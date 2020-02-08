package Login;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugins;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Model::GetCommonConfig;

use MyApp::Model::Users;
use Data::Dumper;

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
#	my $conf_dir = $ENV{MOJO_CONFIG} ? $ENV{MOJO_CONFIG} : $ENV{HOME}.'/etc';
#	my $conf_file = $conf_dir.'/myapp.conf';
	my $gcc = Model::GetCommonConfig->new;
	$self->plugin(Config => {default => {hypnotoad=>$gcc->get_hypnotoad_config($0)}});
#		die "Missing config file: ".$conf_file if !-f $conf_file;
	my $config = $gcc->get_mojoapp_config($0);
#	warn Dumper $config;
	warn("MISSING accesslogfile in config") if ! exists $config->{'accesslogfile'};
	$self->plugin('Mojolicious::Plugin::AccessLog' => {log => $config->{'accesslogfile'},
		format => ' %h %u %{%c}t "%r" %>s %b "%{Referer}i" "%{User-Agent}i"'});
	$self->log->path($config->{mojo_log_path});
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
	my $logged_in = $r->under('/')->to('login#landing_page');
	$logged_in->any('/')->to('login#landing_page')->name('landing_page')->name('landing_page');
		$logged_in->get('/index')->to('login#landing_page')->name('landing_page');


   $self->helper (is_logged_in => sub {
        my $c = shift;
        return 1 if $c->session('user');
        return;
   });

}

1;
