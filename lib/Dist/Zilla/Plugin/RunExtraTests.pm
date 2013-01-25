use strict;
use warnings;
package Dist::Zilla::Plugin::RunExtraTests;
# ABSTRACT: support running xt tests via dzil test
# VERSION

# Dependencies
use Dist::Zilla 2.100950 (); # XXX really the next release after this date
use Moose 0.99;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

with 'Dist::Zilla::Role::TestRunner';

# methods

sub test {
  my $self = shift;

  my @dirs;
  push @dirs, 'xt/release' if $ENV{RELEASE_TESTING};
  push @dirs, 'xt/author'  if $ENV{AUTHOR_TESTING};
  push @dirs, 'xt/smoke'   if $ENV{AUTOMATED_TESTING};
  @dirs = grep { -d } @dirs;
  return unless @dirs;

  # If the dist hasn't been built yet, then build it:
  unless (-d 'blib') {
    my @builders = @{ $self->zilla->plugins_with(-BuildRunner) };
    die "no BuildRunner plugins specified" unless @builders;
    $builders[0]->build;
  }

  require App::Prove;
  App::Prove->VERSION('3.00');

  my $app = App::Prove->new;
  $app->process_args(qw/-r -b/, @dirs);
  $app->run or $self->log_fatal("Fatal errors in xt tests");
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage::TrustPod
    test

=begin wikidoc

= SYNOPSIS

In your dist.ini:

  [RunExtraTests]

= DESCRIPTION

Runs xt tests when C<dzil test> is run. C<xt/release>, C<xt/author>, and
C<xt/smoke> will be tested based on the values of the appropriate environment
variables (C<RELEASE_TESTING>, C<AUTHOR_TESTING>, and C<AUTOMATED_TESTING>),
which are set by C<dzil test>.

If C<RunExtraTests> is listed after one of the normal test-running
plugins (e.g. C<MakeMaker> or C<ModuleBuild>), then the dist will not
be rebuilt between running the normal tests and the extra tests.

= SEE ALSO

* [Dist::Zilla]

=end wikidoc

=cut

