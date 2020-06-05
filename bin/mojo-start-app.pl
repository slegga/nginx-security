#!/usr/bin/env perl

use strict;
use warnings;
use Mojolicious;
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
use Mojolicious::Commands;
use Model::GetCommonConfig;
my $classname = $ENV{MOJO_CLASSNAME} || $ARGV[0];
die "Missing Mojolicious classname argument" if ! $classname;
my $cfg = Model::GetCommonConfig->new->get_mojoapp_config($classname);
say STDERR  sprintf("%s  %s",($cfg->{hypnotoad}->{service_path}//'__UNDEF__'), ($classname//'__UNDEF__'));

=head1 NAME

web-login.pl - Master login. The main webserver script.

=head1 DESCRIPTION

Not currently in use. May  be used to try local.

=cut

# Start command line interface for application
my $app = Mojo::Server->new->build_app($classname,config => $cfg);
$app->start;

