use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File;
use lib '.';
my $t = Test::Mojo->new(Mojo::File->new('script/web-nginx-guard.pl'));
#$t->ua->tx->req->headers('X-Original-URI' => 'https://baedi.no');
my $tx = $t->ua->build_tx(GET => 'https://example.com/account');
$tx->req->cookies({'X-Original-URI' => 'https://baedi.no'});
#$tx = $ua->start($tx);
$t->get_ok('/')->status_is(500);
$t->ua->on(start => sub {
  my ($ua, $tx) = @_;
  $tx->req->headers->header('X-Original-URI' => 'https://baedi.no/');
});
$t->get_ok('/')->status_is(401);
done_testing();

