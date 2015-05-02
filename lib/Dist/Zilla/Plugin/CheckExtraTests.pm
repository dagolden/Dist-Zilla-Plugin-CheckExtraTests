use strict;
use warnings;

package Dist::Zilla::Plugin::CheckExtraTests;
# ABSTRACT: check xt tests before release

our $VERSION = '0.028';

# Dependencies
use Dist::Zilla 4.3 ();
use Moose 2;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

with 'Dist::Zilla::Role::BeforeRelease';

=attr default_jobs

This attribute is the default value that should be used as the C<jobs> argument
for prerelease tests.

=cut

has default_jobs => (
    is      => 'ro',
    isa     => 'Int', # non-negative
    default => 1,
);

# methods

sub before_release {
    my ( $self, $tgz ) = @_;
    $tgz = $tgz->absolute;

    { require Path::Tiny; Path::Tiny->VERSION(0.013) }

    my $build_root = Path::Tiny::path( $self->zilla->root )->child('.build');
    $build_root->mkpath unless -d $build_root;

    my $tmpdir = Path::Tiny->tempdir( DIR => $build_root );

    $self->log("Extracting $tgz to $tmpdir");

    require Archive::Tar;

    my @files = do {
        my $wd = File::pushd::pushd($tmpdir);
        Archive::Tar->extract_archive("$tgz");
    };

    $self->log_fatal( [ "Failed to extract archive: %s", Archive::Tar->error ] )
      unless @files;

    # Run tests on the extracted tarball:
    my $target = $tmpdir->child( $self->zilla->dist_basename );

    local $ENV{RELEASE_TESTING} = 1;
    local $ENV{AUTHOR_TESTING}  = 1;

    {
        # chdir in
        require File::pushd;
        my $wd = File::pushd::pushd($target);

        # make
        my @builders = @{ $self->zilla->plugins_with( -BuildRunner ) };
        die "no BuildRunner plugins specified" unless @builders;
        $_->build for @builders;

        my $jobs = $self->default_jobs;
        my @v = $self->zilla->logger->get_debug ? ('-v') : ();

        require App::Prove;
        App::Prove->VERSION('3.00');

        my $app = App::Prove->new;
        $app->process_args( '-j', $jobs, @v, qw/-r -b xt/ );
        $app->run or $self->log_fatal("Fatal errors in xt tests");
    }

    $self->log("all's well; removing $tmpdir");
    $tmpdir->remove_tree( { safe => 0 } );

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

Runs all xt tests before release.  Dies if any fail.  Sets RELEASE_TESTING
and AUTHOR_TESTING.

If you use L<Dist::Zilla::Plugin::TestRelease>, you should consider using
L<Dist::Zilla::Plugin::RunExtraTests> instead, which enables xt tests to
run as part of C<[TestRelease]> and is thus a bit more efficient as the
distribution is only built once for testing.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla>

=cut

