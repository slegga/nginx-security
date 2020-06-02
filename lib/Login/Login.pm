package Login::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;
use Clone 'clone';
use MIME::Base64;
use Mojo::Util 'dumper';
use Mojo::JSON 'from_json';
use Mojo::SQLite;
use UUID 'uuid';
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

Render login with passowrd. Has google OAuth2 link.

=cut

has db => sub {Mojo::SQLite->new(shift->config->{login_db_dir}. '/session_store.db')->db};

sub login {
	my $self = shift;
	my $username =    $self->param('user') ||'';
	my $pass =        $self->param('pass') || '';
	my $message =     $self->param('message') || $self->session('message');
    my $redirect;
	if ($redirect = $self->param('redirect_uri')) {
		$self->session(redirect_to => $redirect);
	}
    say STDERR '###################################################################################################################INNE';
    my $sid = $self->session('sid');
    if ($sid) {
    say STDERR '###################################################################################################################SID';
        $self->app->log->warn( "sid found");
        if ( my $res = $self->db->query('select username from sessions where status=? and sid =?','active',$sid ) ) {
            if(my $h = $res->hash ) {
                if ($username = $h->{username}) {
                    return $self->accept_user($username);
                }
            }
        }
    	$self->app->log->warn("Session is not valid anymore remove from session: ". $sid);
        $self->session(sid=>'');
		return $self->render;
    }

    else {
        $self->session(message=>'',expires=>time+300);
        $self->app->log->warn("#Cookie mojolicious: ". ($self->cookie('mojolicious')//'__UNDEF__'));
    #	$self->app->log->warn( "No sid");
       return $self->render if ! $username ||! $pass ;
    	$self->app->log->info( "$username tries to log in");

    	if(! $self->check($username, $pass) ) {
    		$self->app->log->warn("$username is NOT logged in");
    		$self->session(message => 'Wrong user or password');
    		return $self->render;
    	}
    say STDERR '###################################################################################################################BASIC';
    }

    return $self->accept_user($username);

}


=head2 logout

Log out user.

=cut

sub logout {
	my $c = shift;
	my $sid = $c->session('sid');
	$c->db->update('sessions',{ status =>'expired',expires =>time },{sid=>$sid} );
	$c->session(sid => undef);
#	$c->session(expire => 1);

	return	$c->redirect_to($c->config->{login_path});
}

=head2 oauth2_google

Connect with google authentication

=cut

sub oauth2_google {
	my $c = shift;

	my  $redirect = $c->url_for()->userinfo(undef)->port(undef)->host($c->app->config->{hypnotoad}->{hostname})->scheme('https')->path('/xlogin/google');
	#}
    my $get_token_args = {
        client_id => $c->app->config->{oauth2}->{google}->{ClientID},
        redirect_uri => "$redirect",
        scope => 'email',
   };

    $c->oauth2->get_token_p(google => $get_token_args)->then(sub {
        return unless my $provider_res = shift; # Redirct to Facebook
#        $c->session(token => $provider_res->{openid});
		$c->app->log->warn( "id_token=".$provider_res->{id_token});

        my $tmp = (split(/\./, $provider_res->{id_token}))[1];
   		$c->app->log->warn( "id_tokenno2=".$tmp);

#no code here
        my $tmp2 = decode_base64($tmp);
   		$c->app->log->warn( "id_tokenno2decoded=".$tmp2);
		my $payload = from_json($tmp2);
        my $username;
        $username = $payload->{email} if ref $payload;
		$c->app->log->warn( "payload=".dumper($payload));
#        delete $tmp->{id_token}; #tar for mye plass i cookie inneholder base64 {"alg":"RS256","kid":"6fcf413224765156b48768a42fac06496a30ff5a","typ":"JWT"}
        return $c->accept_user($username);
    })->catch(sub {
        $c->session(message => 'Connection refused by Google. '. shift);
        return $c->render("login");
    });

}

=head2 accept_user

Set cookie and render or redirect

=cut

sub accept_user {
    my $self = shift;
    my $username = shift;
    $self->app->log->info("$username logs in");

    my $sid = uuid();
	$self->session(sid=> $sid,message => '');
    $self->session(expires => time + 3600); #last for 1 hour
	$self->db->insert('sessions',{sid=>$sid, username => $username, status =>'active', expires => $self->session('expires') } );
	if (my $redirect = $self->session('redirect_to')) {
		$self->app->log->warn("Redirect to $redirect");
		$self->session('redirect_to' => undef); # remove redirect for later reloging
		return $self->redirect_to($redirect);
	}
	$self->app->log->warn('Render landing for '.$username);
	my $ws = YAML::Tiny->read( ($ENV{COMMON_CONFIG_DIR}||$ENV{HOME}.'/etc').'/hypnotoad.yml' )->[0]->{web_services};
	$self->stash(web_services => $ws);
	return $self->render('login/landing_page');
}

1;
