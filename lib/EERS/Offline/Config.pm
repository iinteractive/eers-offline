
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

=cut