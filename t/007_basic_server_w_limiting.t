#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::MockObject;

use File::Slurp ();
use Data::Dumper;

BEGIN {
    use_ok('EERS::Offline::DB');
    use_ok('EERS::Offline::Client');
    use_ok('EERS::Offline::Server');
    use_ok('EERS::Offline::Logger');
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

my $schema = EERS::Offline::DB->connect(
    "dbi:SQLite:dbname=gen_server_test.db",
    undef,
    undef,
    { PrintError => 0, RaiseError => 1 }
);

my $logger = EERS::Offline::Logger->new(
    log_file => $LOG_FILE,
);

my $s = EERS::Offline::Server->new(
    schema             => $schema,
    logger             => $logger,
    report_builder_map => {
        'TestReport' => {
            PDF => 'My::Test::Report::PDF',
        }
    }
);
isa_ok($s, 'EERS::Offline::Server');

my $c = EERS::Offline::Client->new(schema => $schema);
isa_ok($c, 'EERS::Offline::Client');

is($s->get_num_of_waiting_requests, 0, '... no waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

ok(!defined($s->get_next_pending_request), '... no pending requests');

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

## create some requests ...

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

is($s->get_num_of_waiting_requests, 6, '... 6 waiting request(s)');
is($s->get_num_of_pending_requests, 0, '... no pending request(s)');

$s->get_next_pending_request for (1 .. 5);

is($s->get_num_of_waiting_requests, 1, '... 1 waiting request(s)');
is($s->get_num_of_pending_requests, 5, '... 5 pending request(s)');

ok(!defined($s->run()), '... nothing to run, so returned undef');

## now check the logs ...

my $log = File::Slurp::slurp($LOG_FILE);
$log =~ s/\[.*] //g;
is($log,
q{- Looking for requests ...
- No requests found
- Looking for requests ...
- Request (id => 1) found
- Request (id => 1) set to pending ...
- Looking for requests ...
- Request (id => 2) found
- Request (id => 2) set to pending ...
- Looking for requests ...
- Request (id => 3) found
- Request (id => 3) set to pending ...
- Looking for requests ...
- Request (id => 4) found
- Request (id => 4) set to pending ...
- Looking for requests ...
- Request (id => 5) found
- Request (id => 5) set to pending ...
- Starting Server Run
- Max number of reports already running (5)
}, '... got the right log info');

