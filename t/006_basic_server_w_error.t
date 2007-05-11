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
    use_ok('EERS::Offline::DB');
    use_ok('EERS::Offline::Client');
    use_ok('EERS::Offline::Server');    
    use_ok('EERS::Offline::Logger');
    use_ok('EERS::Offline::Transporter::Simple');    
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
$session->set_isa('EERS::Entities::Session');
$session->mock('getSessionId' => sub { $MOCK_SESSION_ID });
$session->mock('getUserID'    => sub { $MOCK_USER_ID    });

## configure object ...

my $schema = EERS::Offline::DB->connect(
    "dbi:SQLite:dbname=gen_server_test.db", 
    undef, 
    undef, 
    { PrintError => 0, RaiseError => 1 } 
);

my $logger = EERS::Offline::Logger->new(
    log_file => $LOG_FILE,
);

my $transporter = EERS::Offline::Transporter::Simple->new(
    source_dir_path      => curdir(),
    destination_dir_path => curdir(),    
);

my $s = EERS::Offline::Server->new(
    schema             => $schema,
    logger             => $logger,
    transporter        => $transporter,
    report_builder_map => {
        'TestReport' => {
            PDF => 'My::Test::Report::PDF',
        }
    }
);
isa_ok($s, 'EERS::Offline::Server');

ok(!defined($s->run()), '... nothing to run, so returned undef');

## define the report handlers 

{
    package My::Test::Report::PDF;
    use Moose;
    
    with 'EERS::Offline::Report';

    sub create {
        my ($self, $request) = @_;
        die "Whoops\n";
    }
}

## make a request ...

my $c = EERS::Offline::Client->new(schema => $schema);
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

ok(!$s->run(), '... ran successfully, but found an error');

## now check the reports

my ($request) = $c->get_all_report_requests_for_user(session => $session)->all;

ok($request->is_submitted, '... checking the status (is submitted)');
ok(!$request->is_pending, '... checking the status (is not pending)');
ok($request->is_completed, '... checking the status (is completed)');
ok($request->has_error, '... checking the status (does have an error)');

ok(!$request->has_attachement, '... we do not have an attachement');

## now check the logs ...

my $log = File::Slurp::slurp($LOG_FILE);
$log =~ s/\[.*] //g;
is($log, 
q{- Starting Server Run
- Looking for requests ...
- No requests found
- Starting Server Run
- Looking for requests ...
- Request (id => 1) found
- Report builder class (My::Test::Report::PDF) threw an exception : Whoops

}, '... got the right log info');


