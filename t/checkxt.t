#!perl

use strict;
use warnings;
use lib 't/lib';

use Capture::Tiny qw/capture/;
use Dist::Zilla::App::Tester;
use Test::DZil;
use Test::More 0.88;
use Try::Tiny;

## XT FILE GUTS 
my $xt_fail = << 'HERE';
use Test::More tests => 1;
fail("doomed to fail");
HERE

my $xt_pass = << 'HERE';
use Test::More tests => 1;
pass("destined to succeed");
HERE

## XXX copy paste junk below


{
  my $tzil;
  try {
    $tzil = Dist::Zilla::Tester->from_config(
      { dist_root => 'corpus/DZ' },
      {
        add_files => {
          'source/xt/checkme.t' => $xt_fail,
        },
      },
    );
    ok( $tzil, "created test dist that will fail xt tests");

    capture { $tzil->release };
  } catch {
    my $err = $_;
    like(
      $err,
      qr/Fatal errors in xt/i,
      "CheckExtraTests caught xt test failure",
    );
    ok(
      ! grep({ /fake release happen/i } @{ $tzil->log_messages }),
      "FakeRelease did not happen",
    );

  }

}

{
  my $tzil;
  try {
    $tzil = Dist::Zilla::Tester->from_config(
      { dist_root => 'corpus/DZ' },
      {
        add_files => {
          'source/xt/checkme.t' => $xt_pass,
        },
      },
    );
    ok( $tzil, "created test dist that will pass xt tests");

    capture { $tzil->release };
  }
  catch {
    diag "ERROR: $_";
  };

  ok(
    ! grep({ /Fatal errors in xt/i } @{ $tzil->log_messages }),
    "No xt errors logged",
  );
  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease executed",
  );

}

done_testing;

