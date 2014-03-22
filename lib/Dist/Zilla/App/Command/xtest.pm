use strict;
use warnings;

package Dist::Zilla::App::Command::xtest;
# ABSTRACT: run xt tests for your dist
# VERSION
use Dist::Zilla::App -command;

use Moose::Autobox;

=head1 SYNOPSIS

Run xt tests for your distribution:

  dzil xtest [ --no-author] [ --no-release ] [ --no-automated ] [ --all ]

This runs with AUTHOR_TESTING and RELEASE_TESTING environment variables turned
on, so it's like doing this:

  export AUTHOR_TESTING=1
  export RELEASE_TESTING=1
  dzil build
  rsync -avp My-Project-Version/ .build/
  cd .build;
  perl Makefile.PL
  make
  prove -l -r xt

Except for the fact it's built directly in a subdir of .build (like
F<.build/ASDF123>).

A build that fails tests will be left behind for analysis, and F<dzil> will
exit a non-zero value.  If the tests are successful, the build directory will
be removed and F<dzil> will exit with status 0.

You can also use 'xt' as an alias for 'xtest':

  dzil xt

If you provide one or more filenames on the command line, only
those tests will be run (however deeply they are nested).

  dzil xtest pod-spell.t

Arguments are turned into regexp patterns, so you can
do any sort of partial match you want:

  dzil xtest author/    # just the author tests
  dzil xtest spell      # a test with 'spell' in the path

There is no need to add anything to F<dist.ini> -- installation of this module
is sufficient to make the command available.

=cut

sub opt_spec {
  [ 'author!' => 'enables the AUTHOR_TESTING env variable (default behavior)', { default => 1 } ],
  [ 'release!'   => 'enables the RELEASE_TESTING env variable (default behavior)', { default => 1 } ],
  [ 'automated' => 'enables the AUTOMATED_TESTING env variable', { default => 0 } ],
  [ 'jobs|j=i' => 'number of parallel test jobs to run', { default => 1 } ],
  [ 'all' => 'enables the RELEASE_TESTING, AUTOMATED_TESTING and AUTHOR_TESTING env variables', { default => 0 } ]
}

=head1 OPTIONS

=head2 --no-author

This will run the test suite without setting AUTHOR_TESTING

=head2 --no-release

This will run the test suite without setting RELEASE_TESTING

=head2 --automated

This will run the test suite with AUTOMATED_TESTING=1

=head2 --all

Equivalent to --release --automated --author

=cut

sub abstract { 'run xt tests for your dist' }

sub command_names {
    my ($self) = @_;
    return ( $self->SUPER::command_names, 'xt' );
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    require App::Prove;
    require File::pushd;

    local $ENV{AUTHOR_TESTING} = 1 if $opt->author or $opt->all;
    local $ENV{RELEASE_TESTING} = 1 if $opt->release or $opt->all;
    local $ENV{AUTOMATED_TESTING} = 1 if $opt->automated or $opt->all;

    my ( $target, $latest ) = $self->zilla->ensure_built_in_tmpdir;

    my $error;
    {
        my $wd = File::pushd::pushd($target);

        my @builders = @{ $self->zilla->plugins_with( -BuildRunner ) };
        die "no BuildRunner plugins specified" unless @builders;
        $_->build for @builders;

        my $app = App::Prove->new;
        if ( ref $arg eq 'ARRAY' && @$arg ) {
            require Path::Iterator::Rule;
            my $pcr = Path::Iterator::Rule->new->file->and(
                sub {
                    my $path = $_;
                    return grep { $path =~ /$_/ } @$arg;
                }
            );
            my @t = map { "$_" } $pcr->all('xt');
            if (@t) {
                $app->process_args( '-j', $self->jobs, qw/-r -b/, @t ) if @t;
                $error = "Failed xt tests" unless $app->run;
            }
            else {
                $self->log("no xt files found matching: @$arg");
            }
        }
        else {
            $app->process_args( '-j', $self->jobs, qw/-r -b xt/);
            $error = "Failed xt tests" unless $app->run;
        }
    }

    if ($error) {
        $self->log($error);
        $self->log("left failed dist in place at $target");
        exit 1;
    }
    else {
        $self->log("all's well; removing $target");
        $target->rmtree;
        $latest->remove if $latest;
    }

}

1;
