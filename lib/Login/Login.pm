package Login::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;
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

	$self->app->log->info("$user tries to log in");
	if(! $self->users->check($user, $pass) ) {
		$self->app->log->warn("Cookie mojolicious: ". ($self->cookie('mojolicious')//'__UNDEF__'));
		$self->app->log->info("$user is NOT logged in");
		$self->session(message => 'Wrong user or password');
		return $self->render;
	}

	$self->app->log->info("$user logs in");

	$self->session(user => $user);
	my $jwt = Mojo::JWT->new(claims => {user=>$user}, secret => $self->app->secrets->[0])->encode;
	$self->cookie('sso-jwt-token', $jwt,{expires => time + 60,secure => $ENV{TEST_INSECURE_COOKIES} ? 0 : 1, path =>'/' });

	if (my $redirect = $self->session('redirect_to')) {
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
	my $self = shift;
	$self->session(expires => 1);
	return	$self->redirect_to('/'.$self->param('base').'/');
}



1;
