use strict;
use warnings;
package Dist::Zilla::App::Command::xtest;
# ABSTRACT: run xt tests for your dist
# VERSION
use Dist::Zilla::App -command;

use Path::Class::Rule;
use Moose::Autobox;

=head1 SYNOPSIS

Run xt tests for your distribution:

  dzil xtest

This runs with AUTHOR_TESTING and RELEASE_TESTING environment variables turned
on, so it's like doing this:

  export AUTHOR_TESTING=1
  export RELEASE_TESTING=1
  dzil build
  rsync -avp My-Project-Version/ .build/
  cd .build;
  prove -l -r xt

Except for the fact it's built directly in a subdir of .build (like
F<.build/ASDF123>).

A build that fails tests will be left behind for analysis, and F<dzil> will
exit a non-zero value.  If the tests are successful, the build directory will
be removed and F<dzil> will exit with status 0.

You can also use 'xt' as an alias for 'xtest':

  dzil xt

If you provide one or more filenames on the command line, only
those tests will be run (however deeply they are nested).  Glob
patterns may also work, if you protect it from your shell.

  dzil xtest pod-spell.t
  dzil xtest 'dist*'          # don't expand to dist.ini

=cut

sub abstract { 'test your dist' }

sub command_names {
  my ($self) = @_;
  return ( $self->SUPER::command_names, 'xt' );
}

sub execute {
  my ($self, $opt, $arg) = @_;

  require App::Prove;
  require File::pushd;
  require File::Temp;
  require Path::Class;

  my $build_root = Path::Class::dir('.build');
  $build_root->mkpath unless -d $build_root;

  my $target = Path::Class::dir( File::Temp::tempdir(DIR => $build_root) );
  $self->log("building test distribution under $target");

  local $ENV{AUTHOR_TESTING} = 1;
  local $ENV{RELEASE_TESTING} = 1;

  $self->zilla->ensure_built_in($target);

  my $wd = File::pushd::pushd( $target );

  my $error;

  my $app = App::Prove->new;
  if ( ref $arg eq 'ARRAY' && @$arg ) {
    my $pcr = Path::Class::Rule->new->file->name(@$arg);
    my @t = map { "$_" } $pcr->all( 'xt' );
    if ( @t ) {
      $app->process_args(qw/-r -l/, @t) if @t;
      $error = "Failed xt tests" unless  $app->run;
    }
    else {
      $self->log("no xt files found matching: @$arg");
    }
  }
  else {
    $app->process_args(qw/-r -l xt/);
    $error = "Failed xt tests" unless  $app->run;
  }

  if ($error) {
    $self->log($error);
    $self->log("left failed dist in place at $target");
    exit 1;
  } else {
    $self->log("all's well; removing $target");
    $target->rmtree;
  }

}

1;
