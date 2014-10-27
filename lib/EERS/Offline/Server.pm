
package EERS::Offline::Server;
use Moose;

use Data::UUID;
use Class::Load;

our $VERSION = '0.03';

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

has 'supported_report_types' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        [ keys %{ (shift)->report_builder_map } ]
    },
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
    my $r = $schema->resultset("ReportRequest")->get_first_submitted_request( $self );
    unless (defined $r) {
        $self->log("No requests found");
        return;
    }
    $self->log("Request (id => " . $r->id . ") found");
    $schema->txn_do(sub {
        $r->set_status_to_pending;
        $r->update;
    });
    $self->log("Request (id => " . $r->id . ") set to pending ...");
    return $r;
}

sub get_num_of_waiting_requests {
    my $self = shift;
    $self->schema->resultset("ReportRequest")->get_num_of_waiting_requests( $self )
}

sub get_num_of_pending_requests {
    my $self = shift;
    $self->schema->resultset("ReportRequest")->get_num_of_pending_requests( $self )
}

# run reports in batches ...
sub run_up_to {
    my ($self, $num_reports) = @_;
    $self->log("Running up to ($num_reports) reports");
    my $num_reports_run = 0;
    for (1 .. $num_reports) {
        my $result = $self->run;
        last unless defined $result;
        $num_reports_run++ if $result;
    }
    $self->log("Ran ($num_reports_run) reports");
    return $num_reports_run;
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
            $self->log("Report Run failed.");
            if ($@) {
                $self->log("Exception = $@");
            }
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

    eval { Class::Load::load_class($builder_class) };
    if ($@) {
        $self->log("Could not load builder class ($builder_class) because : $@");
        return;
    }
    else {
        $self->log("Loaded builder class ($builder_class) successfully");
    }

    unless ($builder_class->can('does') && $builder_class->does('EERS::Offline::Report')) {
        $self->log("The builder class ($builder_class) does not implement EERS::Offline::Report");
        return;
    }
    else {
        $self->log("The builder class ($builder_class) implements EERS::Offline::Report");
    }

    my $builder;
    eval {
        $builder = $builder_class->new;
        $builder->create($request, $self->logger);
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
        else {
            $self->log("The transporter succecceded.");
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

=pod

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
