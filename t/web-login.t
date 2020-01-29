use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File;
use Carp::Always;
use lib '.';
$ENV{COMMON_CONFIG_DIR} ='t/etc';
$ENV{MOJO_CONFIG} = 't/etc/mojo.conf';
my $t = Test::Mojo->new(Mojo::File->new('script/web-login.pl'));
#$t->ua->tx->req->headers('X-Original-URI' => 'https://baedi.no');
$t->get_ok('/login')->status_is(200);
$t->post_ok('/login'=>form=>{user => 'marcus',pass => 'lulz'})->status_is(302)->content_is('');
my $tx = $t->tx;
$t->get_ok($tx->res->headers->header('Location'));
done_testing();

