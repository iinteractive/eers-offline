#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Exception;
use Test::MockObject;

use File::Slurp ();
use Data::Dumper;

BEGIN {
    use_ok('EERS::GenServer::Simple::DB');
    use_ok('EERS::GenServer::Simple::Client');
    use_ok('EERS::GenServer::Simple::Server');    
    use_ok('EERS::GenServer::Simple::Logger');
}

unlink('gen_server_test.db');
system('sqlite3 gen_server_test.db < db/create_table.sql');

my $LOG_FILE = 'gen_server_log.txt';
unlink($LOG_FILE);

my $MOCK_SESSION_ID = 'deadbeef';
my $MOCK_USER_ID    = 10;
my $MOCK_FILTER     = '2006@c@org:1|2|3';

my $session = Test::MockObject->new;
$session->set_isa('EERS::Entities::Session');
$session->mock('getSessionId' => sub { $MOCK_SESSION_ID });
$session->mock('getUserID'    => sub { $MOCK_USER_ID    });

my $schema = EERS::GenServer::Simple::DB->connect(
    "dbi:SQLite:dbname=gen_server_test.db", 
    undef, 
    undef, 
    { PrintError => 0, RaiseError => 1 } 
);

my $logger = EERS::GenServer::Simple::Logger->new(
    log_file => $LOG_FILE,
);

my $s = EERS::GenServer::Simple::Server->new(
    schema => $schema,
    logger => $logger,
);
isa_ok($s, 'EERS::GenServer::Simple::Server');

my $c = EERS::GenServer::Simple::Client->new(schema => $schema);
isa_ok($c, 'EERS::GenServer::Simple::Client');

ok(!defined($s->get_next_pending_request), '... no pending requests');

my $new_request_id;

{
    my $req;
    lives_ok {
        $req = $c->create_report_request(
            session       => $session,
            report_format => 'PDF', 
            report_type   => 'Employee',
            report_spec   => $MOCK_FILTER,
        );
    } '... created the report request successfully';

    $new_request_id = $req->id;

    ok($req->is_submitted, '... checking the status');
    ok(!$req->is_pending, '... checking the status');
    ok(!$req->is_completed, '... checking the status');
    ok(!$req->has_error, '... checking the status');

    is($req->user_id, $MOCK_USER_ID, '... got the right user_id');
    is($req->session_id, $MOCK_SESSION_ID, '... got the right session_id');

    is($req->report_format, 'PDF', '... got the right report_format');
    is($req->report_type, 'Employee', '... got the right report_type');
    is($req->report_spec, $MOCK_FILTER, '... got the right report_spec');

    ok(defined($req->request_submitted), '... request has been submitted');    
    isa_ok($req->request_submitted, 'DateTime');
    
    ok(!defined($req->job_submitted), '... job not submitted yet');
    ok(!defined($req->job_completed), '... job not completed yet'); 
    
    ok(!defined($req->additional_metadata), '... no additional metadata yet');        
    ok(!defined($req->attachment_type), '... no attachement type yet');     
    ok(!defined($req->attachment_body), '... no attachement body yet');         
}

my $next = $s->get_next_pending_request;
is($next->id, $new_request_id, '... got the latest request (which I had just created)');

ok($next->is_submitted, '... checking the status');
ok($next->is_pending, '... checking the status');
ok(!$next->is_completed, '... checking the status');
ok(!$next->has_error, '... checking the status');

# the request is now PENDING, so no more SUBMITTED in the db
ok(!defined($s->get_next_pending_request), '... no pending requests');

my ($my_request) = $c->get_all_report_requests_for_user(
    session => $session
)->all;
is($next->id, $my_request->id, '... got the right list of requests for my session');

my $log = File::Slurp::slurp($LOG_FILE);
$log =~ s/\[.*] //g;
is($log, 
q{- Looking for requests ...
- No requests found
- Looking for requests ...
- Request (id => 1) found
- Looking for requests ...
- No requests found
}, '... got the right log info');




