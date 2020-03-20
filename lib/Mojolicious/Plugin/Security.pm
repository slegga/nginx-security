package Mojolicious::Plugin::Security;
use Mojo::Base -strict;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON 'j';
use Data::Dumper;
use Mojo::JWT;
use Mojo::JSON 'j';
use Mojo::File 'path';

my $lib;
BEGIN {
    my $gitdir = Mojo::File->curfile;
    my @cats = @$gitdir;
    while (my $cd = pop @cats) {
        if ($cd eq 'git') {
            $gitdir = path(@cats,'git');
            last;
        }
    }
    $lib =  $gitdir->child('utilities-perl','lib')->to_string; #return utilities-perl/lib
};

use lib $lib;
use SH::UseLib;
use Model::GetCommonConfig;
use Model::Users;


=encoding utf8

=head1 NAME

Mojolicious::Plugin::Security

=head1 SYNOPSIS

	package MyApp;
	use Mojo::Base 'Mojolicious';
	use Mojo::File 'path';

	my $lib;
	BEGIN {
	    my $gitdir = Mojo::File->curfile;
	    my @cats = @$gitdir;
	    while (my $cd = pop @cats) {
	        if ($cd eq 'git') {
	            $gitdir = path(@cats,'git');
	            last;
	        }
	    }
	    $lib =  $gitdir->child('utilities-perl','lib')->to_string; #return utilities-perl/lib
	};

	use lib $lib;
	use SH::UseLib;
	use Model::GetCommonConfig;

	sub startup {
		my $self = shift;
		my $gcc = Model::GetCommonConfig->new;
		my $config = $gcc->get_mojoapp_config($0);
		$config->{hypnotoad} = $gcc->get_hypnotoad_config($0);
		$self->config($config);
		$self->secrets($config->{secrets});
		$self->plugin('Mojolicious::Plugin::Security');
		my $logged_in = $self->routes->under('/' => sub {my $c = shift;return 1 if $c->user;return});

=head1 DESCRIPTION

Common module for security issue and utility module.

=head1 HOOKS ADDED

=head2 before_dispatch

Read $app->config->{hypnotoad}->{service_path} and adjust urls.

=head1 HELPERS

=head2 user

Return user object if logged in. Else return undef.

=cut

sub _user {
    say STDERR $_ for @_;
	my $c   = shift;  # Mojolicious::Controller

	my $headers = $c->tx->req->headers;
	$DB::single=2;
	my $uri      = Mojo::URL->new( $headers->header('X-Original-URI')||'');

    if ( !$ENV{TEST_INSECURE_COOKIES} && (!$uri or !defined $uri->scheme or $uri->scheme ne 'https' )) {
        # X-Original-URI is set by nginx
        # The guard require https to prevent man-in-the-middle cookie stealing
        $c->app->log->error("nginx is not configured correctly: X-Original-URI is invalid. ($uri)");
        $c->render( text => 'nginx is not configured.', status => 500 );
    }

	#GET USER
	my $user = $c->session('user'); # User is already authenticated
	if (!$user) { # Set by nginx, client certificate
		$user = $headers->header('X-Common-Name');
	}
	if (!$user) { # Set user with ss0-jwt-token
		if (my $jwt = $c->cookie('sso-jwt-token') ) {
			my $claims;
			eval {
				$claims = Mojo::JWT->new(secret => $c->app->secrets->[0])->decode($jwt);
			} or $c->app->log->error('Did not manage to validate jwt "'.$jwt.'" '.$!.' '.$@. "secret: ". $c->app->secrets->[0]);
			if ($claims) {
				$c->app->log->info('claims is '.j($claims));
				$user = $claims->{user};
				$c->tx->res->cookie('sso-jwt-token'=>'');
			} else {
				say STDERR 'Got jwt but no claims jwt:'. $jwt;
#				say STDERR "secret: ".$c->app->secrets->[0];
				$c->app->log->warn( 'Got jwt but no claims jwt:'. $jwt);
			}
		} else {
			say STDERR "NO JWT:\n".$headers->to_string;
			$c->app->log->warn( 'No jwt cookie');
		}
	}

    #HANDLE USER SET
	if ( $user ) {
        $c->req->env->{identity} = $user;
        $c->session->{user} = $user;
        $c->res->headers->header( 'X-User', $user );
        return  Model::Users->new({user => $user});
	}
    $c->app->log->warn("Not authenticated.");
    $c->app->log->warn("Reqest Headers:\n". $c->req->headers->to_string);
    $c->app->log->warn("Cookie sso-jwt-token: ". ($c->cookie('sso-jwt-token')//'__UNDEF__'));

	return;

}

=head2 register

Auto called from Mojolicious. Do the setup.

=cut

sub register {
  	my ( $self, $app ) = @_;

  	# Register hook
  	if ( my $path = $app->config->{hypnotoad}->{service_path} ) {
  		my @path_parts = grep /\S/, split m{/}, $path;
		$app->hook(before_dispatch =>  sub {
			my ( $c ) = @_;
			my $url = $c->req->url;
			my $base = $url->base;
			$base->path( @path_parts );
			$base->path->trailing_slash(1);
			$url->path->leading_slash(0);
		});
	}

	# Register helpers
	$app->helper(user => sub {_user(@_)});

}
1;
