requires "App::Prove" => "3.00";
requires "Dist::Zilla" => "4.3";
requires "Dist::Zilla::App" => "0";
requires "Dist::Zilla::Role::BeforeRelease" => "0";
requires "Dist::Zilla::Role::TestRunner" => "0";
requires "File::Temp" => "0";
requires "File::pushd" => "0";
requires "Moose" => "2";
requires "Moose::Autobox" => "0";
requires "Path::Iterator::Rule" => "0";
requires "Path::Tiny" => "0";
requires "namespace::autoclean" => "0.09";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "Dist::Zilla::App::Tester" => "0";
  requires "Dist::Zilla::Tester" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "List::Util" => "0";
  requires "Params::Util" => "0";
  requires "Sub::Exporter" => "0";
  requires "Test::More" => "0.88";
  requires "Test::Requires" => "0";
  requires "Try::Tiny" => "0";
  requires "lib" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
