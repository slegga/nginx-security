package Login;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugins;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;

use MyApp::Model::Users;


=head1 NAME

Login

=head1 DESRIPTION

Main lib for Nginx Login page.

=head1 METHODS

=head2 startup

Main loop for Login page.

=cut


sub startup {
	my $self = shift;
	my $conf_dir = $ENV{MOJO_CONFIG} ? $ENV{MOJO_CONFIG} : $ENV{HOME}.'/etc';
	my $conf_file = $conf_dir.'/myapp.conf';
	$self->plugin(Config => {default => {hypnotoad => { listen => ['http://127.0.0.1:8102'], proxy => 1, workers => 3 }}});
		die "Missing config file: ".$conf_file if !-f $conf_file;
	my $config = $self->plugin('Mojolicious::Plugin::Config' => {file => $conf_file});
	$self->plugin('Mojolicious::Plugin::AccessLog' => {log => $config->{'accesslogfile'},
		format => ' %h %u %{%c}t "%r" %>s %b "%{Referer}i" "%{User-Agent}i"'});
	push @{$self->static->paths}, $self->home->rel_file('static');
	$self->sessions->cookie_name('nginx-guard');
	$self->sessions->default_expiration( 3600 * 1 );
	$self->sessions->secure( $ENV{TEST_INSECURE_COOKIES} ? 0 : 1 );

	$self->plugin('MyApp::Plugin::Logger');
	$self->secrets($config->{secrets});
	$self->helper(users  => sub { state $users = MyApp::Model::Users->new });

	my $r = $self->routes;
	$r->any('/login')->to('login#login')->name('login');
	$r->get('/logout')->to('login#logout');
	my $logged_in = $r->under('/')->to('login#logged_in');
	$logged_in->get('/protected')->to('login#protected');
	$logged_in->any('/')->to('login#protected')->name('protected');
}

1;
