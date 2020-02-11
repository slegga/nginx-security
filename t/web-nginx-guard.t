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
#$t->ua->tx->req->headers('X-Original-URI' => 'https://baedi.no');
my $tx = $t->ua->build_tx(GET => 'https://example.com/account');
$t->get_ok('/')->status_is(401);
my $jwt = Mojo::JWT->new(claims=>{user=>'adoer',expires => time + 60},secret=>$secret)->encode;
$t->ua->on(start => sub {
  my ($ua, $tx) = @_;
  $tx->req->cookie('sso-jwt-token' => $jwt);
});
$t->get_ok('/')->status_is(200);

done_testing();

