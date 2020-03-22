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
my $classname = $ARGV[0]||$ENV{MOJO_CLASSNAME};
die "Missing Mojolicious classname argument" if ! $classname;
my $cfg = Model::GetCommonConfig->new->get_mojoapp_config($classname);
say STDERR  sprintf("%s  %s",($cfg->{hypnotoad}->{service_path}//'__UNDEF__'), ($classname//'__UNDEF__'));

=head1 NAME

web-login.pl - Master login. The main webserver script.

=cut

# Start command line interface for application
my $app = Mojo::Server->new->build_app($classname,config => $cfg);
$app->routes->pattern(Mojolicious::Routes::Pattern->new('/'.$cfg->{hypnotoad}->{service_path}));
$app->start;

