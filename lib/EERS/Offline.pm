
package EERS::Offline;
use Moose;

use YAML::Syck ();

use EERS::Offline::DB;
use EERS::Offline::Config;
use EERS::Offline::Server;
use EERS::Offline::Client;

our $VERSION = '0.02';

with 'MooseX::Getopt';

has 'config_file' => (
    metaclass   => 'Getopt',
    cmd_aliases => [ 'c' ],
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has '_config' => (
    reader  => 'config',
    isa     => 'EERS::Offline::Config::Simple',
    lazy    => 1,
    builder => '_build_config',
);

sub _build_config {
    my $self = shift;

    # NOTE:
    # the config isa up there is actually
    # just a subtype, which uses heavy
    # validation features. It works for
    # now, we might need to make it an
    # object at some point, in which case
    # this needs to change - SL
    YAML::Syck::LoadFile( $self->config_file );
}


has '_server' => (
    reader  => 'server',
    isa     => 'EERS::Offline::Server',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $conf = $self->config->{server};
        return EERS::Offline::Server->new(
            max_running_reports => $conf->{max_running_reports},
            schema              => $self->_create_schema($conf),
            logger              => $self->_create_logger($conf),
            transporter         => $self->_create_transporter($conf),
            report_builder_map  => $conf->{report_builder_map},
        );
    }
);

has '_client' => (
    reader  => 'client',
    isa     => 'EERS::Offline::Client',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return EERS::Offline::Client->new(
            schema => $self->_create_schema($self->config->{client}),
        );
    }
);

## util methods ...

sub _create_schema {
    my ($self, $conf) = @_;
    return EERS::Offline::DB->connect(
        $conf->{schema}->{dsn},
        $conf->{schema}->{username},
        $conf->{schema}->{password},
        $conf->{schema}->{options},
    );
}

sub _create_logger {
    my ($self, $conf) = @_;
    return undef unless $conf->{logger};

    my $logger_class = 'EERS::Offline::Logger';
    Class::MOP::load_class($logger_class);

    return $logger_class->new(
        log_file => $conf->{logger}->{log_file},
    );
}

sub _create_transporter {
    my ($self, $conf) = @_;
    return undef unless $conf->{transporter};

    my $type = $conf->{transporter}->{type} || 'Simple';
    my $transporter_class = 'EERS::Offline::Transporter::' . $type;
    Class::MOP::load_class($transporter_class);

    return $transporter_class->new(
        %{$conf->{transporter}}
    );
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


