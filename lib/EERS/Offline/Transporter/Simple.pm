
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

=pod

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut