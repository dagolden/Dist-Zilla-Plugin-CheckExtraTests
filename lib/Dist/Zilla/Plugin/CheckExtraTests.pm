use strict;
use warnings;

package Dist::Zilla::Plugin::CheckExtraTests;
# ABSTRACT: check xt tests before release
# VERSION

# Dependencies
use Dist::Zilla 2.3 ();
use Moose 2;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

with 'Dist::Zilla::Role::BeforeRelease';

# methods

sub before_release {
    my $self = shift;

    $self->zilla->ensure_built_in;

    # chdir in
    require File::pushd;
    my $wd = File::pushd::pushd( $self->zilla->built_in );

    # make
    my @builders = @{ $self->zilla->plugins_with( -BuildRunner ) };
    die "no BuildRunner plugins specified" unless @builders;
    $_->build for @builders;

    require App::Prove;
    App::Prove->VERSION('3.00');

    # prove xt
    local $ENV{RELEASE_TESTING} = 1;
    my $app = App::Prove->new;
    $app->process_args(qw/-r -b xt/);
    $app->run or $self->log_fatal("Fatal errors in xt tests");
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage::TrustPod
before_release

=head1 SYNOPSIS

In your dist.ini:

  [CheckExtraTests]

=head1 DESCRIPTION

Runs all xt tests before release.  Dies if any fail.  Sets RELEASE_TESTING,
but not AUTHOR_TESTING.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla>

=cut

