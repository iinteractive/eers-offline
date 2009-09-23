
package EERS::Offline::DB::ReportRequest;

use strict;
use warnings;

use DateTime;
use DateTime::Format::MySQL;
use Perl6::Junction 'any';

our $VERSION = '0.02';

use base 'DBIx::Class';

# status types
use constant SUBMITTED => 'submitted';
use constant PENDING   => 'pending';
use constant COMPLETED => 'completed';
use constant ERROR     => 'error';
use constant DELETED   => 'deleted';

__PACKAGE__->load_components(qw/PK::Auto InflateColumn::DateTime InflateColumn Core/);
__PACKAGE__->table('tbl_report_requests');
__PACKAGE__->add_columns(
    id => { data_type => 'INTEGER', is_auto_increment => 1, is_nullable => 0  },

    ## User information
    # user who owns the report
    user_id    => { data_type => 'INTEGER' },
    # session where the request was initiated
    session_id => { data_type => 'CHAR(32)' },

    ## Report information
    # the output format (PDF, Excel, etc)
    report_format => { data_type => 'VARCHAR(20)', is_nullable => 0 },
    # the "type" of report (could be anything, future-proofin++)
    report_type   => { data_type => 'VARCHAR(20)', is_nullable => 0 },
    # JSON structure of the demographics, etc
    report_spec   => { data_type => 'TEXT', is_nullable => 0 },

    ## Date/Timestamp
    # timestamp of when the report was initially requested
    request_submitted => { data_type => 'DATETIME', is_nullable => 0 },
    # timestamp of when the request was picked up by the gen servers
    job_submitted     => { data_type => 'DATETIME', is_nullable => 1 },
    # timestamp of when the request has been fufilled
    job_completed     => { data_type => 'DATETIME', is_nullable => 1 },

    ## Status info
    # {submitted, pending, completed, error, n/a}
    status => { data_type => 'VARCHAR(20)' },

    ## Misc.
    # misc crap which might be applicable
    additional_metadata => { data_type => 'TEXT', is_nullable => 1, },

    ## Results
    ## NOTE: results are returned as "attachments"

    # type of attachment sent back (uri, gif, pdf,
    # command-to-fetch-it, error message, etc.)
    attachment_type => { data_type => 'VARCHAR(255)', is_nullable => 1, },
    # the attachment payload
    attachment_body => { data_type => 'TEXT', is_nullable => 1, },

);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->resultset_class('EERS::Offline::DB::ReportRequest::ResultSet');

## Status related methods

sub set_status_to_submitted {
    my $self = shift;
    $self->status(SUBMITTED);
    $self->request_submitted(DateTime->now);
}

sub set_status_to_pending {
    my $self = shift;
    $self->status(PENDING);
    $self->job_submitted(DateTime->now);
}

sub set_status_to_completed {
    my $self = shift;
    $self->status(COMPLETED);
    $self->job_completed(DateTime->now);
}

sub set_status_to_error {
    my $self = shift;
    $self->status(ERROR);
    $self->job_completed(DateTime->now);
}

sub set_status_to_deleted {
    my $self = shift;
    $self->status(DELETED);
    $self->job_completed(DateTime->now);
}

sub is_submitted { (shift)->status eq any(SUBMITTED, COMPLETED, PENDING, ERROR) }
sub is_pending   { (shift)->status eq PENDING }
sub is_completed { (shift)->status eq any(COMPLETED, ERROR) }
sub has_error    { (shift)->status eq ERROR }
sub is_deleted   { (shift)->status eq DELETED }

sub has_attachement {
    my $self = shift;
    ($self->attachment_type && $self->attachment_body)
}

package EERS::Offline::DB::ReportRequest::ResultSet;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'DBIx::Class::ResultSet';

## get the first one out of the queue

sub get_first_submitted_request {
    my $self     = shift;
    my $server   = shift;
    my $requests = $self->search(
        {
            status      => EERS::Offline::DB::ReportRequest->SUBMITTED,
            report_type => { in => $server->supported_report_types },
        },
        { order_by    => 'id asc' },
    );
    # NOTE:
    # just grab the first one, there is
    # almost certainly a better way to
    # do this, but this should work for
    # now. - SL
    my ($r) = $requests->all;
    return $r;
}

sub get_undeleted_requests_for {
    my ($self, %params) = @_;
    my $requests = $self->search({
        status => { '!=' => EERS::Offline::DB::ReportRequest->DELETED },
        %params,
    });
}

sub get_num_of_waiting_requests {
    my $self     = shift;
    my $server   = shift;
    my $requests = $self->count({
        status      => EERS::Offline::DB::ReportRequest->SUBMITTED,
        report_type => { in => $server->supported_report_types },
    });
}

sub get_num_of_pending_requests {
    my $self     = shift;
    my $server   = shift;
    my $requests = $self->count({
        status      => EERS::Offline::DB::ReportRequest->PENDING,
        report_type => { in => $server->supported_report_types },
    });
}

1;

__END__

=pod


=cut
