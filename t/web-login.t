use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File;
use Carp::Always;
use lib '.';
$ENV{COMMON_CONFIG_DIR} ='t/etc';
my $t = Test::Mojo->new(Mojo::File->new('script/web-login.pl'));
#$t->ua->tx->req->headers('X-Original-URI' => 'https://baedi.no');
$t->get_ok('/login')->status_is(200);
...; #TODO test valid login
done_testing();

