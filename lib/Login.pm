package Login;
use Mojo::Base 'Mojolicious';
#use Mojolicious::Plugins;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Model::GetCommonConfig;
use Mojo::JWT;
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
	my $config = $gcc->get_mojoapp_config($0);


#	$self->plugin(Config => $config);
	$self->config($config);
	$self->config(hypnotoad=>$gcc->get_hypnotoad_config($0));
#		die "Missing config file: ".$conf_file if !-f $conf_file;
#	warn Dumper $config;
#	warn("MISSING accesslogfile in config") if ! exists $config->{'accesslogfile'};
#	$self->plugin('Mojolicious::Plugin::AccessLog' => {log => $config->{'accesslogfile'},
#		format => ' %h %u %{%c}t "%r" %>s %b "%{Referer}i" "%{User-Agent}i"'});
	$self->log->path($config->{mojo_log_path});
	$self->log->info('(Re)Start server');
	push @{$self->static->paths}, $self->home->rel_file('static');
	$self->sessions->default_expiration( 3600 * 1 );
	$self->sessions->secure( $ENV{TEST_INSECURE_COOKIES} ? 0 : 1 );
	$self->sessions->cookie_name( $config->{moniker} );

	$self->plugin('MyApp::Plugin::Logger');
	$self->secrets($config->{secrets});
	$self->helper(users  => sub { state $users = MyApp::Model::Users->new });

	my $r = $self->routes;
	$r->get('/:base/logout')->to('login#logout');
	$r->any('/:base/')->to('login#login')->name('landing_page');
	$r->any('/:base/login')->to('login#login')->name('landing_page'); # because of login form


   $self->helper (is_logged_in => sub {
        my $c = shift;
        return 1 if $c->session->{user};
		$self->log->info('No none is logged in:  '. $c->req->headers->to_string);
        return;
   });

	$self->helper (set_jwt_cookie => sub {
		my $c = shift;
		my $claims = shift;

		my $jwt = Mojo::JWT->new(claims => $claims, secret => $config->{'secrets'}->[0])->encode;
		$c->cookie('sso-jwt-token', $jwt,{expires => time + 60,secure => $ENV{TEST_INSECURE_COOKIES} ? 0 : 1, path =>'/' });
	});
	#slutt flytting


}

1;
