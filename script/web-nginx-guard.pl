#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::File 'path';
use File::Basename;
my $name = fileparse($0,'.pl');
plugin Config => {default => {hypnotoad => { listen => ['http://127.0.0.1:8101'], proxy => 1, workers => 4, pid_file => path('/var/run')->child($name.'.pid')->to_string}}};

app->sessions->cookie_name('nginx-guard');
app->sessions->default_expiration( 3600 * 1 );
app->sessions->secure( $ENV{TEST_INSECURE_COOKIES} ? 0 : 1 );
hook before_dispatch => sub { shift->res->headers->server('Some server'); };

get '/' => sub {
	my $c = shift;
	$c->render(status=>200, text => 'Allowed');
	my $uri      = Mojo::URL->new( $c->req->headers->header('X-Original-URI') || '' );
	my $username = $c->session('username');
    $username ||= 'anonymous';

    if ( !$uri or !defined $uri->scheme or $uri->scheme ne 'https' ) {

        # X-Original-URI is set by nginx
        # The guard require https to prevent man-in-the-middle cookie stealing
        $c->app->log->error("[$username] nginx is not configured correctly: X-Original-URI is invalid. ($uri)");
        $c->render( text => 'nginx is not configured.', status => 500 );
    }
	elsif ( $c->session('username') ) {
        $c->req->env->{identity} = $c->session('username');
        if ( $uri =~ m!/logout\b! ) {
            $c->session( expires => 1, nms_expires => 1 );
        }
        $c->res->headers->header( 'X-User', $c->session('username') );
        $c->render( text => 'Logged in', status => 200 );
	}
	else {
        $c->session( expires => ( $c->session('nms_expires') || time + 3600 ) );
        $c->app->log->debug("[$username] No username in session.");
        $c->render( text => 'Use 401 instead of 302 for redirect in nginx', status => 401 );
    }
};

app->start;

__END__

=encoding utf8
