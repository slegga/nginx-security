use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File 'path';
use Carp::Always;
use lib '.';
use Data::Dumper;
use Model::GetCommonConfig;
$ENV{COMMON_CONFIG_DIR} ='t/etc';
$ENV{TEST_INSECURE_COOKIES}=1;

my $cfg = Model::GetCommonConfig->new->get_mojoapp_config($0);
my $spath = $cfg->{hypnotoad}->{service_path};
my $t = Test::Mojo->new(Mojo::File->new('script/web-login.pl'));
$t->get_ok("/$spath/")->status_is(200);
my $user ='marcus';
$t->post_ok("/$spath/"=>form=>{user => $user,pass => 'lulz'})->status_is(200)->content_like(qr'Welcome');
my $tx = $t->tx;
#print STDERR Dumper $tx;
$t->get_ok("/$spath/?redirect_uri=/test")->status_is(200);
$t->post_ok("/$spath/?redirect_uri=/test"=>form=>{user => 'marcus',pass => 'lulz'})->status_is(302)->content_is('');
$tx = $t->tx;
is($tx->res->headers->header('Location'),'/test');
like($tx->res->cookie('sso-jwt-token'),qr'sso-jwt-token.+path=\/') ;
my $secret = (split(/[\n\s]+/,path($ENV{COMMON_CONFIG_DIR},'secrets.txt')->slurp))[0];
my $jwt = Mojo::JWT->new(claims=>{user=>$user,expires => time + 60},secret=>$secret)->encode;
is($tx->res->cookie('sso-jwt-token')->value,$jwt,'Cookie as expected') ;

done_testing();

