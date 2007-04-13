
package EERS::GenServer::Simple::Client;
use Moose;

our $VERSION = '0.01';

extends 'EERS::GenServer::Simple';

## Methods

sub create_report_request {
    my $self   = shift;
    my %params = @_;
    
    my ($session, 
        $report_format, 
        $report_type, 
        $report_spec, 
        $additional_metadata) = @params{qw[
        session 
        report_format 
        report_type 
        report_spec 
        additional_metadata
    ]};
    
    (defined $session       &&
     defined $report_format &&        
     defined $report_type   &&
     defined $report_spec)
        || confess "You must have a session, report_format, report_type and report spec defined";
    
    my $schema = $self->schema;    
    
    my $r;
    $schema->txn_do(sub {
        $r = $schema->resultset("ReportRequest")->new({
            user_id           => $session->getUserID,
            session_id        => $session->getSessionId,
            report_format     => $report_format,
            report_type       => $report_type,
            report_spec       => $report_spec,    
            (defined $additional_metadata
                ? (additional_metadata => $additional_metadata)
                : ())                    
        });
        $r->set_status_to_submitted;
        $r->insert;
    }); 
    
    return $r;   
}

sub get_all_report_requests_for_user {
    my $self   = shift;
    my %params = @_;
    
    my ($session, $report_format) = @params{qw[
        session report_format
    ]};
    
    (defined $session)
        || confess "You must have a session defined";
    
    return $self->schema->resultset("ReportRequest")->get_undeleted_requests_for(
        user_id => $session->getUserID,
        (defined $report_format 
            ? (report_format => $report_format)
            : ()),
    );    
}

no Moose;

1;

__END__