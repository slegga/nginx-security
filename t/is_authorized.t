use Test::More;
use Test::Mojo;
use Carp::Always;
use Data::Dumper;

$ENV{COMMON_CONFIG_DIR} = 't/etc';
{
    use Mojolicious::Lite;

    app->config(hypnotoad=>{});
    plugin 'Security'=>{authorized_groups => [qw/all area1/]};
    my $home = Mojo::Home->new->detect;
    get '/ssl' => sub {
        my $c = shift;
        return $c->render(text => $c->req->headers->to_string) if $c->is_authorized;
        return $c->render(status => 403, text => 'SSL cert NOK'.Dumper $c->security_info);
    };
}
my $t       = Test::Mojo->new;
my $headers = {};

diag 'ssl';
$t->get_ok('/ssl')->status_is(403)->content_like(qr'SSL cert NOK');
my $headers={};
#$headers->{'X-SSL-Client-Verified'} = 'FAILED';
$t->get_ok('/ssl', $headers)->status_is(403)->content_like(qr'SSL cert NOK');
$t->get_ok('/ssl', $headers)->status_is(403)->content_like(qr'authorized_groups');

$headers->{'X-Common-Name'} = 'admin';
$t->get_ok('/ssl', $headers)->status_is(200)->content_like(qr'admin');

done_testing();
