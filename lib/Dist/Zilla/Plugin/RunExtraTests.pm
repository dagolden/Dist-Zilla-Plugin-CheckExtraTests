use strict;
use warnings;

package Dist::Zilla::Plugin::RunExtraTests;
# ABSTRACT: support running xt tests via dzil test

our $VERSION = '0.025';

# Dependencies
use Dist::Zilla 4.3 ();
use Moose 2;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

with 'Dist::Zilla::Role::TestRunner';

# methods

sub test {
    my ($self, $target, $arg) = @_;

    my %dirs; @dirs{ glob('xt/*') } = ();
    delete $dirs{'xt/author'}  unless $ENV{AUTHOR_TESTING};
    delete $dirs{'xt/smoke'}   unless $ENV{AUTOMATED_TESTING};
    delete $dirs{'xt/release'} unless $ENV{RELEASE_TESTING};

    my @dirs = sort keys %dirs;
    return unless @dirs;

    # If the dist hasn't been built yet, then build it:
    unless ( -d 'blib' ) {
        my @builders = @{ $self->zilla->plugins_with( -BuildRunner ) };
        die "no BuildRunner plugins specified" unless @builders;
        $_->build for @builders;
        die "no blib; failed to build properly?" unless -d 'blib';
    }

    my $jobs = $arg && exists $arg->{jobs}
             ? $arg->{jobs}
             : $self->can('default_jobs')
             ? $self->default_jobs
             : 1;

    require App::Prove;
    App::Prove->VERSION('3.00');

    my $app = App::Prove->new;
    $app->process_args( '-j', $jobs, qw/-r -b/, @dirs );
    $app->run or $self->log_fatal("Fatal errors in xt tests");
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage::TrustPod
test

=head1 SYNOPSIS

In your dist.ini:

  [RunExtraTests]

=head1 DESCRIPTION

Runs F<xt> tests when the test phase is run (e.g. C<dzil test>, C<dzil release>
etc).  F<xt/release>, F<xt/author>, and F<xt/smoke> will be tested based on the
values of the appropriate environment variables (C<RELEASE_TESTING>,
C<AUTHOR_TESTING>, and C<AUTOMATED_TESTING>), which are set by C<dzil test>.
Additionally, all other F<xt> files and directories will always be run.

If C<RunExtraTests> is listed after one of the normal test-running
plugins (e.g. C<MakeMaker> or C<ModuleBuild>), then the dist will not
be rebuilt between running the normal tests and the extra tests.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla>

=cut

