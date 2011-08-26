
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