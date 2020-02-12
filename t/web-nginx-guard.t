use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File;
use Carp::Always;
use Mojo::JWT;
use lib '.';
$ENV{COMMON_CONFIG_DIR} ='t/etc';
my $secret = 'abc';
my $t = Test::Mojo->new(Mojo::File->new('script/web-nginx-guard.pl'));
is($t->app->secrets->[0], $secret);
my $jwt = Mojo::JWT->new(claims=>{user=>'adoer',expires => time + 60},secret=>$secret)->encode;

$t->get_ok('/')->status_is(401);

# Request with custom cookie
my $tx = $t->ua->build_tx(GET => '/');
$tx->req->cookies({name=>'sso-jwt-token', value=> $jwt});
$tx->req->headers->header('X-Original-URI' => '/spennendesaker');
$t->request_ok($tx)->status_is(200)->content_is('Logged in');

#$t->tx->req->cookie('X-Original-URI' => '/spennendesaker');
#$t->tx->req->cookie();
#$t->get_ok('/')->status_is(200);

done_testing();

