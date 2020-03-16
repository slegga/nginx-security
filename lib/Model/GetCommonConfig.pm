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

=head1 ENVIRONMENTS VARIABLES

COMMON_CONFIG_DIR = dir to where configuration files are.

=head1 ATTRIBUTES

=head2 config_dir

Default to ~/etc

=cut

has config_dir => sub{ $ENV{COMMON_CONFIG_DIR} ? path($ENV{COMMON_CONFIG_DIR}) : path($ENV{HOME})->child('etc') };

=head1 METHODS

# =head2 get_hypnotoad_config
# Return hypnotoad config from common config file

=cut

sub _get_hypnotoad_config {
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
 		for my $key (keys %$tmp) {
			if ($key eq 'port') {
				push @{$return->{listen}},'http://127.0.0.1:'.$tmp->{port} ;
			} else {
				$return->{$key} = $tmp->{$key};
			}
		}
 	} else {
 		die "Missing config in file ". $cfile->to_string .":  web_services:->$script:";
 	}
 	my $uid = `id -u`;
 	$uid =~s/[\n\s]//g;
# 	$return->{pid_file} = "/run/user/$uid/".$script.'.pid'; #does not work well on centos7
	my $rundir = path($ENV{HOME})->child('run');
	if (! -d $rundir) {
		$rundir->make_path;
	}
	$return->{pid_file} = $rundir->child("$script.pid")->to_string;
	$DB::single=2;
 	return $return;
}


=head2 get_mojoapp_config

Return app config from common config file

=cut


sub get_mojoapp_config {
    my $self = shift;
    die "Not an object $self" if !ref $self;
    my $moniker = basename(shift,'.pl');
    my $cfg= shift;
    my $file = $self->config_dir->child('mojoapp.yml')->to_string;
    die "Common config file $file does not exists" if ! -e $file;
 	my $raw_hr =  YAML::Tiny->read( $file)->[0];
 	die "Empty config file in $file: $raw_hr". Dumper $raw_hr if ! ref $raw_hr eq 'HASH';
 	my $return;
    $return = $raw_hr->{common_config};
    die "Missing mojo_log_path in common_config file $file\n". Dumper $return if ! exists $return->{mojo_log_path};
 	if (exists $raw_hr->{web_services}->{$moniker}) {
		my $tmp = $raw_hr->{web_services}->{$moniker};
		for my $key(keys %$tmp) {
			$return->{$key} = $tmp->{$key};
		}
 	}
	$return->{moniker}       = $moniker;
	$return->{mojo_log_path} = path($raw_hr->{common_config}->{mojo_log_path})->child("$moniker.log")->to_string;
	$return->{secrets} = [ split(/[\n\s]+/, path(($ENV{COMMON_CONFIG_DIR}//$ENV{HOME}.'/etc'),'secrets.txt')->slurp ) ];
 	die "No config in $file" if ! $raw_hr;
	$return->{hypnotoad} = $self->_get_hypnotoad_config($moniker);
 	return $return;
}

1;
