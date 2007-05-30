
package EERS::Offline::Transporter::Simple;
use Moose;

use File::Copy::Reliable 'copy_reliable';
use File::Spec::Functions 'catfile';

our $VERSION = '0.03';

with 'EERS::Offline::Transporter';

sub put {
    my ($self, %params) = @_;
    my $source_path      = catfile($self->source_dir_path,      $params{source});
    my $destination_path = catfile($self->destination_dir_path, $params{destination});    
    unless (eval { copy_reliable($source_path, $destination_path) }) {
        $self->error('File copy (from => ' 
                    . $source_path 
                    . ', to => ' 
                    . $destination_path
                    . ') failed : ' . $@);
        return;
    }
    # the copy was successful ...
    return 1;
}

1;

__END__