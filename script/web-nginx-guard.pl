#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::File 'path';
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Model::GetCommonConfig;
use Data::Dumper;
my $gcc = Model::GetCommonConfig->new;
#my $name = fileparse($0,'.pl');
#plugin Config => {toadfarm => $gcc->get_hypnotoad_config($0) };
app->config($gcc->get_mojoapp_config($0));
app->config(hypnotoad => $gcc->get_hypnotoad_config($0));

app->sessions->default_expiration( 3600 * 1 );
#app->sessions->secure( $ENV{TEST_INSECURE_COOKIES} ? 0 : 1 );
app->sessions->secure( 0 );
app->log->path(app->config('mojo_log_path'));

hook before_dispatch => sub { shift->res->headers->server('Some server'); };

get '/' => sub {
	my $c = shift;
	$c->render(status=>200, text => 'Allowed');
	my $uri      = Mojo::URL->new( $c->req->headers->header('X-Original-URI') || '' );
	my $user = $c->session('user');
    $user ||= 'anonymous';

    if ( !$uri or !defined $uri->scheme or $uri->scheme ne 'https' ) {

        # X-Original-URI is set by nginx
        # The guard require https to prevent man-in-the-middle cookie stealing
        $c->app->log->error("[$user] nginx is not configured correctly: X-Original-URI is invalid. ($uri)");
        $c->render( text => 'nginx is not configured.', status => 500 );
    }
	elsif ( $c->session('user') ) {
	        $c->req->env->{identity} = $c->session('user');
	        if ( $uri =~ m!/logout\b! ) {
	            $c->session( expires => 1, nms_expires => 1 );
	        }
	        $c->res->headers->header( 'X-User', $c->session('user') );
	        $c->render( text => 'Logged in', status => 200 );
		}
	else {
		my $headers = $c->tx->req->headers;
		my $user;
		$user = $headers->header('X-Common-Name') if ($headers);

		if ( $user ) {
			$c->session->{user} = $user;
	        $c->req->env->{identity} = $user;
	        if ( $uri =~ m!/logout\b! ) {
	            $c->session( expires => 1, nms_expires => 1 );
	        }
	        $c->res->headers->header( 'X-User', $c->session('user') );
	        $c->render( text => 'Logged in', status => 200 );
		}
		else {
	        $c->session( expires => ( $c->session('nms_expires') || time + 3600 ) );
	        $c->app->log->warn("[$user] No user in session.". Dumper $c->session);
	        $c->app->log->warn("Recest Headers: ". $c->req->headers->to_string);
   	        $c->render( text => 'Use 401 instead of 302 for redirect in nginx', status => 401 );
	    }
    }
};

app->start;

__END__

=encoding utf8
