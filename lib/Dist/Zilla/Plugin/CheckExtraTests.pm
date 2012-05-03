use strict;
use warnings;
package Dist::Zilla::Plugin::CheckExtraTests;
# ABSTRACT: check xt tests before release
# VERSION

# Dependencies
use Dist::Zilla 2.100950 (); # XXX really the next release after this date
use App::Prove 3.00 ();
use File::pushd 0 ();
use Moose 0.99;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

with 'Dist::Zilla::Role::BeforeRelease';

# methods

sub before_release {
  my $self = shift;

  $self->zilla->ensure_built_in;

  # chdir in
  my $wd = File::pushd::pushd($self->zilla->built_in);

  # prove xt
  local $ENV{RELEASE_TESTING} = 1;
  my $app = App::Prove->new;
  $app->process_args(qw/-r -l xt/);
  $app->run or $self->log_fatal("Fatal errors in xt tests");
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage::TrustPod
    before_release

=begin wikidoc

= SYNOPSIS

In your dist.ini:

  [CheckExtraTests]

= DESCRIPTION

Runs all xt tests before release.  Dies if any fail.  Sets RELEASE_TESTING,
but not AUTHOR_TESTING.

= SEE ALSO

* [Dist::Zilla]

=end wikidoc

=cut

