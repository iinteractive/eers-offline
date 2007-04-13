
package EERS::GenServer::Simple::Report;
use Moose::Role;

our $VERSION = '0.01';

has 'attachment_type' => (
    is  => 'rw',
    isa => 'Str',
);

has 'attachment_body' => (
    is  => 'rw',
    isa => 'Str',
);

requires 'create';
# NOTE:
# create will accept a ReportRequest
# and return void, it should treat the
# ReportRequest as a read-only item

1;

__END__