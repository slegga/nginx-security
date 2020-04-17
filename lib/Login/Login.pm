package Login::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;
use Clone 'clone';
use MIME::Base64;
use Mojo::Util 'dumper';
use Mojo::JSON 'from_json';
my $log = Mojo::Log->new;

=head1 NAME

Loging module. Handle login request.

=head1 DESCRIPTION

=head1 ENVIRONMENT VARIABLES

=over 3

=item TEST_INSECURE_COOKIES - Turn of secure from cookie for testing with hhtp

=back

=head1 METHODS

=head2 login

Render login

=cut

sub login {
	my $self = shift;
	my $user = $self->param('user') || '';
	my $pass = $self->param('pass') || '';

	if (my $redirect = $self->tx->req->headers->header('X-Original-URI') || $self->param('redirect_uri')) {
		$self->session(redirect_to => $redirect);
	}

	$self->app->log->(info => "$user tries to log in");
	if(! $self->users->check($user, $pass) ) {
		if (! $user && !$pass) {
			return $self->render;
		}
		$self->app->log->warn("Cookie mojolicious: ". ($self->cookie('mojolicious')//'__UNDEF__'));
		$DB::single=2;
		$self->app->log->warn("$user is NOT logged in");
		$self->session(message => 'Wrong user or password');
		return $self->render;
	}

	$self->app->log->info("$user logs in");

	$self->session(user => $user);
	$self->set_jwt_cookie({user=> $user, expires => time +60 });
	if (my $redirect = $self->session('redirect_to')) {
		$self->app->log->warn("Redirect to $redirect");
		$self->session('redirect_to' => undef); # remove redirect for later reloging
		return $self->redirect_to($redirect);
	}
	$self->session(message => '');
	$self->app->log->warn('Render landing for '.$self->session->{user});
	return $self->render('login/landing_page');

}


=head2 logout

Log out user.

=cut

sub logout {
	my $c = shift;
	$c->session(expires => 1);
	return	$c->redirect_to('/'.$c->param('base').'/');
}

=head2 oauth2_google

Connect with google authentication

=cut

sub oauth2_google {
	my $c = shift;
	#my $redirect = $c->tx->req->headers->header('X-Original-URI') || $c->param('redirect_uri') ;
	#if ( $redirect) {
	#    $redirect = path($redirect);
	#} else {
	#    $redirect = $c->url_for()->userinfo(undef)->path('/')->to_abs;
	#}
	#if ($redirect->port) {

	my  $redirect = $c->url_for()->userinfo(undef)->port(undef)->host($c->app->config->{hypnotoad}->{hostname})->scheme('https')->path('/xlogin/google');
	#}
    my $get_token_args = {
        client_id => $c->app->config->{oauth2}->{google}->{ClientID},

        redirect_uri => "$redirect",
        # response_type=> 'code',
        scope => 'email',
   };

    $c->oauth2->get_token_p(google => $get_token_args)->then(sub {
        return unless my $provider_res = shift; # Redirct to Facebook
#        $c->session(token => $provider_res->{openid});
		$c->app->log(warn "id_token=".$provider_res->{id_token});

        my $tmp = (split(/\./, $provider_res->{id_token}))[1];
   		$c->app->log(warn "id_tokenno2=".$tmp);

#no code here
        my $tmp2 = decode_base64($tmp);
   		$c->app->log(warn "id_tokenno2decoded=".$tmp2);
		my $payload = from_json($tmp2);
        my $user;
        $user = $payload->{email} if ref $payload;
		$c->app->log(warn "payload=".dumper($payload));
#        delete $tmp->{id_token}; #tar for mye plass i cookie inneholder base64 {"alg":"RS256","kid":"6fcf413224765156b48768a42fac06496a30ff5a","typ":"JWT"}
        $c->session(google_idt => $payload );
        $c->session(user => $user);
        my $redirect = $c->session('redirect_to');
        $c->session('redirect_to'=> undef);
        $c->redirect_to($redirect);
    })->catch(sub {
        $c->session(message => 'Connection refused by Google. '. shift);
        $c->render("login");
    });

}

1;
