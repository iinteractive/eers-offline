requires "DBIx::Class" => "0";
requires "DBIx::Class::ResultSet" => "0";
requires "DBIx::Class::Schema" => "0";
requires "Data::UUID" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::MySQL" => "0";
requires "DateTime::Format::SQLite" => "0";
requires "Declare::Constraints::Simple" => "0";
requires "File::Copy::Reliable" => "0";
requires "File::Spec::Functions" => "0";
requires "IO::File" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "MooseX::Getopt" => "0";
requires "MooseX::Params::Validate" => "0";
requires "Net::SFTP" => "0";
requires "Perl6::Junction" => "0";
requires "Try::Tiny" => "0";
requires "YAML::Syck" => "0";
requires "base" => "0";
requires "constant" => "0";
requires "namespace::autoclean" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Data::Dumper" => "0";
  requires "File::Slurp" => "0";
  requires "Test::Exception" => "0";
  requires "Test::MockObject" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Test::Pod" => "1.41";
};
