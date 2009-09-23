#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
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
        },
    }
);
isa_ok($s, 'EERS::Offline::Server');

## define the report handlers

is($s->get_num_of_waiting_requests, 0, '... no waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

## make a request ...

my $c = EERS::Offline::Client->new(schema => $schema);
isa_ok($c, 'EERS::Offline::Client');

lives_ok {
    $c->create_report_request(
        session       => $session,
        report_format => 'PDF',
        report_type   => 'MissingReportType',
        report_spec   => $MOCK_FILTER,
    );
} '... created the report request successfully';

is($s->get_num_of_waiting_requests, 0, '... 0 waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

## now run the report

ok(!defined($s->run()), '... ran didnt find anything it could run');

## now check the reports

is($s->get_num_of_waiting_requests, 0, '... 0 waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

lives_ok {
    $c->create_report_request(
        session       => $session,
        report_format => 'XLS',
        report_type   => 'TestReport',
        report_spec   => $MOCK_FILTER,
    );
} '... created the report request successfully';

is($s->get_num_of_waiting_requests, 1, '... 1 waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

## now run the report

ok(!$s->run(), '... run errored because it found something it could run, but not the right format');

## now check the reports

is($s->get_num_of_waiting_requests, 0, '... 0 waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

## now check the logs ...

my $log = File::Slurp::slurp($LOG_FILE);
$log =~ s/\[.*] //g;
is($log,
q{- Starting Server Run
- Looking for requests ...
- No requests found
- Starting Server Run
- Looking for requests ...
- Request (id => 2) found
- Request (id => 2) set to pending ...
- No Report Format (type => TestReport, format => XLS) found
- Report Run failed.
}, '... got the right log info');


