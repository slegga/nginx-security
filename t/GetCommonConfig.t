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
is($m->get_hypnotoad_config($0)->{listen}->[0], 'http://127.0.0.1:42');
like($m->get_hypnotoad_config($0)->{pid_file}, qr'/home/\w+/run/GetCommonConfig\.t\.pid');
is($m->get_mojoapp_config($0)->{secrets}->[0],'abc');
done_testing;
