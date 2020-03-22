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
#use Mojolicious::Lite;
use Model::GetCommonConfig;
my $cfg = Model::GetCommonConfig->new->get_mojoapp_config($0);
warn $cfg->{hypnotoad}->{service_path};
#my $rs=app->routes;
#$rs->route($cfg->{hypnotoad}->{service_path})->detour('Login',{secrets=>$cfg->{secrets} });
#app->routes($rs);
#app->start;
# BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
# use Mojolicious::Commands;

=head1 NAME

web-login.pl - Master login. The main webserver script.

=cut

# Start command line interface for application
my $app = Mojo::Server->new->build_app('Login');
$app->routes->pattern(Mojolicious::Routes::Pattern->new('/'.$cfg->{hypnotoad}->{service_path}));
$app->start;
#Mojolicious::Commands->start_app('Login');

