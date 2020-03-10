package Mojolicious::Plugin::Security;
use Mojo::Base 'Mojolicious::Plugin';

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Security


=head1 DESCRIPTION

Common module for security issue and utility module.

=head1 HOOKS ADDED

=head2 before_dispatch

Read $app->config->{hypnotoad}->{service_path} and adjust urls.

=head1 HELPERS

=head2 user

Return user object if logged in. Else return undef.

=cut

sub _user {
	my $self = shift;
	my $c    = shift;
	return @_;

	# return Model::User->new({user=>$dn->{cn}});
}

=head2 register

Auto called from Mojolicious. Do the setup.

=cut

sub register {
  	my ($self, $app, $conf) = @_;

  	# Register hook
  	if ( my $path = $app->config->{hypnotoad}->{service_path} ) {
  		my @path_parts = grep /\S/, split m{/}, $path;
		$self->hook(before_dispatch =>  sub {
			my ( $c ) = @_;
			my $url = $c->req->url;
			my $base = $url->base;
			push @{ $base->path }, @path_parts;
			$base->path->trailing_slash(1);
			$url->path->leading_slash(0);
		});
	}

	# Register helpers
	$app->helpers(user => \&_user);

}
1;