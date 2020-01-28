package Model::GetCommonConfig;
use Mojo::Base -base, -signatures;
use Mojo::SQLite;
use Mojo::File 'path';
use open ':encoding(UTF-8)';
use YAML::Tiny;
use Data::Dumper;
use File::Basename;

=head1 NAME

Model::GetCommonConfig - Module for extracting common config. Especially hypnotoad.

=head1 DESCRIPTION

Give config for script.

=head1 ATTRIBUTES

=head2 config_dir

Default to ~/etc

=cut

has config_dir => sub{ path($ENV{HOME})->child('etc') };

=head1 METHODS

=head2 get_hypnotoad_config

=cut

sub get_hypnotoad_config {
    my $self = shift;
    my $script = basename(shift);
 	my $raw_hr = YAML::Tiny->read( $self->config_dir->child('hypnotoad.yml') )->[0];
# 	say Dumper $raw_hr;
 	my $return;
 	$return = $raw_hr->{common};
 	if (exists $raw_hr->{web_services}->{$script}) {
 		my $tmp = $raw_hr->{web_services}->{$script};
		if (exists $tmp->{port}) {
			push @{$return->{listen}},'127.0.0.1:'.$tmp->{port} ;
		}

 	} else {
 		die "Missing config for $script";
 	}
 	$return->{pid_file} = '/run/'.$script.'.pid';
 	return $return;
}


1;