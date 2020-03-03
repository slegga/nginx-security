#!/usr/bin/env perl

use Mojo::Base -strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Mojo::File 'path';

=head1 NAME

web-login.pl - Master login. The main webserver script.

=cut

# Start command line interface for application

my $gitdir = Mojo::File->curfile;
$gitdir = path(@$gitdir[0 .. $#$gitdir-3]);
for my $repo($gitdir->list({dir=>1})->each) {
	next if !-d $repo;
	my $scriptdir = $repo->child('script');
	next if ! -d $scriptdir;
	for my $file($scriptdir->list->each) {
		next if ! -f $file;
		next if $file->basename !~/web\-/;
		my  $cmd = sprintf("hypnotoad %s %s",($ARGV[0]//''), $file);
		say $cmd;
		say `$cmd`;
	}
}