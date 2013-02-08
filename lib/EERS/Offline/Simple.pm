package EERS::Offline::Simple;
use Moose;
use namespace::autoclean;

extends 'EERS::Offline';

has 'report_builder_map' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'ii_config' => (
    is       => 'ro',
    isa      => 'II::Config',
    required => 1,
);

has '+config_file' => ( required => 0, default => "unused" );

override '_build_config' => sub {
    my $self = shift;

    my $conf = $self->ii_config->get_vars->{app}{cron};
    $conf->{server}{report_builder_map} = $self->report_builder_map;

    return $conf;
};

__PACKAGE__->meta->make_immutable;

1;
