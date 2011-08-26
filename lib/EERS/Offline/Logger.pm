
package EERS::Offline::Logger;
use Moose;

use IO::File;

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
        my $io = IO::File->new($self->log_file, 'a')
            || confess "Could not open log file (" . $self->log_file . ") because : $!";
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