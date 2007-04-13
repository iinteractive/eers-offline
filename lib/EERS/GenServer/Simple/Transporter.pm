
package EERS::GenServer::Simple::Transporter;
use Moose::Role;
use Moose::Util::TypeConstraints;

our $VERSION = '0.01';

subtype 'EERS::GenServer::Simple::DirectoryType'
    => as 'Str'
    => where { -d $_ };

has 'error' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_error'
);

has 'source_dir_path' => (
    is       => 'rw',
    isa      => 'EERS::GenServer::Simple::DirectoryType',
    required => 1,
);

has 'destination_dir_path' => (
    is       => 'rw',
    isa      => 'EERS::GenServer::Simple::DirectoryType',    
    required => 1,
);

requires 'put';
# NOTE:
# put will return true or false 
# depending on the success of the 
# transfer

1;

__END__