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

## set up some mocks ...

my $MOCK_SESSION_ID = 'deadbeef';
my $MOCK_USER_ID    = 10;
my $MOCK_FILTER     = '2006@c@org:1|2|3';

my $session = Test::MockObject->new;
$session->set_isa('EERS::Entities::Session');
$session->mock('getSessionId' => sub { $MOCK_SESSION_ID });
$session->mock('getUserID'    => sub { $MOCK_USER_ID    });

## configure object ...

local @ARGV = ('-c', 't/conf/basic_conf.yaml');
my $offline = EERS::Offline->new_with_options;

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

lives_ok {
    $c->create_report_request(
        session       => $session,
        report_format => 'PDF', 
        report_type   => 'TestReport',
        report_spec   => $MOCK_FILTER,
    );
} '... created the report request successfully';

## now run the report 

$s->run();

## now check the reports

my ($request) = $c->get_all_report_requests_for_user(session => $session)->all;

ok($request->is_submitted, '... checking the status');
ok(!$request->is_pending, '... checking the status');
ok($request->is_completed, '... checking the status');
ok(!$request->has_error, '... checking the status');

my $report = File::Slurp::slurp($request->attachment_body);
is($report, 
q{Got a report request for deadbeef
of report type TestReport
and report format is PDF
and report spec is 2006@c@org:1|2|3
}, '... got the right report info (from attachment)');

unlink($request->attachment_body);

my $orig_report = File::Slurp::slurp($TEST_REPORT_FILE_NAME);
is($orig_report, 
q{Got a report request for deadbeef
of report type TestReport
and report format is PDF
and report spec is 2006@c@org:1|2|3
}, '... got the right report info');

## now check the logs ...

my $log = File::Slurp::slurp($offline->config->{server}->{logger}->{log_file});
$log =~ s/\[.*] //g;
is($log, 
q{- Starting Server Run
- Looking for requests ...
- Request (id => 1) found
}, '... got the right log info');


