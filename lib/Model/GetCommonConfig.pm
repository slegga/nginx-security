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

Reads config from config directory set in COMMON_CONFIG_DIR else goes to ~/etc

=head1 ATTRIBUTES

=head2 config_dir

Default to ~/etc

=cut

has config_dir => sub{ $ENV{COMMON_CONFIG_DIR} ? path($ENV{COMMON_CONFIG_DIR}) : path($ENV{HOME})->child('etc') };

=head1 METHODS

=head2 get_hypnotoad_config

Return hypnotoad config from common config file

=cut

sub get_hypnotoad_config {
    my $self = shift;
    die "Not an object $self" if !ref $self;
    my $script = basename(shift,'.pl');
    my $cfile = $self->config_dir->child('hypnotoad.yml');
 	my $raw_hr = YAML::Tiny->read( $cfile )->[0];
# 	say Dumper $raw_hr;
 	my $return;
 	$return = $raw_hr->{common_config};
 	if (exists $raw_hr->{web_services}->{$script}) {
 		my $tmp = $raw_hr->{web_services}->{$script};
		if (exists $tmp->{port}) {
			push @{$return->{listen}},'http://127.0.0.1:'.$tmp->{port} ;
		}

 	} else {
 		die "Missing config in file ". $cfile->to_string .":  web_services:->$script:";
 	}
 	$return->{pid_file} = '/run/user/'.`id -uz`.'/'.$script.'.pid';
 	return $return;
}


=head2 get_mojoapp_config

Return app config from common config file

=cut


sub get_mojoapp_config {
    my $self = shift;
    die "Not an object $self" if !ref $self;
    my $script = basename(shift,'.pl');
    my $file = $self->config_dir->child('mojoapp.yml')->to_string;
    die "Common config file $file does not exists" if ! -e $file;
 	my $raw_hr =  YAML::Tiny->read( $file)->[0];
 	my $return;
 	$return = $raw_hr->{common_config};
    die "Missing mojo_log_path in common_config file $file" if ! exists $return->{mojo_log_path};
 	if (exists $raw_hr->{web_services}->{$script}) {
		my $tmp = $raw_hr->{web_services}->{$script};
		for my $key(keys %$tmp) {
			$return->{$key} = $tmp->{$key};
		}
 	}
	$return->{mojo_log_path} = path($raw_hr->{common_config}->{mojo_log_path})->child("$script.log")->to_string;
 	die "No config in $file" if ! $raw_hr;
 	return $return;
}

1;
