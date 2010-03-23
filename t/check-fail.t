#!perl

use strict;
use warnings;

use Dist::Zilla     1.093250;
use Capture::Tiny qw/capture/;
use Path::Class;
use Test::More      tests => 1;
use Test::Exception;

# build fake repository
chdir( dir('t', 'check-fail') );
dir('xt')->mkpath;
my $t_fh = file("xt/fail.t")->openw;
print {$t_fh} << 'HERE';
use Test::More tests => 1;
fail("doomed to fail");
HERE
close $t_fh;

my $zilla = Dist::Zilla->from_config;

# fail xt test
my ($out, $err) = capture { eval { $zilla->release} };
like( $out, qr/Fatal errors in xt/, 'failed xt test msg on STDOUT')
  or diag "OUT:\n$out\nERR:\n$err\n";

END { unlink 'Foo-1.23.tar.gz'; dir('Foo-1.23')->rmtree; dir("xt")->rmtree };

