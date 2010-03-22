#!perl

use strict;
use warnings;

use Dist::Zilla     1.093250;
use Capture::Tiny qw/capture/;
use Path::Class;
use Test::More      tests => 1;
use Test::Exception;

# build fake repository
chdir( dir('t', 'check-pass') );
dir('xt')->mkpath;
my $t_fh = file("xt/pass.t")->openw;
print {$t_fh} << 'HERE';
use Test::More tests => 1;
pass("destined to pass");
HERE
close $t_fh;

my $zilla = Dist::Zilla->from_config;

# pass xt test
my ($out, $err) = capture { eval { $zilla->release} };
ok( ! $@, "doesn't die" );

END { unlink 'Foo-1.23.tar.gz'; dir("xt")->rmtree };

