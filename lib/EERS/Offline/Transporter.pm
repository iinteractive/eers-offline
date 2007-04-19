
package EERS::Offline::Transporter;
use Moose::Role;
use Moose::Util::TypeConstraints;

our $VERSION = '0.01';

subtype 'EERS::Offline::DirectoryType'
    => as 'Str'
    => where { -d $_ };

has 'error' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_error'
);

has 'source_dir_path' => (
    is       => 'rw',
    isa      => 'EERS::Offline::DirectoryType',
    required => 1,
);

has 'destination_dir_path' => (
    is       => 'rw',
    isa      => 'EERS::Offline::DirectoryType',    
    required => 1,
);

requires 'put';
# NOTE:
# put will return true or false 
# depending on the success of the 
# transfer

1;

__END__