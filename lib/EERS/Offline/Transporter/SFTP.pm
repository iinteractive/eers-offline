
package EERS::Offline::Transporter::SFTP;
use Moose;

use Net::SFTP;
use File::Spec::Functions;

our $VERSION = '0.01';

with 'EERS::Offline::Transporter';

has 'host'     => (is => 'ro', isa => 'Str');
has 'username' => (is => 'ro', isa => 'Str');
has 'password' => (is => 'ro', isa => 'Str');

has '_sftp_handle' => (
    is      => 'ro',
    isa     => 'Net::SFTP',
    lazy    => 1,
    clearer => '_clear_sftp_handle',
    default => sub {
        my $self = shift;
        Net::SFTP->new($self->host,
            user     => $self->username,
            password => $self->password,
        );
    }
);

sub put {
    my ($self, %params) = @_;

    my $source_path      = catfile($self->source_dir_path,      $params{source});
    my $destination_path = catfile($self->destination_dir_path, $params{destination});

    try {
        my $sftp = $self->_sftp_handle;

        if ($sftp->error) {
            die "Unable to connect to host(" . $self->host . ")";
        }

        unless ($sftp->put($source_path, $destination_path)) {
            die 'Cannot PUT file (from => '
                        . $source_path
                        . ', to => '
                        . $destination_path
                        . ')';
        }
    }
    catch {
        $self->error('SFTP Error: ' . $@);
        $self->_clear_sftp_handle;
        return;
    };

    return 1;
}

1;

__END__
