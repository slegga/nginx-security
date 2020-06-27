#!/usr/bin/env perl
use YAML::Tiny;
use Mojo::Base -strict;
use warnings;
use Capture::Tiny 'capture';

use Mojo::File 'path';
my $lib;
BEGIN {
    my $gitdir = Mojo::File->curfile;
    my @cats = @$gitdir;
    while (my $cd = pop @cats) {
        if ($cd eq 'git') {
            $gitdir = path(@cats,'git');
            last;
        }
    }
    $lib =  $gitdir->child('utilities-perl','lib')->to_string; #return utilities-perl/lib
};
use lib $lib;
use SH::UseLib;


=head1 NAME

reload-hypnotoads.pl - reload all hypnotoads

=head1 DESCRIPTION

Reloads all hypnotoad services.

2020-06-05 Has problems reloading. Maybe use systemctl

=cut

sub xsystem {
    my @cmd = @_;
    say join(' ',@cmd);
    my $ret_code;
    my ($stdout,$stderr,@result) = capture {
        $ret_code = system(@cmd);
    };
    say $stdout;
    say $stderr if $stderr;

    $ret_code += 1 if ($stderr =~/line/);
    return $ret_code;
}

# Start command line interface for application
my $cfg = YAML::Tiny->read($ENV{HOME}.'/etc/general.yml')->[0];
my $gitdir = Mojo::File->curfile;
$gitdir = path(@$gitdir[0 .. $#$gitdir-3]);
my $exit=0;

my $ret_code=0;
for my $repo($gitdir->list({dir=>1})->each) {
	next if !-d $repo;
	my $scriptdir = $repo->child('script');
	next if ! -d $scriptdir;
	for my $file($scriptdir->list->each) {
		next if ! -f $file;
		next if $file->basename !~/web\-/;
		my  @cmd = ("hypnotoad", $file);
		push @cmd, $file if $file;
		$exit += xsystem(@cmd);
	}
}
# my @classes = ('Login','MyApp');

# for my $class (@classes) {
#		$ENV{MOJO_CLASSNAME} = $class;
#		my  $cmd = sprintf("MOJO_CLASSNAME=%s hypnotoad /home/%s/git/nginx-security/bin/mojo-start-app.pl", $class, $cfg->{master_user});
#		my @cmd =($cmd);
#		push @cmd, $ARGV[0] if $ARGV[0];
#		say join(' ',@cmd);
#		$exit += xsystem(@cmd);
#}
#say $exit if $exit;
exit($exit);