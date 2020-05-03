package Login;
use Mojo::Base 'Mojolicious';
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Model::GetCommonConfig;
use Mojo::JWT;
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

	#MUST CHANGE WHEN FIXED
	$self->mode('development');
	$DB::single=2;
	my $config =  $self->config;

	if ( scalar keys %{$config} < 3 ) {
		say STDERR Dumper $config;
		my $gcc = Model::GetCommonConfig->new;
		$config = $gcc->get_mojoapp_config($0,{debug=>1});

		$self->config($config);
	} else {
		$config = $self->config;
	}
	$self->secrets($config->{secrets});
	$self->log->path($config->{mojo_log_path});
	$self->log->info('(Re)Start server');
	push @{$self->static->paths}, $self->home->rel_file('static');
	$self->sessions->default_expiration( 3600 * 1 );
	$self->sessions->secure( $ENV{TEST_INSECURE_COOKIES} ? 0 : 1 );
	$self->sessions->cookie_name( $config->{moniker} );

	$self->plugin('MyApp::Plugin::Logger');
	$self->plugin('Mojolicious::Plugin::Security'); # add helper user, add hook
	if (exists $self->config->{oauth2}->{google}) {
        $self->plugin('OAuth2'=> {google => {
            key     => $self->config->{oauth2}->{google}->{ClientID},
            secret  => $self->config->{oauth2}->{google}->{ClientSecret},
        } }
        );
    }
	$self->secrets($config->{secrets});
	my $spath= $config->{hypnotoad}->{service_path};
	if (!$spath) {
		die Dumper $config;
	}
	my $r = $self->routes->under("/$spath");
	$r->get("/logout")->to('login#logout');
	$r->any("/")->to('login#login')->name('landing_page');
	$r->any("/login")->to('login#login')->name('landing_page'); # because of login form
	$r->any("/google")->to('login#oauth2_google')->name('landing_page'); # because of login form


   $self->helper (is_logged_in => sub {
        my $c = shift;
        return 1 if $c->session->{user};
		$self->log->info('No none is logged in:  '. $c->req->headers->to_string);
        return;
   });

	$self->helper (set_jwt_cookie => sub {
		my $c = shift;
		my $claims = shift;

		my $jwt = Mojo::JWT->new(claims => $claims, secret => $self->secrets->[0])->encode;
		$c->cookie('sso-jwt-token', $jwt,{expires => time + 120,secure => $ENV{TEST_INSECURE_COOKIES} ? 0 : 1, path =>'/',samesite =>'Lax', httponly=>1 });
	});
	#slutt flytting
}

1;
