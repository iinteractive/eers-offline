
package EERS::Offline::WithSchema;
use Moose::Role;

our $VERSION = '0.01';

has 'schema' => (
    is       => 'ro',
    isa      => 'EERS::Offline::DB',
    required => 1,
);

no Moose;

1;

__END__