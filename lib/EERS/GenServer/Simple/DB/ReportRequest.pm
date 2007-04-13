
package EERS::GenServer::Simple::DB::ReportRequest;

use strict;
use warnings;

use DateTime;
use DateTime::Format::MySQL;
use Perl6::Junction 'any';

our $VERSION = '0.01';

use base 'DBIx::Class';

# status types 
use constant SUBMITTED => 'submitted';
use constant PENDING   => 'pending';
use constant COMPLETED => 'completed';
use constant ERROR     => 'error';

__PACKAGE__->load_components(qw/PK::Auto InflateColumn::DateTime InflateColumn Core/);
__PACKAGE__->table('tbl_report_requests');
__PACKAGE__->add_columns(
    id => { data_type => 'INTEGER' },

    ## User information
    # user who owns the report
    user_id    => { data_type => 'INTEGER' },
    # session where the request was initiated    
    session_id => { data_type => 'CHAR(32)' },

    ## Report information
    # the output format (PDF, Excel, etc)
    report_format => { data_type => 'VARCHAR(20)' },        
    # the "type" of report (could be anything, future-proofin++)
    report_type   => { data_type => 'VARCHAR(20)' },        
    # JSON structure of the demographics, etc    
    report_spec   => { data_type => 'TEXT' },         

    ## Date/Timestamp
    # timestamp of when the report was initially requested
    request_submitted => { data_type => 'DATETIME' },    
    # timestamp of when the request was picked up by the gen servers
    job_submitted     => { data_type => 'DATETIME', is_nullable => 0, },        
    # timestamp of when the request has been fufilled
    job_completed     => { data_type => 'DATETIME', is_nullable => 0, },         

    ## Status info
    # {submitted, pending, completed, error, n/a}
    status => { data_type => 'VARCHAR(20)' },                   

    ## Misc.
    # misc crap which might be applicable
    additional_metadata => { data_type => 'TEXT', is_nullable => 0, },     

    ## Results
    ## NOTE: results are returned as "attachments"
    
    # type of attachment sent back (uri, gif, pdf, 
    # command-to-fetch-it, error message, etc.)
    attachment_type => { data_type => 'VARCHAR(255)', is_nullable => 0, },         
    # the attachment payload
    attachment_body => { data_type => 'TEXT', is_nullable => 0, },          

);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->resultset_class('EERS::GenServer::Simple::DB::ReportRequest::ResultSet');

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

sub is_submitted { (shift)->status eq any(SUBMITTED, COMPLETED, PENDING, ERROR) }
sub is_pending   { (shift)->status eq PENDING }
sub is_completed { (shift)->status eq any(COMPLETED, ERROR) }
sub has_error    { (shift)->status eq ERROR }

package EERS::GenServer::Simple::DB::ReportRequest::ResultSet;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'DBIx::Class::ResultSet';

## get the first one out of the queue

sub get_first_submitted_request {
    my $self = shift;    
    my $requests = $self->search(
        { status   => EERS::GenServer::Simple::DB::ReportRequest->SUBMITTED },
        { order_by => 'status asc' },
    );    
    # NOTE:
    # just grab the first one, there is 
    # almost certainly a better way to 
    # do this, but this should work for 
    # now. - SL
    $requests->next;
}

1;

__END__

=pod


=cut
