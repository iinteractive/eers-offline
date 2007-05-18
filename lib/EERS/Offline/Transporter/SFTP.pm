
package EERS::Offline::Transporter::SFTP;
use Moose;

use Net::SFTP;
use File::Spec::Functions;

our $VERSION = '0.01';

with 'EERS::Offline::Transporter';

has 'host'     => (is => 'ro', isa => 'Str');
has 'username' => (is => 'ro', isa => 'Str');
has 'password' => (is => 'ro', isa => 'Str');

sub put {
    my ($self, %params) = @_;
    
    my $source_path      = catfile($self->source_dir_path,      $params{source});
    my $destination_path = catfile($self->destination_dir_path, $params{destination});
        
    eval {
        my $sftp = Net::SFTP->new($self->host,
            user     => $self->username,
            password => $self->password,
        );

        unless ($sftp) {
            $self->error("Unable to connect via SFTP to host(" . $self->host . ")");
            return;
        }
        
        unless ($sftp->put($source_path, $destination_path)) {
            $self->error('Cannot SFTP file (from => ' 
                        . $source_path 
                        . ', to => ' 
                        . $destination_path
                        . ')');
            return;
        } 
    };
    if ($@) {
        $self->error('SFTP Error: ' . $@);
        return;
    }
    return 1;
}

1;

__END__