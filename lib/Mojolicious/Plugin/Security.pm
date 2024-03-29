package Mojolicious::Plugin::Security;
use Mojo::Base -strict -signatures;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON 'j';
use Data::Dumper;
use Mojo::JWT;
use Mojo::JSON 'j';
use FindBin;
use Mojo::Util 'secure_compare';
use Authen::OATH;
use Convert::Base32;
use YAML::Tiny;

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

use Carp::Always;



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
		my $config = $gcc->get_mojoapp_config(__PACKAGE__);
		$self->config($config);
		$self->secrets($config->{secrets});
		$self->plugin('Mojolicious::Plugin::Security'=>{ authorized_groups =>['all'] });
		my $logged_in = $self->routes->under('/' => sub {my $c = shift;return 1 if $c->user;return});
    }

=head1 DESCRIPTION

Common module for security issue and utility module.

Session has only sid - session id
Username for sid is stored in sessions table.
Never store username in session or JWT.

=head1 ENVIRONMENT

=over 4

=item COMMON_CONFIG_DIR - set config dir

=item MOJO_CONFIG - alternative config dir

=item TEST_INSECURE_COOKIES - Set sessions->secure to 0

=item TEST_USER - Set a test user. Overrule security

=back

=head1 ATTRIBUTES

=over 4

=item authorized_groups

Array ref of groups that is allowed to access this web-app. This attribute is optional. If none then authorize my only be done with $c->user eq 'username', or checking that $c->user is not undef (user is authenticated).

=back

=cut

has 'main_module_name';

# config
has 'authorized_groups' => sub{[]};

# All the users in the system
has _users => sub {
    my $users;
    my $userfile = $ENV{COMMON_CONFIG_DIR}||$ENV{MOJO_CONFIG}||"$FindBin::Bin/../../../etc";
    $userfile .= "/users.yml";
    # warn $userfile;
    die "Missing users.yml file $userfile. Please add" if (! -r $userfile );
    my $tmp = YAML::Tiny->read( $userfile );
    $users = $tmp->[0]->{users};
    for my $k(%$users) {
        $users->{$k}->{username} = $k;
    }
    return $users;
};

# db handler
sub _db {
    my $self = shift;
    my $c = shift;
    state $db = Mojo::SQLite->new($c->config->{login_db_dir}. '/session_store.db')->db;
    return $db;
}

=head1 HELPERS

=head2 unauthenticated

Redirects to login page

=cut

sub unauthenticated {
    my ($self,$c) = @_;
    my $url = Mojo::URL->new($c->config->{login_path}.'/login')->query(redirect_uri => $c->url_for,message => 'unauthenticated');
    $c->redirect_to($url);
    return undef; ##no critic

}

=head2 unauthorized

Return standard webpage when trying to access restricted pages

=cut

sub unauthorized {
    my ($self,$c) = @_;
    $c->res->code(403);
    $c->render(code=>403,text => 'You are not authorized to view this page. Contact the webmaster. Your username is '.$c->user->{username}. ' Your groups are '.join (',',@{$c->user->{groups}||[]}). '. You need: ' .join(',',@{$self->authorized_groups}));
    return undef; ##no critic
}

=head2 url_logout

Return logout link as Mojo::URL

=cut

sub url_logout {
    my ($self,$c) = @_;
#    $c->session(expires=>1, message=>'url_logout');
#    die "Missing login_path in mojoapp.yml" if ! $c->config->{login_path};
    return Mojo::URL->new($c->config->{login_path}.'/logout')->to_abs;
}

=head2 url_login

Return landing page link as Mojo::URL

=cut

sub url_login {
    my ($self,$c) = @_;
#    $c->session(expires=>1, message=>'url_logout');
#    die "Missing login_path in mojoapp.yml" if ! $c->config->{login_path};
    return Mojo::URL->new($c->config->{login_path}.'/login')->to_abs;
}


=head2 url_abspath

Like url_for, but return expected url with configured base path. Return string.

=cut

sub url_abspath {
    my ($self,$c,$local_path) = @_;
    my $parts=[];
    push @$parts, $c->config->{hypnotoad}->{service_path} if $c->config->{hypnotoad}->{service_path};
    push @$parts, $local_path;
    my $return = $c->url_for->path->parts($parts);
    return $return;
}

=head2 user

Return user-hash ref {username=>'xyz', groups=>['all']} object if sucess. Else return undef.

=cut

sub user {
    say STDERR "USER:$_" for @_;
    my $self = shift;
	my $c   = shift;  # Mojolicious::Controller
    return {username=>$ENV{TEST_USER},groups=>['all']} if $ENV{TEST_USER};
	my $headers = $c->tx->req->headers;

	#GET USER
	my $sid;

	if (!$sid) {
        $sid = $c->session('sid');
		say STDERR 'GOT sid:'. $sid if $sid;
		say STDERR 'NO sid: '. ($sid//'') if ! $sid;
	}

	if ( !$sid) { # Set user with ss0-jwt-token
		if (my $jwt = $c->cookie('sso-jwt-token') ) {
			say STDERR 'Got jwt:'. $jwt;
            say STDERR "SECRETX ". $c->app->secrets->[0];
			my $claims;
			eval {
				$claims = Mojo::JWT->new(secret => $c->app->secrets->[0])->decode($jwt);
			} or $c->app->log->error('Did not manage to validate jwt "'.$jwt.'" '.$!.' '.$@. "secret: ". $c->app->secrets->[0]);
			if ($claims) {
				$c->app->log->info('claims is '.j($claims));
				$sid = $claims->{sid};
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
	if ( $sid ) {
        my $h = $self->_db($c)->query('select username from sessions where status = ?  and sid = ?','active', $sid)->hash;
        my $username;
        $username = $h->{username} if ref $h;
        if (! $username) {
            $c->app->log->warn( 'Got sid:'. $sid. 'but it is no longer valid.');
            $c->session(sid => undef)
        } else {
            $c->req->env->{identity} = $username;
            $c->session->{sid} = $sid;
            $c->res->headers->header( 'X-User', $username );
            my $users = $self->_users;
            my $user = $users->{$username}||{};
            $user->{username} = $username;
            return $user;
        }
	}

	if ($headers->header('X-Common-Name')) { # Set by nginx, client certificate
		my $username = $headers->header('X-Common-Name');
            my $users = $self->_users;
            my $user = $users->{$username};
            $user->{username} = $username if ref $user;
            return $user;
 	}

    $c->app->log->warn("Not authenticated.");
    $c->app->log->warn("Reqest Headers:\n". $c->req->headers->to_string);

	return;

}

=head2 check

Check username and password of totp.

=cut

sub check {
  my ($self, $c,$user, $pass) = @_;
#  $self->log->warn("$user tries to log in");
  # Success
 # warn "user = $user";
 if (my $u =  $self->_users->{$user}) {
    if ($u->{type} eq 'password') {
        return 1 if (secure_compare($pass,$u->{secret}));
    } elsif ($u->{type} eq 'totp') {
        my $oath = Authen::OATH->new;
	die if ! length($u->{secret});
        my $bytes = decode_base32( $u->{secret} );
        my $correct_otp = $oath->totp($bytes);
	my $delay_otp     = $oath->totp($bytes, time()-30);
        $correct_otp=sprintf("%06d",$correct_otp);
        warn $correct_otp,"\n";
        if (secure_compare($pass,$correct_otp) || secure_compare($pass, $delay_otp)) {
#		$self->log->warn("$user has successfully logged in");
		return 1;
	} else {
#		$self->log->warn("$user has wrong password");
		return;
	}
    } else {
        die "Unkown type";
    }
  }
  # Fail
  return;
}

=head2 is_authorized

Check authorisation. Check users group with authorized groups and return 1 if matching group is found.
If and array ref is given after $c, use this list of authorized groups insted of the default.

=cut

sub is_authorized {
    my ($self, $c, $author_grp) =@_;
    $DB::single=2;
    my $user_hr = $self->user($c);
    if (! $user_hr) {
        $c->log->error("User has not logged in. Authenticate before authorize.");
        return;
    }
    if (ref $author_grp ne 'ARRAY') {
        $author_grp = $self->authorized_groups;
    }
    return 1 if ! $self->authorized_groups || ! @{$self->authorized_groups}; # all are welcome
    for my $g(@{$self->authorized_groups}) {
         return 1  if grep {$g eq $_} @{$self->user($c)->{groups}};
    }
    return; #unauthorized
}


=head2 security_info

For debugging and testing. Get info about classvalues

=cut

sub security_info {
    my ($self, $c) =@_;
    my $return={};
    for my $key(qw/main_module_name authorized_groups/) {
        $return->{$key} = $self->$key;
    }
# config
    return $return;

}

=head1 METHODS

=head2 register

Auto called from Mojolicious. Do the setup.

=cut

sub register {
  	my ( $self, $app, $attributes ) = @_;
    $app->session(httponly=>1);
    die 'Missing $c->config->{hypnotoad}. Please load this configuration before loading plugin' if ! $app->config->{hypnotoad};
    $app->sessions->samesite('None');
    $app->sessions->secure( $ENV{TEST_INSECURE_COOKIES} ? 0 : 1 ); # a try to fix keeping session

	# Register helpers
	for my $h(qw/is_authorized check unauthenticated unauthorized url_logout url_login url_abspath user security_info/ ) {
    	$app->helper($h => sub {$self->$h(@_)});
	}
    for my $key (keys %$attributes) {
        $self->$key($attributes->{$key});
    }
    die 'authorized_groups is not an array referanse' if exists $self->{authorized_groups} && ! ref $self->{authorized_groups} eq 'ARRAY';
}

1;
