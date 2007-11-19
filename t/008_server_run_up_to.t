#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Exception;
use Test::MockObject;

use File::Slurp ();
use File::Spec::Functions;
use Data::Dumper;

BEGIN {
    use_ok('EERS::Offline');  
}

## clean out the crap

unlink('gen_server_test.db');
system('sqlite3 gen_server_test.db < db/create_table.sql');

our $TEST_REPORT_FILE_NAME = 'my_test_report_pdf.txt';
unlink($TEST_REPORT_FILE_NAME);

my $LOG_FILE = 'gen_server_log.txt';
unlink($LOG_FILE);

## set up some mocks ...

my $MOCK_SESSION_ID = 'deadbeef';
my $MOCK_USER_ID    = 10;
my $MOCK_FILTER     = '2006@c@org:1|2|3';

my $session = Test::MockObject->new;
$session->set_isa('EERS::Entities::Session');
$session->mock('getSessionId' => sub { $MOCK_SESSION_ID });
$session->mock('getUserID'    => sub { $MOCK_USER_ID    });

## configure object ...

my $offline = EERS::Offline->new(config_file => 't/conf/basic_conf.yaml');

my $s = $offline->server;
isa_ok($s, 'EERS::Offline::Server');

## define the report handlers 

{
    package My::Test::Report::PDF;
    use Moose;
    
    with 'EERS::Offline::Report';

    sub create {
        my ($self, $request) = @_;
        
        my $file = IO::File->new($main::TEST_REPORT_FILE_NAME, 'w') 
            || confess "Could not create report file because : $!";
        $file->print("Got a report request for " . $request->session_id . "\n");
        $file->print("of report type " . $request->report_type . "\n");        
        $file->print("and report format is " . $request->report_format . "\n");    
        $file->print("and report spec is " . $request->report_spec . "\n");                        
        $file->close;
        
        $self->attachment_type('file');
        $self->attachment_body($main::TEST_REPORT_FILE_NAME);        
    }
}

## make a request ...

my $c = $offline->client;
isa_ok($c, 'EERS::Offline::Client');

for (1 .. 6) {
    my $req;
    lives_ok {
        $req = $c->create_report_request(
            session       => $session,
            report_format => 'PDF', 
            report_type   => 'TestReport',
            report_spec   => $MOCK_FILTER,
        );
    } '... created the report request (' . $_ . ') successfully';   
}

## now run the report 

is($s->get_num_of_waiting_requests, 6, '... 6 waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

is($s->run_up_to(5), 5, '... 5 reports were run');
is($s->run_up_to(5), 1, '... 1 report was run');

my $log = File::Slurp::slurp($LOG_FILE);
$log =~ s/\[.*] //g;
is($log, 
q{- Running up to (5) reports
- Starting Server Run
- Looking for requests ...
- Request (id => 1) found
- Loaded builder class (My::Test::Report::PDF) successfully
- The builder class (My::Test::Report::PDF) implements EERS::Offline::Report
- The transporter succecceded.
- Starting Server Run
- Looking for requests ...
- Request (id => 2) found
- Loaded builder class (My::Test::Report::PDF) successfully
- The builder class (My::Test::Report::PDF) implements EERS::Offline::Report
- The transporter succecceded.
- Starting Server Run
- Looking for requests ...
- Request (id => 3) found
- Loaded builder class (My::Test::Report::PDF) successfully
- The builder class (My::Test::Report::PDF) implements EERS::Offline::Report
- The transporter succecceded.
- Starting Server Run
- Looking for requests ...
- Request (id => 4) found
- Loaded builder class (My::Test::Report::PDF) successfully
- The builder class (My::Test::Report::PDF) implements EERS::Offline::Report
- The transporter succecceded.
- Starting Server Run
- Looking for requests ...
- Request (id => 5) found
- Loaded builder class (My::Test::Report::PDF) successfully
- The builder class (My::Test::Report::PDF) implements EERS::Offline::Report
- The transporter succecceded.
- Ran (5) reports
- Running up to (5) reports
- Starting Server Run
- Looking for requests ...
- Request (id => 6) found
- Loaded builder class (My::Test::Report::PDF) successfully
- The builder class (My::Test::Report::PDF) implements EERS::Offline::Report
- The transporter succecceded.
- Starting Server Run
- Looking for requests ...
- No requests found
- Ran (1) reports
}, '... got the right log info');

my @requests = $c->get_all_report_requests_for_user(session => $session)->all;

foreach my $request (@requests) {
    ok($request->is_submitted, '... checking the status');
    ok(!$request->is_pending, '... checking the status');
    ok($request->is_completed, '... checking the status');
    ok(!$request->has_error, '... checking the status');

    ok($request->has_attachement, '... we do have an attachement');

    my $report = File::Slurp::slurp($request->attachment_body);
    is($report, 
    q{Got a report request for deadbeef
of report type TestReport
and report format is PDF
and report spec is 2006@c@org:1|2|3
}, '... got the right report info (from attachment)');

    unlink($request->attachment_body);
}