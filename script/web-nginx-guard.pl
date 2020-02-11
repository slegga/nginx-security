#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::File 'path';
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Model::GetCommonConfig;
use Data::Dumper;
use Mojo::JWT;
use Mojo::JSON 'j';

my $gcc = Model::GetCommonConfig->new;
#my $name = fileparse($0,'.pl');
#plugin Config => {toadfarm => $gcc->get_hypnotoad_config($0) };
app->config($gcc->get_mojoapp_config($0));
app->config(hypnotoad => $gcc->get_hypnotoad_config($0));

app->sessions->default_expiration( 3600 * 1 );
app->sessions->secure( $ENV{TEST_INSECURE_COOKIES} ? 0 : 1 );
app->sessions->secure( 0 );
app->sessions->cookie_name(app->config->{moniker});
app->log->path(app->config('mojo_log_path'));

hook before_dispatch => sub { shift->res->headers->server('Some server'); };

get '/' => sub {
	my $c = shift;
	$c->render(status=>200, text => 'Allowed');
	my $headers = $c->tx->req->headers;
	my $uri      = Mojo::URL->new( $headers->header('X-Original-URI') || '' );

    if ( !$uri or !defined $uri->scheme or $uri->scheme ne 'https' ) {

        # X-Original-URI is set by nginx
        # The guard require https to prevent man-in-the-middle cookie stealing
        $c->app->log->error("nginx is not configured correctly: X-Original-URI is invalid. ($uri)");
        $c->render( text => 'nginx is not configured.', status => 500 );
    }

	#GET USER
	my $user = $c->session('user');
	if (!$user) {
		$user = $headers->header('X-Common-Name');
	}
	if (!$user) {
		if (my $jwt = $c->cookie('sso-jwt-token') ) {
			my $claims;
			eval {
				my $claims = Mojo::JWT->new(secret => $c->app->secrets->[0])->decode($jwt);
			} or {
				$c->app->log->error('Did not manage to validate jwt "$jwt" '.$!.' '.$@);
			};
			if ($claims) {
				$c->app->log->info('claims is '.j($claims));
				$user = $claims->{user};
				$c->tx->res->cookie('sso-jwt-token'=>'');
			}
		}
	}
    $c->req->env->{identity} = $user;

    #HANDLE USER SET
	if ( $user ) {
        $c->req->env->{identity} = $c->session('user');
        if ( $uri =~ m!/logout\b! ) {
            $c->session( expires => 1 );
            $headers->header('X-User',undef);
        	return $c->render( text => 'Logged in', status => 200 );
        }
        $c->session->{user} = $user;
        $c->res->headers->header( 'X-User', $user );
        return $c->render( text => 'Logged in', status => 200 );
	}
    $c->app->log->warn(" No user in session.". Dumper $c->session);
    $c->app->log->warn("Recest Headers: ". $c->req->headers->to_string);
    $c->app->log->warn("Cookie mojolicious: ". ($c->cookie('mojolicious')//'__UNDEF__'));
    $c->app->log->warn("signed_cookie mojolicious: ". ($c->signed_cookie('mojolicious')//'__UNDEF__'));
    $c->app->log->warn("Secrets: ". $c->config->{'secrets'}->[0]);
    $c->render( text => 'Use 401 instead of 302 for redirect in nginx', status => 401 );

};

app->start;

__END__

=encoding utf8
