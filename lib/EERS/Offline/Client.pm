
package EERS::Offline::Client;
use Moose;
use MooseX::Params::Validate;

our $VERSION = '0.01';

with 'EERS::Offline::WithSchema';

## Methods

sub create_report_request {
    my $self   = shift;
    my %params = validate(\@_,
        session             => { isa => 'EERS::Entities::Session' },
        report_format       => { isa => 'Str' }, # pdf, excel, etc ...
        report_type         => { isa => 'Str' }, # usually a class name of some kind ...
        report_spec         => { isa => 'Str' }, # the serialized filter ...
        additional_metadata => { isa => 'Str', optional => 1 },
    );
    
    my $schema = $self->schema;    
    
    my $r;
    $schema->txn_do(sub {
        $r = $schema->resultset("ReportRequest")->new({
            user_id           => $params{session}->getUserID,
            session_id        => $params{session}->getSessionId,
            report_format     => $params{report_format},
            report_type       => $params{report_type},
            report_spec       => $params{report_spec},    
            (exists $params{additional_metadata}
                ? (additional_metadata => $params{additional_metadata})
                : ())                    
        });
        $r->set_status_to_submitted;
        $r->insert;
    }); 
    
    return $r;   
}

sub get_all_report_requests_for_user {
    my $self   = shift;
    my %params = validate(\@_,
        session       => { isa => 'EERS::Entities::Session' },
        report_format => { isa => 'Str', optional => 1 }, # pdf, excel, etc ...
    );
    
    return $self->schema->resultset("ReportRequest")->get_undeleted_requests_for(
        user_id => $params{session}->getUserID,
        (exists $params{report_format} 
            ? (report_format => $params{report_format})
            : ()),
    );    
}

no Moose;

1;

__END__