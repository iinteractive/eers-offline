
package EERS::Offline::Server;
use Moose;

use Data::UUID;

our $VERSION = '0.02';

with 'EERS::Offline::WithSchema';

has 'transporter' => (
    is        => 'rw',
    does      => 'EERS::Offline::Transporter',
    predicate => 'has_transporter',
);

has 'logger' => (
    is  => 'ro',
    isa => 'EERS::Offline::Logger',
);

has 'max_running_reports' => (
    is      => 'ro',
    isa     => 'Int',
    default => 5,
);

# NOTE:
# the map will map the report_type first
# and then the report_format under it
# this is because report_format is a more
# "fixed" list (for some def of fixed)
# - SL 
has 'report_builder_map' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}}
);

## Methods

# logging is optional ...
sub log { ((shift)->logger || return)->log(@_) }

sub generate_destination_file_name {
    my ($self, $source_file_name) = @_;
    my $uuid_gen = Data::UUID->new;
    my $uuid = $uuid_gen->to_string($uuid_gen->create); 
    my ($source_file_type) = ($source_file_name =~ /\.(.*)$/);   
    return $uuid . '.' . $source_file_type;
}

sub get_next_pending_request {
    my $self = shift;    
    my $schema = $self->schema;
    $self->log("Looking for requests ...");
    my $r = $schema->resultset("ReportRequest")->get_first_submitted_request;
    unless (defined $r) {
        $self->log("No requests found");
        return;
    }
    $schema->txn_do(sub {
        $r->set_status_to_pending;
        $r->update;
    });
    $self->log("Request (id => " . $r->id . ") found");
    return $r;
}

sub get_num_of_waiting_requests { 
    (shift)->schema->resultset("ReportRequest")->get_num_of_waiting_requests 
}

sub get_num_of_pending_requests { 
    (shift)->schema->resultset("ReportRequest")->get_num_of_pending_requests 
}

sub run {
    my $self = shift;
    
    $self->log("Starting Server Run");
    
    if ($self->get_num_of_pending_requests >= $self->max_running_reports) {
        $self->log("Max number of reports already running (" . $self->max_running_reports . ")");  
        return;      
    }
    
    my $request = $self->get_next_pending_request;
    
    return unless defined $request;
    
    $self->schema->txn_do(sub {
        # NOTE:
        # perhaps I dont want to do this 
        # within the transaction. I think it
        # it would leave it in a bad state
        # if the transaction failed 
        # (pending but not run),.. need to 
        # test it - SL
        if (eval { $self->_run($request) }) {
            $request->set_status_to_completed;
        }
        else {
            $request->set_status_to_error;
        }        
        $request->update;
    }); 
    
    # return false if we have an error ...
    $request->has_error ? 0 : 1;
}

sub _run {
    my ($self, $request) = @_;

    my $map = $self->report_builder_map;
    
    unless (exists $map->{$request->report_type}) {
        $self->log("No Report Type (" 
                  . $request->report_type 
                  . ") found");
        return;
    }

    unless (exists $map->{$request->report_type}->{$request->report_format}) {
        $self->log("No Report Format (type => " 
                  . $request->report_type 
                  . ", format => " 
                  . $request->report_format 
                  . ") found");
        return;        
    }        
                             
    my $builder_class = $map->{$request->report_type}->{$request->report_format};
    
    eval { Class::MOP::load_class($builder_class) };
    if ($@) {
        $self->log("Could not load builder class ($builder_class) because : $@");     
        return;        
    }
    
    unless ($builder_class->can('does') && $builder_class->does('EERS::Offline::Report')) {
        $self->log("The builder class ($builder_class) does not implement EERS::Offline::Report");     
        return;        
    }
    
    my $builder;
    eval { 
        $builder = $builder_class->new;
        $builder->create($request) 
    };
    if ($@) {
        $self->log("Report builder class ($builder_class) threw an exception : $@");
        return;        
    }    
    
    if ($self->has_transporter) {
        
        ($builder->attachment_type eq 'file')
            || confess "Currently only file attachments are supported";
        
        my $source_file_name      = $builder->attachment_body;
        my $destination_file_name = $self->generate_destination_file_name($source_file_name);
        
        unless ($self->transporter->put(
                    source      => $source_file_name,
                    destination => $destination_file_name,
                )) {
            $self->log("The transporter failed: " . $self->transporter->error); 
            return;            
        }
        
        $request->attachment_type($builder->attachment_type);
        $request->attachment_body($destination_file_name);
        
    }
    else {
        $request->attachment_type($builder->attachment_type);
        $request->attachment_body($builder->attachment_body);        
    }
    
    return 1;
}

no Moose;

1;

__END__