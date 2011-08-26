
package EERS::Offline::Config;
use Moose::Util::TypeConstraints;
use Declare::Constraints::Simple '-All';

our $VERSION = '0.01';

my $schema_constraint = And(
    IsHashRef,
    # these are required ...
    HasAllKeys('dsn', 'username', 'password'),
    # options is an optional item ...
    OnHashKeys('options' => IsHashRef)
);

subtype('EERS::Offline::Config::Simple' => {
    as    => 'HashRef',
    where => And(
        IsHashRef,
        HasAllKeys('client', 'server'),
        OnHashKeys(
            client => And(
                IsHashRef,
                HasAllKeys('schema'),
                OnHashKeys(schema => $schema_constraint),
            ),
            server => And(
                IsHashRef,
                HasAllKeys('schema', 'report_builder_map'),
                OnHashKeys(
                    schema             => $schema_constraint,
                    report_builder_map => IsHashRef,
                    # optional items ...
                    logger => And(
                        IsHashRef,
                        HasAllKeys('log_file'),
                    ),
                    transporter => And(
                        IsHashRef,
                        HasAllKeys('source_dir_path', 'destination_dir_path'),
                    ),
                )
            )
        )
    )
});

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