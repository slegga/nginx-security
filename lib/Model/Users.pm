package Model::Users;

=head1 NAME

Model::Users

=head1 DESCRIPTION

Handle users and security.

=head1 NOTES

=head2 How to generate a google authenticator secret

 perl
 $base32_alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
 print substr($base32_alphabet,rand(32),1) for (0..20);

=cut

use strict;
use warnings;
use Authen::OATH;
use Convert::Base32;
use YAML::Tiny;
#use Mojo::Log;
use FindBin;
use Data::Dumper;
use Encode;
use Mojo::Base -base;
#use Mojolicious::Plugin::AccessLog;

# Log to STDERR
#my $log = Mojo::Log->new;

use Mojo::Util 'secure_compare';

my $USERS;
my $userfile = $ENV{COMMON_CONFIG_DIR}||$ENV{MOJO_CONFIG}||"$FindBin::Bin/../../../etc";
$userfile .= "/users.yml";
# warn $userfile;
if (-r $userfile ) {
    my $tmp = YAML::Tiny->read( $userfile );
    $USERS = $tmp->[0]->{users};
} else {
    $USERS = {
          marcus    => {type=>'password',secret=>'lulz'},
          sebastian => {type=>'password',secret=>'secr3t'},
          foo       => {type=>,'google' ,secret=>"3RZHGD2DLIMBT4C3GLFDG"},
    };
}
#warn Dumper $USERS;
#$log->warn( $USERS );

=head2 check

Check username and password.

=cut

sub check {
  my ($self, $user, $pass) = @_;
#  $self->log->warn("$user tries to log in");
  # Success
 if (my $u =  $USERS->{$user}) {
    if ($u->{type} eq 'password') {
        return 1 if (secure_compare($pass,$u->{secret}));
    } elsif ($u->{type} eq 'google') {
        my $oath = Authen::OATH->new;
	die if ! length($u->{secret});
        my $bytes = decode_base32( $u->{secret} );
        my $correct_otp = $oath->totp($bytes);
	my $delay_otp     = $oath->totp($bytes, time()-30);
        $correct_otp=sprintf("%06d",$correct_otp);
        warn $correct_otp,"\n";
        if (secure_compare($pass,$correct_otp) || secure_compare($pass, $delay_otp)) {
#		$self->log->warn("$user has successfully logged in");
		return 1;
	} else {
#		$self->log->warn("$user has wrong password");
		return;
	}
    } else {
        die "Unkown type";
    }
  }
  # Fail
  return;
}

=head2 padd5

Padd for TOPT

=cut

sub padd5 {
    my $token = shift;
    while (length $token < 6) {
        $token = "0$token";
    }
    return $token;
}

1;