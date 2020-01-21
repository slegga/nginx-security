use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Mojo::File;
use lib '.';
my $t = Test::Mojo->new(Mojo::File->new('script/web-nginx-guard.pl'));
$t->get_ok('/')->status_is(401);
done_testing();

