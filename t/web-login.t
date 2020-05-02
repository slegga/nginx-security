use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File 'path';
use Carp::Always;
use Data::Dumper;
use MIME::Base64;
use Model::GetCommonConfig;
$ENV{COMMON_CONFIG_DIR} ='t/etc';
$ENV{TEST_INSECURE_COOKIES}=1;
my $db = Mojo::SQLite->new($ENV{COMMON_CONFIG_DIR}.'/session_store.db')->db;
$db->query($_) for split(/\;/, path('sql/table_defs.sql')->slurp);

my $cfg = Model::GetCommonConfig->new->get_mojoapp_config('Login');
my $spath = $cfg->{hypnotoad}->{service_path};
my $t = Test::Mojo->new('Login',$cfg); #Mojo::File->new('script/web-login.pl'),{config=>$cfg});
$t->get_ok("/$spath")->status_is(200);
my $user ='admin';
$t->post_ok("/$spath"=>form=>{user => $user,pass => 'lulz'})->status_is(200)->content_like(qr'Welcome');
my $tx = $t->tx;
#print STDERR Dumper $tx;
$t->get_ok("/$spath?redirect_uri=/test")->status_is(302);
$t->post_ok("/$spath?redirect_uri=/test"=>form=>{user => $user,pass => 'lulz'})->status_is(302)->content_is('');
$tx = $t->tx;
is($tx->res->headers->header('Location'),'/test');
like($tx->res->cookie('sso-jwt-token'),qr'sso-jwt-token.+path=\/') ;
my $secret = (split(/[\n\s]+/,path($ENV{COMMON_CONFIG_DIR},'secrets.txt')->slurp))[0];

like (decode_base64($tx->res->cookie('sso-jwt-token')->value),qr'sid','Cookie as expected') ;
my $lo = $t->app->build_controller->url_logout;
is($lo, '/xlogin/logout','Correct path for logout');
$t->get_ok("/$spath/logout")->status_is(302)->header_is('Location'=>'/xlogin');

done_testing();

