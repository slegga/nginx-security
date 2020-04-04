use Test::More;
use Test::Mojo;
use Carp::Always;

{
    use Mojolicious::Lite;

#    plugin 'RequestBase';
    plugin 'Security';
    my $home = Mojo::Home->new->detect;
    get '/ssl' => sub {
        my $c = shift;
        return $c->render(text => $c->req->headers->to_string) if $c->user;
        return $c->render(status => 401, text => 'SSL cert NOK');
    };
}
my $t       = Test::Mojo->new;
my $headers = {};

diag 'ssl';
$t->get_ok('/ssl')->status_is(401)->content_is('SSL cert NOK');
my $headers={};
#$headers->{'X-SSL-Client-Verified'} = 'FAILED';
$t->get_ok('/ssl', $headers)->status_is(401)->content_is('SSL cert NOK');

#$headers->{'X-SSL-Client-Verified'} = 'SUCCESS';
$t->get_ok('/ssl', $headers)->status_is(401)->content_is('SSL cert NOK');

done_testing();