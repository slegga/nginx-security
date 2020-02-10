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
		$self->app->log->warn("Cookie mojolicious: ". $self->cookie('mojolicious'));
		$self->app->log->info("$user is NOT logged in");
		return $self->render;
	}

	$self->app->log->info("$user logs in");

	$self->session(user => $user);
	if(	my $m = $self->cookie('mojolicious') ) {
		$self->app->log->warn("Success Cookie mojolicious: ". $m);
	}

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
	return	$self->redirect_to('/'.$self->param('base').'/login');
}

=head2 landing_page

Landing page.

=cut

sub landing_page {
	my $self = shift;
	if ($self->is_logged_in) {
		if ($self->param('redirect_uri')) {
			return $self->redirect_to($self->tx->req->headers->header('X-Original-URI')||$self->param('redirect_uri'));
		}
		return $self->render(text=>'ok');
	} else {
#	print STDERR "Not is_logged_in\n";
	return	$self->redirect_to('/'.$self->param('base').'/login');
	}
}
1;
