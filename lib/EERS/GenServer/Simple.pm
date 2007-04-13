
package EERS::GenServer::Simple;
use Moose;

our $VERSION = '0.01';

has 'schema' => (
    is       => 'ro',
    isa      => 'EERS::GenServer::Simple::DB',
    required => 1,
);

no Moose;

1;

__END__