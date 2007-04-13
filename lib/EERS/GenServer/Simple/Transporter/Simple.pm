
package EERS::GenServer::Simple::Transporter::Simple;
use Moose;

use File::Copy 'copy';
use File::Spec::Functions 'catfile';

our $VERSION = '0.01';

with 'EERS::GenServer::Simple::Transporter';

sub put {
    my ($self, %params) = @_;
    my $source_path      = catfile($self->source_dir_path,      $params{source});
    my $destination_path = catfile($self->destination_dir_path, $params{destination});
    unless (copy($source_path, $destination_path)) {
        $self->error('File copy (from => ' 
                    . $source_path 
                    . ', to => ' 
                    . $destination_path
                    . ') failed : ' . $!);
        return;
    }
    # the copy was successful ...
    return 1;
}

1;

__END__