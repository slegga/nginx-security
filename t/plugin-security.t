use Test::More;
use Test::Mojo;
use Carp::Always;

$ENV{COMMON_CONFIG_DIR} ='t/etc';

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
    get '/url_abspath' => sub {
        my $c  = shift;
        return $c->render(text => $c->url_abspath('info'));
    };
}
my $t       = Test::Mojo->new;
my $headers = {};

diag 'ssl';
$t->get_ok('/ssl')->status_is(401)->content_is('SSL cert NOK');
my $headers={};
$t->get_ok('/ssl', $headers)->status_is(401)->content_is('SSL cert NOK');

$headers->{'X-Common-Name'} = 'deadly';
$t->get_ok('/ssl', $headers)->status_is(200)->content_like(qr'deadly');


# utility functions;
is ($t->app->config->{hypnotoad}->{service_path},undef,'Check path');
$t->app->config->{hypnotoad}->{service_path} = 'base';
$t->get_ok('/url_abspath')->status_is(200)->content_is('/base/info');
done_testing();
