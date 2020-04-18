package Mojolicious::Plugin::Security;
use Mojo::Base -strict -signatures;
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
		$self->config($config);
		$self->secrets($config->{secrets});
		$self->plugin('Mojolicious::Plugin::Security');
		my $logged_in = $self->routes->under('/' => sub {my $c = shift;return 1 if $c->user;return});

=head1 DESCRIPTION

Common module for security issue and utility module.

=head1 HOOKS ADDED

=head2 before_dispatch

Read $app->config->{hypnotoad}->{service_path} and adjust urls.

=head1 ATTRIBUTES

=cut

has 'main_module_name';
has config => sub {Model::GetCommonConfig->new->get_mojoapp_config(shift->main_module_name||$0)};
has 'accepted_groups' => sub{[]};

=head1 HELPERS


=head2 is_authorized

Check authorisation. Check users group with authorized groups and return 1 if matching group is found.

=cut

sub is_authorized {
    my ($self, $c) =@_;
    for my $g(@{$self->authorized_groups}) {
        return 1  if grep {$g eq $_}$self->user($c)->{groups};
    }
    return; #unauthorized
}

=head2 unauthenticated

Redirects to login page

=cut

sub unauthenticated {
    my ($self,$c,$format) = @_;
    my $url = Mojo::URL->new($self->config->{login_path}.'/login')->query(redirect_uri => $c->url_for);
    $c->redirect_to($url);
    return undef; ##no critic

}

=head2 url_logout

=cut

sub url_logout {
    my ($self,$c,$format) = @_;
    die if ! $self->config->{login_path};
    return Mojo::URL->new($self->config->{login_path}.'/logout')->to_abs;
}

=head2 user

Return user object if logged in. Else return undef.

=cut

sub user {
    say STDERR $_ for @_;
    my $self = shift;
	my $c   = shift;  # Mojolicious::Controller

	my $headers = $c->tx->req->headers;

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
  	my ( $self, $app, $attributes ) = @_;

	# Register helpers
	for my $h(qw/user unauthenticated url_logout/ ) {
    	$app->helper($h => sub {$self->$h(@_)});
	}
    for my $key (keys %$attributes) {
        $self->$key($attributes->{$key});
    }
}
1;
