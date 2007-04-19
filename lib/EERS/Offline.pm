
package EERS::Offline;
use Moose;

use YAML::Syck ();

use EERS::Offline::DB;
use EERS::Offline::Config;
use EERS::Offline::Server;
use EERS::Offline::Client;

our $VERSION = '0.01';

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
    default => sub {
        # NOTE:
        # the config isa up there is actually 
        # just a subtype, which uses heavy 
        # validation features. It works for 
        # now, we might need to make it an 
        # object at some point, in which case
        # this needs to change - SL
        YAML::Syck::LoadFile((shift)->config_file)
    }
);

has '_server' => (
    reader  => 'server',
    isa     => 'EERS::Offline::Server',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $conf = $self->config->{server};
        return EERS::Offline::Server->new(
            schema             => $self->_create_schema($conf),
            logger             => $self->_create_logger($conf),
            transporter        => $self->_create_transporter($conf),
            report_builder_map => $conf->{report_builder_map},
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
        source_dir_path      => $conf->{transporter}->{source_dir_path},
        destination_dir_path => $conf->{transporter}->{destination_dir_path},    
    );
}

1;

__END__