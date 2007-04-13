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
    use_ok('EERS::GenServer::Simple::DB');
    use_ok('EERS::GenServer::Simple::Client');
    use_ok('EERS::GenServer::Simple::Server');    
    use_ok('EERS::GenServer::Simple::Logger');
    use_ok('EERS::GenServer::Simple::Transporter::Simple');    
}

## clean out the crap

unlink('gen_server_test.db');
system('sqlite3 gen_server_test.db < db/create_table.sql');

my $LOG_FILE = 'gen_server_log.txt';
unlink($LOG_FILE);

our $TEST_REPORT_FILE_NAME = 'my_test_report_pdf.txt';
unlink($TEST_REPORT_FILE_NAME);

## set up some mocks ...

my $MOCK_SESSION_ID = 'deadbeef';
my $MOCK_USER_ID    = 10;
my $MOCK_FILTER     = '2006@c@org:1|2|3';

my $session = Test::MockObject->new;
$session->mock('getSessionId' => sub { $MOCK_SESSION_ID });
$session->mock('getUserID'    => sub { $MOCK_USER_ID    });

## configure object ...

my $schema = EERS::GenServer::Simple::DB->connect(
    "dbi:SQLite:dbname=gen_server_test.db", 
    undef, 
    undef, 
    { PrintError => 0, RaiseError => 1 } 
);

my $logger = EERS::GenServer::Simple::Logger->new(
    log_file => $LOG_FILE,
);

my $transporter = EERS::GenServer::Simple::Transporter::Simple->new(
    source_dir_path      => curdir(),
    destination_dir_path => curdir(),    
);

my $s = EERS::GenServer::Simple::Server->new(
    schema             => $schema,
    logger             => $logger,
    transporter        => $transporter,
    report_builder_map => {
        'TestReport' => {
            PDF => 'My::Test::Report::PDF',
        }
    }
);
isa_ok($s, 'EERS::GenServer::Simple::Server');

## define the report handlers 

{
    package My::Test::Report::PDF;
    use Moose;
    
    with 'EERS::GenServer::Simple::Report';

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
        $self->attachment_body('my_test_report_pdf.txt');        
    }
}

## make a request ...

my $c = EERS::GenServer::Simple::Client->new(schema => $schema);
isa_ok($c, 'EERS::GenServer::Simple::Client');

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
}, '... got the right report info');

unlink($request->attachment_body);

my $orig_report = File::Slurp::slurp($TEST_REPORT_FILE_NAME);
is($orig_report, 
q{Got a report request for deadbeef
of report type TestReport
and report format is PDF
and report spec is 2006@c@org:1|2|3
}, '... got the right report info');

## now check the logs ...

my $log = File::Slurp::slurp($LOG_FILE);
$log =~ s/\[.*] //g;
is($log, 
q{- Starting Server Run
- Looking for requests ...
- Request (id => 1) found
}, '... got the right log info');


