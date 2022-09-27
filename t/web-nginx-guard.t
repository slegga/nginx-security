use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File 'path';
use Carp::Always;
use Mojo::JWT;
use Mojo::Util 'secure_compare';
use lib '.';
use Data::Dumper;
$ENV{TEST_INSECURE_COOKIES} = 1;
$ENV{COMMON_CONFIG_DIR} ='t/etc';
my $secret = (split(/[\n\s]+/,path($ENV{COMMON_CONFIG_DIR},'secrets.txt')->slurp))[0];
diag '$secret = '.$secret;
my $t = Test::Mojo->new(Mojo::File->new('script/web-nginx-guard.pl'));
is($t->app->secrets->[0], $secret);

my $db = Mojo::SQLite->new($ENV{COMMON_CONFIG_DIR}.'/session_store.db')->db;
$db->query($_) for split(/\;/, path('sql/table_defs.sql')->slurp);
$db->insert('sessions',{sid=>'123', username=>'admin',status=>'active'});

my $jwt = Mojo::JWT->new(claims=>{sid=>'123',expires => time + 60},secret=>$secret)->encode;

# request with out cookie
my $tx = $t->ua->build_tx(GET => '/');
$tx->req->headers->add('X-Original-URI' => '/spennendesaker');
$t->request_ok($tx)->status_is(401);

# Request with custom cookie
my $tx2 = $t->ua->build_tx(GET => '/');
$tx2->req->cookies({name=>'sso-jwt-token', value=> $jwt});
$tx2->req->headers->add('X-Original-URI' => '/spennendesaker');
$t->request_ok($tx2)->status_is(200)->content_is('Logged in');

#$t->tx->req->cookie('X-Original-URI' => '/spennendesaker');
#$t->tx->req->cookie();
#$t->get_ok('/')->status_is(200);

done_testing();

