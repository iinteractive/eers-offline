
package EERS::Offline::Client;
use Moose;
use MooseX::Params::Validate;

our $VERSION = '0.02';

with 'EERS::Offline::WithSchema';

## Methods

sub create_report_request {
    my $self   = shift;
    my %params = validated_hash(\@_,
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
    my ($session, $report_format, $report_type) = validated_list(\@_,
        session       => { isa => 'EERS::Entities::Session' },
        report_format => { isa => 'Str', optional => 1 }, # pdf, excel, etc ...
        report_type   => { isa => 'Str', optional => 1 }, # Scorecard, Comments
    );

    return $self->schema->resultset("ReportRequest")->get_undeleted_requests_for(
        user_id => $session->getUserID,
        (defined $report_format
            ? (report_format => $report_format)
            : ()),
        (defined $report_type
            ? (report_type => $report_type)
            : ()),
    );
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