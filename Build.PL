use strict;
use Module::Build;

Module::Build->new(
    module_name => "Net::ZeroConf::Backend::Howl",
    license     => 'perl',
    requires    => {
        'perl'          => '5.006',
        'Net::ZeroConf' => 0,
        'Test::More'    => 0,
    },
    extra_compiler_flags => '-I/usr/local/howl/include/howl-0.9.2',
    extra_linker_flags => '-L/usr/local/howl/lib -lrendezvous -lcorby -lsalt -lpthread',
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;
