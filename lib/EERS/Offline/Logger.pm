
package EERS::Offline::Logger;
use Moose;

our $VERSION = '0.01';

has 'log_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_log_fh' => (
    is      => 'ro', 
    isa     => 'IO::File',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $io = IO::File->new($self->log_file, 'a');
        $io->autoflush(1);
        return $io;
    }
);

sub log {
    my ($self, $message) = @_;
    $self->_log_fh->print("[ $$ : " . localtime(time) . " ] - $message\n");    
}

sub DEMOLISH {
    my $self = shift;
    $self->_log_fh->close;
}

1;

__END__