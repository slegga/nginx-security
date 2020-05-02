use Test::More;
use Test::Mojo;
use Mojo::Base -strict;
use Carp::Always;
use Mojo::File 'path';
use Mojo::SQLite;
use Mojo::JWT;
use lib;

$ENV{COMMON_CONFIG_DIR} ='t/etc';
my $tmp = path($ENV{COMMON_CONFIG_DIR})->child('secrets.txt')->slurp;
my $SECRET = (split(/[\s\n]/, $tmp))[0];
say STDERR $SECRET;
my $db = Mojo::SQLite->new($ENV{COMMON_CONFIG_DIR}.'/session_store.db')->db;
$db->query($_) for split(/\;/, path('sql/table_defs.sql')->slurp);
$db->insert('sessions',{sid=>123,username=>'bodil'});

sub generate_jwt {
    my $claims = shift;

    #my $jwt =
    return Mojo::JWT->new(claims => $claims, secret => $SECRET)->encode;
#    return Mojo::Cookie::Request->new({name=>'sso-jwt-token', value =>$jwt});
};

{
    use Mojolicious::Lite;

#    plugin 'RequestBase';
    plugin 'Mojolicious::Plugin::Security';
    app->secrets([$SECRET]);
    my $home = Mojo::Home->new->detect;
    get '/request' => sub {
        my $c = shift;
        $DB::single=2;
        return $c->render(text => $c->req->headers->to_string) if $c->user;
        return $c->render(status => 401, text => 'Request NOT OK');
    };
    get '/url_abspath' => sub {
        my $c  = shift;
        return $c->render(text => $c->url_abspath('info'));
    };
}
my $t       = Test::Mojo->new;
my $headers = {};

diag 'ssl';
$t->get_ok('/request')->status_is(401)->content_is('Request NOT OK');
$t->get_ok('/request', $headers)->status_is(401)->content_is('Request NOT OK');

$headers->{'X-Common-Name'} = 'deadly';
$t->get_ok('/request', $headers)->status_is(200)->content_like(qr'deadly');

diag 'jwt';
$headers={};
#my $tx = $t->tx;
my $tx = $t->ua->build_tx(GET => '/request');
my $jwt = generate_jwt({sid=>'123'});

$tx->req->cookies({name => 'sso-jwt-token', value => $jwt});
#say $cookie;
#push @{$tx->req->cookies}, $cookie;
#$headers={'Set-Cookie' => "$cookie"};
#$t->tx($tx);
$t->request_ok($tx)->status_is(200);#->content_like(qr'deadly');#->content_is('');


# utility functions;
is ($t->app->config->{hypnotoad}->{service_path},undef,'Check path');
$t->app->config->{hypnotoad}->{service_path} = 'base';
$t->get_ok('/url_abspath')->status_is(200)->content_is('/base/info');
done_testing();
