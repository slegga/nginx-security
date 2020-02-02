use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Mojo::File 'path';
use Carp::Always;
# GetCommonConfig.pm - Module for extractng common config. Especially hypnotoad.
 $ENV{COMMON_CONFIG_DIR}='t/etc';
use Model::GetCommonConfig;

unlike(path('lib/Model/GetCommonConfig.pm')->slurp, qr{\<[A-Z]+\>},'All placeholders are changed');
my $m  = Model::GetCommonConfig->new(config_dir =>path('t/etc') );
is_deeply($m->get_hypnotoad_config($0), {listen=>['127.0.0.1:42'], proxy=>1,workers=>4,pid_file=>'/run/GetCommonConfig.t.pid'}, 'output is ok');
done_testing;
