
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