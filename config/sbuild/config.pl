$chroot_mode = 'unshare';
$unshare_tmpdir_template = '/dev/shm/tmp.sbuild.XXXXXXXXXX';

$clean_source = 0;

$build_arch_all = 1;

$run_lintian = 1;
$lintian_opts = ['-i', '-I', '--pedantic'];

$run_piuparts = 0;
$run_autopkgtest = 0;

1;
