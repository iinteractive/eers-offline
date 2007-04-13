
package EERS::GenServer::Simple::DB;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/
    ReportRequest
/);

1;

__END__
