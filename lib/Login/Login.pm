package Login::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;
my $log = Mojo::Log->new;

=head1 NAME

Loging module. Handle login request.

=cut


=head2 login

Render login

=cut

sub login {
	my $self = shift;
	my $user = $self->param('user') || '';
	my $pass = $self->param('pass') || '';
#	$DB::single=2;
	if($self->is_logged_in) {
		if (my $redirect = $self->tx->req->headers->header('X-Original-URI') || $self->param('redirect_uri')) {
			return $self->redirect_to($redirect);
		} else {
			return $self->render('landing_page');
		}
	}
	$self->app->log->info("$user tries to log in");
	if(! $self->users->check($user, $pass) ) {
		$self->app->log->warn("Cookie mojolicious: ". ($self->cookie('mojolicious')//'__UNDEF__'));
		$self->app->log->info("$user is NOT logged in");
		return $self->render;
	}

	$self->app->log->info("$user logs in");

	$self->session(user => $user);
	my $jwt = Mojo::JWT->new(claims => {user=>$user}, secret => $self->app->secrets->[0])->encode;
	$self->res->headers->header('X-JWT', $jwt);

	if (my $redirect = $self->tx->req->headers->header('X-Original-URI') || $self->param('redirect_uri')) {
		return $self->redirect_to($redirect);
	}
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
