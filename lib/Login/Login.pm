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
	$DB::single=2;
	if($self->logged_in) {
		return $self->redirect_to($self->tx->req->header('X-Original-URI')||'index');
	}
	$self->app->log->info("$user tries to log in");
	if(! $self->users->check($user, $pass) ) {
		$self->app->log->info("$user is NOT logged in");
		return $self->render
	}

	$self->app->log->info("$user is logged in");

	$self->session(user => $user);

	$self->flash(message => 'Thanks for logging in.');
	$self->redirect_to('index');
}

=head2 logged_in

Return if logged in. Return undef if not.

=cut

sub logged_in {
  my $self = shift;

  return 1 if $self->session('user');
#  $self->redirect_to('login');
  return;
}

=head2 logout

Log out user.

=cut

sub logout {
  my $self = shift;
  $self->session(expires => 1);
  $self->redirect_to('login');
}

=head2 protected

Landing page.

=cut

sub protected {
	my $self = shift;
	return $self->render(text=>'ok');
}
1;
