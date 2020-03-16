use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File 'path';
use Carp::Always;
use lib '.';
use Data::Dumper;
$ENV{COMMON_CONFIG_DIR} ='t/etc';
#$ENV{MOJO_CONFIG} = 't/etc/mojo.conf';
$ENV{TEST_INSECURE_COOKIES}=1;
my $t = Test::Mojo->new(Mojo::File->new('script/web-login.pl'));
$t->get_ok('/')->status_is(200);
#$t->ua->tx->req->headers('X-Original-URI' => 'https://baedi.no');
my $user ='marcus';
$t->post_ok('/'=>form=>{user => $user,pass => 'lulz'})->status_is(200)->content_like(qr'Welcome');
my $tx = $t->tx;
#print STDERR Dumper $tx;
$t->get_ok('/?redirect_uri=/test')->status_is(200);
$t->post_ok('/?redirect_uri=/test'=>form=>{user => 'marcus',pass => 'lulz'})->status_is(302)->content_is('');
$tx = $t->tx;
is($tx->res->headers->header('Location'),'/test');
like($tx->res->cookie('sso-jwt-token'),qr'sso-jwt-token.+path=\/') ;
my $secret = (split(/[\n\s]+/,path($ENV{COMMON_CONFIG_DIR},'secrets.txt')->slurp))[0];
my $jwt = Mojo::JWT->new(claims=>{user=>$user,expires => time + 60},secret=>$secret)->encode;
is($tx->res->cookie('sso-jwt-token')->value,$jwt,'Cookie as expected') ;

done_testing();

