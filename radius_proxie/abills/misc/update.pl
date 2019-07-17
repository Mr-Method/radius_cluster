#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use v5.16;
use feature 'say';

=head1 NAME

  ABillS Update script

=head1 VERSION

  0.03

=head1 SYNOPSIS

  update.pl - script for updating ABillS
  
  Arguments:
     -D, --debug      - numeric(1..7), level of verbosity
     --branch         - string, git branch to use for update
     --clean          - reload full git repository
     --prefix         - ($base_dir),  where your ABillS directory lives
     --tempdir        - place where script store temprorary sources
     --source         - which system to use while update cvs(untested) or git(default)
     --git-repo       - username@host, where abills.git repository is located
     --skip-check-sql - will not fault if your MySQL Server version is lower than recommended
     --skip-backup    - skip copying current sources
     --login          - support login
     --password       - support password
     --license, -dl   - ONLY renew license

=head1 PURPOSES

  + Check perl version
  + Check perl modules
  + Update sources for current installation (git)
    + backup current sources
    + check free space
    + TODO: update commercial modules
  
  - Update DB scheme prior to current version
  - Update license for commercial users

=cut

our $VERSION = 0.03;

# Core modules from at least Perl 5.6
use Getopt::Long qw/GetOptions HelpMessage :config auto_help auto_version ignore_case/;
use Pod::Usage qw/pod2usage/;
use File::Copy qw/copy/;
use Term::Complete qw/Complete/;
use POSIX qw/strftime/;
use Digest::MD5;

our (%conf, @MODULES, %OPTIONS);

BEGIN {
  %OPTIONS = (
    skip_check_sql => '',
    skip_backup    => '',
    clean          => '',
    renew_license  => '',
    PREFIX         => '/usr/abills',
    TEMP_DIR       => '/tmp',
    GIT_BRANCH     => 'master',
    SOURCE         => 'git',
    DEBUG          => 0,
    GIT_REPO_HOST  => 'git@abills.net.ua',
    USERNAME       => '',
    PASSWORD       => '',
    update_sql     => '',
  );

  GetOptions(
    'debug|D=i'                     => \$OPTIONS{DEBUG},
    'branch=s'                      => \$OPTIONS{GIT_BRANCH},
    'clean'                         => \$OPTIONS{clean},
    'prefix=s'                      => \$OPTIONS{PREFIX},
    'tempdir=s'                     => \$OPTIONS{TEMP_DIR},
    'source=s'                      => \$OPTIONS{SOURCE},
    'git-repo=s'                    => \$OPTIONS{GIT_REPO_HOST},
    'skip_check_sql|skip-check-sql' => \$OPTIONS{skip_check_sql},
    'skip_backup|skip-backup'       => \$OPTIONS{skip_backup},
    'login=s'                       => \$OPTIONS{USERNAME},
    'password=s'                    => \$OPTIONS{PASSWORD},
    'dl|license'                    => \$OPTIONS{renew_license},
    'sql-update|sql_update'         => \$OPTIONS{update_sql}
  ) or die pod2usage();

  if (!-d $OPTIONS{PREFIX} && !-d "$OPTIONS{PREFIX}/lib") {
    die " --prefix should point to abills sources dir\n";
  }
}

# Load ABillS Libraries
use lib $OPTIONS{PREFIX} . '/lib';
use lib $OPTIONS{PREFIX} . '/Abills/mysql';
use lib $OPTIONS{PREFIX} . '/';

do "libexec/config.pl";
use Abills::Fetcher qw/web_request/;
use Abills::Base qw/_bp urlencode/;

_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

my $base_dir = $OPTIONS{PREFIX};
my $TEMP_DIR = $OPTIONS{TEMP_DIR};
my $GIT_BRANCH = $OPTIONS{GIT_BRANCH};
my $SOURCE = $OPTIONS{SOURCE};
my $DEBUG = $OPTIONS{DEBUG};
my $GIT_REPO_HOST = $OPTIONS{GIT_REPO_HOST};

my $ABILLS_UPDATE_URL = "http://abills.net.ua/misc/update.php";
my $SUPPORT_URL = 'https://support.abills.net.ua/index.cgi';

if ($DEBUG) {
  require Carp::Always;
}

my %SYSTEM_INFO = get_os_information();
my %HARDWARE_INFO = get_hardware_info();

require Admins;
require Abills::SQL;
# Connect to DB
my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} }
);
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID} || 2, { IP => '127.0.0.1' });

my %ENABLED_MODULES = map {$_ => 1} @MODULES;

my $date = strftime("%Y%m%d", localtime(time));
my $backup_dir = $base_dir . "_$date";

my $recommended_perl_version = '5.018000';
my $minimal_perl_version = '5.018000';
my $recommended_sql_version = '5.7.6';

my @abills_var_directories = (
  '/var',
  '/var/log',
  '/var/q',
  '/var/log/ipn',
);

my $ABILLS_VERSION = get_abills_version();

my $SYS_ID = get_sys_id();
my $ABILLS_SIGN = authenticate();
chomp $SYS_ID;
chomp $ABILLS_SIGN;

if (!$ABILLS_SIGN) {
  say 'Authentication required';
  exit 0;
}

if ($OPTIONS{renew_license}) {
  if (renew_license()) {
    say 'License have been successfully saved';
  }
  else {
    say 'Failed to save new license. Please check errors above';
  }
  exit 0;
}

if ($OPTIONS{update_sql}) {
  if (update_sql()) {
    say 'SQL have been successfully updated';
  }
  else {
    say 'Failed to update SQL. Please check errors above';
  }
  exit 0;
}

check_perl_version($recommended_perl_version);
check_used_perl_modules();

if (!$OPTIONS{skip_check_sql} && !check_sql_version()) {
  print "  If you want to skip MySQL version check, use --skip-check-sql \n";
  exit 1;
};

main();

exit 0;

#**********************************************************
=head2 main()

=cut
#**********************************************************
sub main {

  if ($DEBUG < 4 && !$OPTIONS{skip_backup}) {
    sources_backup() or return 0;
  }

  sources_update($SOURCE) or return 0;

  if (update_sql()) {
    say 'SQL have been successfully updated';
  }
  else {
    say 'Failed to update SQL. Please check errors above';
  }

  print "Checking for updated modules \n";
  update_modules();

  renew_license();

  print "Success \n";

}

#**********************************************************
=head2 get_os_information()

=cut
#**********************************************************
sub get_os_information {

  return %SYSTEM_INFO if (%SYSTEM_INFO);

  my $OS = `uname -s`;
  my $OS_VERSION = `uname -r`;
  my $MACH = `uname -m`;
  my $ARCH = `uname -p`;
  my $KERNEL = `uname -s`;

  chomp $OS;
  chomp $OS_VERSION;
  chomp $MACH;
  chomp $ARCH;
  chomp $KERNEL;

  my $OS_NAME = '';
  my $OS_STR = '';

  if ($OS eq 'SunOS') {
    $OS = 'Solaris';
    $OS_STR = "${OS} ${OS_VERSION}(${ARCH}" . `uname -v` . ")";
  }
  elsif ($OS eq 'AIX') {
    $OS_STR = "${OS} " . `oslevel` . "(" . `oslevel -r` . ")";
  }
  elsif ($OS eq 'FreeBSD') {
    $OS_NAME = "FreeBSD";
    #$OS_VERSION=`uname -r | awk -F\. '{ print $1 }'`
  }
  elsif ($OS eq 'Linux') {

    # TODO: check /etc/os-release first
    #    if ( -f '/etc/os-release' ) {
    #      $OS_NAME = `cat /etc/os-release | awk '{ print \$1 \$2 }'`;
    #      $OS_VERSION = `cat /etc/os-release | awk '{ print \$3 }'`;
    #    }
    #    els
    if (-f '/etc/altlinux-release') {
      $OS_NAME = `cat /etc/altlinux-release | awk '{ print \$1 \$2 }'`;
      $OS_VERSION = `cat /etc/altlinux-release | awk '{ print \$3 }'`;
    }
    elsif (-f '/etc/redhat-release') {
      $OS_NAME = 'RedHat';
      $OS_NAME = `cat /etc/redhat-release | awk '{ print \$1 }'`;
      $OS_VERSION = `cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`;
    }
    elsif (-f '/etc/SuSE-release') {
      $OS_NAME = 'openSUSE';
      $OS_VERSION = `cat /etc/SuSE-release | grep 'VERSION' | tr "\n" ' ' | sed s/.*=\ //`;
    }
    elsif (-f '/etc/mandrake-release') {
      $OS_NAME = 'Mandrake';
      $OS_VERSION = `cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`;
    }
    elsif (-f '/etc/slackware-version') {
      $OS_NAME = `cat /etc/slackware-version | awk '{ print \$1 }'`;
      $OS_VERSION = `cat /etc/slackware-version | awk '{ print \$2 }'`;
    }
    elsif (-f '/etc/gentoo-release') {
      $OS_NAME = `cat /etc/os-release | grep "^NAME=" | awk -F= '{ print \$2 }'`;
      $OS_VERSION = `cat /etc/gentoo-release`;
    }
    elsif (-f '/etc/UnitedLinux-release') {
      $OS_NAME .= "[" . `cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//` . "]";
    }
    else {
      $OS_NAME = `cat /etc/issue| head -1 |awk '{ print \$1 }'`;
      $OS_VERSION = `cat /etc/issue | head -1 |awk '{ print \$3 }'`;
    }

    if ($OS_NAME eq 'Ubuntu') {
      $OS_VERSION = `cat /etc/issue | awk '{ print \$2 }'`;
    }
  }

  chomp $OS;
  chomp $OS_VERSION;
  chomp $MACH;
  chomp $OS_NAME;
  chomp $ARCH;
  chomp $KERNEL;

  $OS_STR = join(' ', grep {$_ ne ''} ($OS_NAME, $OS_VERSION));

  return %SYSTEM_INFO = (
    OS         => $OS,
    OS_VERSION => $OS_VERSION,
    MACH       => $MACH,
    OS_NAME    => $OS_NAME,
    OS_STR     => $OS_STR,
    ARCH       => $ARCH,
    KERNEL     => $KERNEL,
  );
}

#**********************************************************
=head2 get_hardware_info()

=cut
#**********************************************************
sub get_hardware_info {
  return %HARDWARE_INFO if (%HARDWARE_INFO);

  %SYSTEM_INFO = get_os_information() if (!%SYSTEM_INFO);
  my %info = ();

  my $cpu = '';
  my $cpu_count = '';
  my $vga_device = '';
  my $vga_vendor = '';
  my $net_if = '';
  my $ram = '';
  my $hdd = '';
  my $hdd_serial = '';
  my $hdd_size = '';
  my $interfaces = '';

  if ($SYSTEM_INFO{OS} eq 'FreeBSD') {
    $cpu = `grep -i CPU: /var/run/dmesg.boot | cut -d \: -f2 | tail -1`;
    $cpu ||= `sysctl hw.model | sed "s/hw.model: //g"`;
    $cpu_count = `sysctl -a | egrep -i 'hw.ncpu' | awk '{ print \$2 }'`;

    $vga_device = `pciconf -lv |grep -B 3 VGA |grep device |awk -F \' '{print \$2}' |paste -s -`;
    $vga_vendor = `pciconf -lv |grep -B 3 VGA |grep vendor |awk -F \' '{print \$2}' |paste -s -`;

    $net_if = `grep -i Network /var/run/dmesg.boot |cut -d \: -f1`;
    $interfaces = `ifconfig | grep "[a-z0-9]: f" | awk '{ print \$1 }' | grep -v -E "ng*|vlan*|lo*|ppp*|ipfw*"`;

    $ram = `grep -i "real memory" /var/run/dmesg.boot | sed 's/.*(\([0-9]*\) MB)/\1/' | tail -1`;
    $ram ||= `sysctl hw.physmem | awk '{ print \$2 "/ 1048576" }' | bc`;

    $hdd = `grep -Ei '^ada?[0-9]?:' /var/run/dmesg.boot | tail -1`;
    $hdd_serial = `grep -Ei '^ada?[0-9]?:' /var/run/dmesg.boot | grep Serial | awk '{ print \$4 }'`;
    $hdd_size = `grep -Ei '^ada?[0-9]?:' /var/run/dmesg.boot | tail -1 | awk '{ print \$2 }'`;
  }
  elsif ($SYSTEM_INFO{OS} eq 'Linux') {
    $cpu = `cat /proc/cpuinfo |egrep '(model name)' | tail -1 |sed 's/.*\: //'|paste -s`;
    $cpu_count = `cat /proc/cpuinfo | grep '^processor' | tail -1 | sed 's/.*\: //'`;
    chomp ($cpu_count);
    if ($cpu_count && $cpu_count =~ /^\d+$/) {
      $cpu_count += 1;
    }

    $ram = `free -m |grep Mem |awk '{print \$2}'`;

    # TODO    _install pciutils hdparm bc
    $vga_device = `lspci |grep VGA |cut -f5- -d " "`;
    $net_if = `ifconfig | grep '^[a-z0-9]' | awk '{ print \$1 }' | grep -v -E "ng*|vlan*|lo*|ppp*|ipfw*"`;
    $interfaces = `lspci -mm | grep Ethernet |cut -f4- -d " "`;

    $hdd_size = `fdisk -l |head -2 |tail -1|awk '{print \$3,\$4}'|sed 's/,//'`;
    my $hdd_disk_name = `fdisk -l | head -2 | tail -1 | awk '{ print \$2 }' | sed 's/://'`;
    if ($hdd_disk_name) {
      chomp $hdd_disk_name;
      $hdd_serial = `hdparm -I ${hdd_disk_name} | grep Serial | awk -F ":" '{print \$2}' | tr -cs -`;
      $hdd = `hdparm -I ${hdd_disk_name} | grep Model | awk -F ":" '{print \$2}' | tr -cs -`;
    }
  }

  chomp $cpu;
  chomp $cpu_count;
  chomp $vga_device;
  chomp $vga_vendor;
  chomp $net_if;
  chomp $ram;
  chomp $hdd;
  chomp $hdd_serial;
  chomp $hdd_size;
  chomp $interfaces;

  my $system_info_string = join('^',
    map {$_ || ''} (
      $cpu, $cpu_count,
      $vga_device, $vga_vendor,
      $net_if, $ram,
      $hdd, $hdd_serial, $hdd_size,
      $interfaces
    )
  );
  $system_info_string =~ s/\"//gm;
  $system_info_string =~ s/\n/ /gm;

  my $hardware_id_digest = Digest::MD5->new();
  $hardware_id_digest->add($system_info_string);
  my $hardware_id = $hardware_id_digest->hexdigest();

  %info = (
    id         => $hardware_id,
    cpu        => $cpu,
    cpu_count  => $cpu_count,
    vga_device => $vga_device,
    vga_vendor => $vga_vendor,
    net_if     => $net_if,
    ram        => $ram,
    hdd        => $hdd,
    hdd_serial => $hdd_serial,
    hdd_size   => $hdd_size,
    interfaces => $interfaces,
    sys_info   => $system_info_string
  );

  return %info;
}


#**********************************************************
=head2 authenticate()

=cut
#**********************************************************
sub authenticate {

  return $ABILLS_SIGN if ($ABILLS_SIGN);

  if (-f '/usr/abills/libexec/.updater') {
    $ABILLS_SIGN = _read_file('/usr/abills/libexec/.updater');
    chomp $ABILLS_SIGN;
  }

  if (!${ABILLS_SIGN}) {
    my ($username, $password) = _get_support_credentials();

    my $hostname = `hostname`;
    chomp($hostname);

    my $request_result = web_request($ABILLS_UPDATE_URL, {
        CURL           => 1,
        REQUEST_PARAMS => {
          SIGN     => $HARDWARE_INFO{id},
          L        => $username,
          P        => $password,
          H        => $hostname,
          SYS_ID   => $SYS_ID,
          sys_info => $HARDWARE_INFO{sys_info},
        },
        DEBUG          => $DEBUG > 4
      }
    );

    if (!$request_result || $request_result !~ 'Registration complete') {
      say 'Authorization failed';
      return 0;
    }

    $ABILLS_SIGN = $HARDWARE_INFO{id};
    `echo -n $ABILLS_SIGN > /usr/abills/libexec/.updater`;
  }

  return $ABILLS_SIGN;
}

#**********************************************************
=head2 sources_update()

  Arguments :
    $type - 'git', 'free', 'snapshot'

=cut
#**********************************************************
sub sources_update {
  my ($type) = @_;

  if ($type eq 'git' && check_ssh_access()) {

    # Check git is present
    my $git = `which git`;
    chomp($git);
    if (!$git) {
      print "Git is not installed. Please install git \n";
      exit 1;
    }

    my $git_cmd = '';
    my @git_options = ();
    my @command_options = ();

    my $temprorary_abills_git_sources_dir = "$TEMP_DIR/abills";
    if (-d  $temprorary_abills_git_sources_dir) {
      $git_cmd .= 'pull';
      push (@git_options, "-C $temprorary_abills_git_sources_dir");
      if ($GIT_BRANCH) {
        push (@command_options, "origin $GIT_BRANCH");
      }
    }
    else {
      $git_cmd .= "clone";
      push (@git_options, "-C $TEMP_DIR");
      if ($GIT_BRANCH) {
        push (@command_options, "-b $GIT_BRANCH --single-branch");
        push (@command_options, 'git@abills.net.ua:abills.git');
      }
    }

    my $cmd = "$git " . join(' ', @git_options, $git_cmd, @command_options);

    print "Git update: $cmd \n" if ($DEBUG);

    my $update_error = system($cmd);
    if ($update_error) {
      print "
      #################################################################
      #                    Git update error                           #
      #################################################################
      
        Check git errors below.\n";

      return 0;
    }

  }

  my $work_copy = $TEMP_DIR . '/abills_rel';

  if (-e $work_copy && $OPTIONS{clean}) {
    unlink $work_copy;
  }
  if (!-e $work_copy) {
    mkdir $work_copy;
  }

  print "Copying working directory to $work_copy \n";
  my $copy_prep_success = system("cp -Rf $TEMP_DIR/abills/* ${work_copy}/") == 0;
  $copy_prep_success = system("find ${work_copy} | grep CVS | xargs rm -Rf") == 0 if ($copy_prep_success);
  $copy_prep_success = system("find ${work_copy} | grep .git | xargs rm -Rf") == 0 if ($copy_prep_success);

  if (!$copy_prep_success) {
    print "  Error while copying work directory \n";
    return 0;
  }

  for my $dir (@abills_var_directories) {
    mkdir "$work_copy$dir" if (!-d "$work_copy$dir");
    system("chown -R nobody $work_copy$dir");
  }

  return system("cp -Rf ${work_copy}/* $OPTIONS{PREFIX}/") == 0;
}

#**********************************************************
=head2 sources_backup()

=cut
#**********************************************************
sub sources_backup {

  if (-e $backup_dir && -d $backup_dir) {
    print "Skipping sources backup. Already have today backup \n";
    return 1;
  }

  my $sources_size_kb = _get_directory_size($base_dir);

  # -P (POSIX) -l (local filesystems) -B k (size in Kilobytes)
  my $df_reply_kb = `df -P -l -B k $base_dir | tail -1 | awk -F' ' '{ print \$4 }'`;
  chomp $df_reply_kb;

  if (!($sources_size_kb && $df_reply_kb) || ($sources_size_kb !~ /^\d+$/ && $df_reply_kb !~ /^\d+$/)) {
    if (Term::Complete::Complete->("Can't check free space. Continue anyway? [y/N]") !~ /y/i) {
      exit 0;
    }
  }

  if ($df_reply_kb && $df_reply_kb =~ /^(\d+)/) {
    $df_reply_kb = $1 || 0;
  };

  my $free_space_kb = $df_reply_kb - $sources_size_kb;

  my $free_space_mb_formatted = sprintf("%.2f", $free_space_kb / 1024);
  my $abills_size_mb_formatted = sprintf("%.2f", $sources_size_kb / 1024);
  print "Free space available : $free_space_mb_formatted Mb ( $abills_size_mb_formatted Mb needed ) \n";

  if ($free_space_kb - ($sources_size_kb * 2) < 0) {
    print "Not enough free space to make copy of current abills sources directory.\n";
    # TODO: ask delete old backups
    exit 1;
  }

  print "Copying $base_dir sources to $backup_dir.\n";
  print "Size: ($abills_size_mb_formatted Mb). This can take a while. \n\n";

  #  return 1;
  return system("cp -Rfp $base_dir $backup_dir") == 0;
}

#**********************************************************
=head2 update_sql()

=cut
#**********************************************************
sub update_sql {
  if (!(-e '/tmp/abills/db/update/') || !(-d '/tmp/abills/db/update')) {
    say "ERROR: No updated abills";
    return 0;
  }

  my $last_updated = '';

  # Read from `config` table las tupdate
  say "Read from config param UPDATE_SQL";
  $admin->query("SELECT value FROM config WHERE param='UPDATE_SQL';", undef, { COLS_NAME => 1 });

  if ($admin->{errno}) {
    say "Fatal error while getting UPDATE_SQL. " . ($admin->{errstr} || '');
    return 0;
  }

  my $list = $admin->{list};
  if ($list && ref $list eq 'ARRAY' && scalar @{$list}) {
    $last_updated = $list->[0]->{value};
  }

  if ($last_updated eq '') {
    say "Old mode updating";
    my $update_url = '';
    my $update_date = 0;

    if ($conf{version}) {
      (undef, $update_date) = split('\/', $conf{version});
      $update_url = "http://abills.net.ua/wiki/doku.php?id=abills:changelogs:0.5x&do=export_raw";
      say "Update date: $update_date";
    }

    if (-e "$base_dir/VERSION") {
      my $version_content = _read_file("$base_dir/VERSION");
      (undef, $update_date) = split(' ', $version_content);
      $update_date ||= 0;
      $update_url = "http://abills.net.ua/wiki/doku.php?id=abills:changelogs:0.7x&do=export_raw";
    }

    if ($update_date < 99999999) {
      _download_and_parse_sql_updates($update_url, $update_date);
    }

    # Update last updated version
    my $version = _read_file("$TEMP_DIR/abills/VERSION") or return 0;
    chomp $version;
    my ($year, $day, $mon) = split('-', POSIX::strftime "%Y-%m-%d", localtime(time));
    _write_to_file("$TEMP_DIR/abills", "$version $year$mon$day");

    return 1;
  }

  say "Last updated file - $last_updated";
  use Abills::Misc qw/_get_files_in/;

  my $update_files = _get_files_in($TEMP_DIR . '/abills/db/update');

  my @sorted_updated_files = sort {$a cmp $b} @$update_files;

  my $dev_update = pop @sorted_updated_files;

  my @to_execute = grep {$_ gt $last_updated}  @sorted_updated_files;

  # execute sql
  foreach my $file_to_execute (@to_execute) {
    # read each line and execute
    _db_execute_from_file($file_to_execute);
    $last_updated = $file_to_execute;
  }

  # Write new last update to `config`
  $admin->query(q{REPLACE INTO config(`param`, `value`) VALUES ('UPDATE_SQL', ?)}, 'do', { Bind => [ $last_updated ] });

  if ($admin->{errno}) {
    say "Couldn't save UPDATE_SQL. " . ($admin->{errstr} || '');
  }

  return 1;
}

#**********************************************************
=head2 restart_servers()

=cut
#**********************************************************
sub restart_servers {

}

#**********************************************************
=head2 renew_license()

=cut
#**********************************************************
sub renew_license {

  #  if [ "${SYS_ID}" != "" ]; then
  #    get_sys_id;
  #  fi;

  my $sign = authenticate();
  return 0 unless $sign;

  my $request_result = web_request($ABILLS_UPDATE_URL, {
      CURL           => 1,
      REQUEST_PARAMS => {
        sign       => $sign,
        SYS_ID     => $SYS_ID,
        VERSION    => $ABILLS_VERSION,
        getupdate => 1,
        get_key    => 1,
      },
      DEBUG          => $DEBUG > 4
    }
  );

  if ($request_result !~ /^\d+$/) {
    say "  !! Failed to receive new license";
    print $request_result;
    if (_read_input('PROCCEED_WITH_WRONG_LICENSE', "Do you want to proceed without license?", 'n') eq 'n') {
      say "Exit";
      exit 1;
    };
    return 0;
  }

  # If we have backup dir and license in it, renew license there
  # So it will be updated later
  if (!$OPTIONS{renew_license} && -d "$TEMP_DIR/abills/libexec") {
    unlink "$TEMP_DIR/abills/libexec/license.key" if (-f "$TEMP_DIR/abills/libexec/license.key");
    _write_to_file($request_result, "$TEMP_DIR/abills/libexec/license.key");
    say 'License saved to new sources';

  }
  # Else if we do not have temp_dir (WHY?)
  elsif (-f "$OPTIONS{PREFIX}/libexec/license.key") {
    # Save old license
    if (-f "$OPTIONS{PREFIX}/libexec/license.key") {
      File::Copy::cp("$OPTIONS{PREFIX}/libexec/license.key", "$OPTIONS{PREFIX}/libexec/license.key.backup")
        or say "Can't save previous license";
    }

    unlink "$OPTIONS{PREFIX}/libexec/license.key";
    _write_to_file($request_result, "$OPTIONS{PREFIX}/libexec/license.key");
  }
  else {
    _write_to_file($request_result, "$OPTIONS{PREFIX}/libexec/license.key");
  }

  return 1;
}

#**********************************************************
=head2 calculate_sys_id()

=cut
#**********************************************************
sub calculate_sys_id {

  my $sys_id = '';
  if ($SYSTEM_INFO{KERNEL} eq 'Linux') {

    my @files_returning_system_id = (
      '/etc/machine-id',
      '/var/lib/dbus/machine-id',
      '/sys/class/dmi/id/product_uuid'
    );

    foreach my $path (@files_returning_system_id) {
      if (-f $path) {
        $sys_id = `cat $path`;
        last;
      }
    }

  }
  elsif ($SYSTEM_INFO{OS} eq 'FreeBSD') {
    $sys_id = `sysctl -a | grep kern.hostuuid`;
  }

  if (!$sys_id) {
    $sys_id = join ('', values %SYSTEM_INFO, localtime);
  }

  chomp($sys_id);
  return $sys_id
}

#**********************************************************
=head2 get_sys_id()

=cut
#**********************************************************
sub get_sys_id {

  return $SYS_ID if ($SYS_ID);

  # Try to get from DB
  $admin->query("SELECT value FROM config WHERE param='SYS_ID';", undef, { COLS_NAME => 1 });
  if ($admin->{errno}) {
    print "Fatal error while getting SYS_ID. " . ($admin->{errstr} || '');
  }
  my $list = $admin->{list};

  if ($list && ref $list eq 'ARRAY' && scalar @{$list}) {
    $SYS_ID = $list->[0]->{value};
  }
  # If not found in DB
  else {
    $SYS_ID = calculate_sys_id();
    $admin->query(q{INSERT INTO config(`param`, `value`) VALUES ('SYS_ID', ?)}, 'do', { Bind => [ $SYS_ID ] });
    if ($admin->{errno}) {
      print "Couldn't save SYS_ID. " . ($admin->{errstr} || '');
    }
  }

  return $SYS_ID;
}

#**********************************************************
=head2 update_modules()

=cut
#**********************************************************
sub update_modules {
  my @modules_to_check = qw(Paysys Ashield Turbo Maps Storage Ureports Cablecat);

  my $directory_to_look_for_new_sources = $TEMP_DIR . '/abills_rel';

  my $find_file_version_in = sub {
    my ($file_name) = shift;

    # Read file until find line with version
    open (my $fh, '<', $file_name) or die "Can't open $file_name : $!\n";

    my $file_version = 0;
    while (my $line = <$fh>) {
      if ($line =~ /VERSION\s?=\s?([0-9.]+)/) {
        $file_version = $1;
        last;
      }
    }

    $file_version;
  };

  my $find_required_version_in = sub {
    my ($file_name) = shift;
    #    REQUIRE_VERSION => 7.13,

    # Read file until find line with version
    open (my $fh, '<', $file_name) or die "Can't open $file_name : $!\n";

    my $required_version = 0;

    while (my $line = <$fh>) {
      if ($line =~ /REQUIRE_VERSION\s?=>\s?([0-9.]+)/) {
        $required_version = $1;
        last;
      }
    }

    $required_version;
  };

  # Table view
  print sprintf("%-17s|%-10s|%-10s\n", 'Module', 'Current', 'Required');
  for my $module (@modules_to_check) {

    my $module_name = ucfirst(lc $module);

    # Skip disabled modules
    next if (!exists $ENABLED_MODULES{$module});

    my $relative_file_path = "/Abills/mysql/$module_name\.pm";
    my $current_full_path = "$base_dir\/$relative_file_path";
    my $webinterface_full_path = "$directory_to_look_for_new_sources/Abills/modules/$module_name/webinterface";

    # Get version from current file
    my $current_version = $find_file_version_in->($current_full_path);

    # Get version from new file
    my $required_version = $find_required_version_in->($webinterface_full_path);

    print sprintf(" %-16s|%-10s|%-10s\n", $module, $current_version, $required_version);

    # Next if the same
    next if ($current_version eq $required_version);

    print "$module should be updated to new version\n";

    # Make backup of old copy
    File::Copy::cp("$base_dir/$relative_file_path", "$base_dir/$relative_file_path\_$current_version");
    print "$module old file saved to $base_dir/$relative_file_path\_$current_version\n";

    # Download
    my $downloaded_module = download_module($module_name, "$base_dir/$relative_file_path");
    if ($downloaded_module) {
      my $new_version = $find_file_version_in->("$base_dir/$relative_file_path");
      print "Successfuly uppdated $module_name to $new_version\n";
    }
    else {
      say " !!! There were problems while downloading $module_name";
    }
  };

  return 1;
}

#**********************************************************
=head2 download_module() - using Sharing

=cut
#**********************************************************
sub download_module {
  my ($module_name, $destination) = @_;

  say "Downloading $module_name";
  my $sys_id = get_sys_id();

  my $module_info = web_request($ABILLS_UPDATE_URL, {
      REQUEST_PARAMS => {
        sign   => $ABILLS_SIGN,
        SYS_ID => $sys_id,
        module => $module_name,
        json   => 1
      },
      CURL           => 1,
      JSON_RETURN    => 1,
      DEBUG          => $DEBUG > 4
    });

  if (!$module_info->{purchased}) {
    my $time = $module_info->{time};
    my $price = $module_info->{price};
    my $file_id = $module_info->{id};

    my $agree_to_buy = _read_input(
      'BUY_' . uc($module_name),
      "\nDo you agree to buy $module_name for $time days? Price is $price USD (y/N)",
      undef,
      {
        CHECK => sub {$_[0] =~ /y|n/i}
      }
    );

    if ($agree_to_buy =~ /n/i) {
      print "Can't update without $module_name.\nPlease disable it and repeat again \n";
      exit 1;
    }
    else {
      # Send buy request
      my ($username, $password) = _get_support_credentials();

      # Check credentials
      my $buyed = web_request($SUPPORT_URL, {
          POST        => "user=$username&passwd=$password&get_index=sharing_user_main&BUY=$file_id&json=1",
          COOKIE      => 1,
          INSECURE    => 1,
          JSON_RETURN => 1,
          DEBUG       => $DEBUG > 4
        });

      if ($buyed && $buyed->{MESSAGE}) {
        my $mes = $buyed->{MESSAGE};
        print "$mes->{message_type} : $mes->{caption} \n $mes->{messaga}";

        if ($mes->{message_type} eq 'err') {
          exit 1;
        };
      }
    }
  }

  # Download new file
  my $file_content = web_request($ABILLS_UPDATE_URL, {
      REQUEST_PARAMS => {
        sign   => $ABILLS_SIGN,
        SYS_ID => $sys_id,
        module => $module_name
      },
      CURL           => 1,
      DEBUG          => $DEBUG > 4
    });

  # Check file
  if (!$file_content || length($file_content) < 100) {

    # Show error if any
    if ($file_content && $file_content =~ /^ERROR:/) {
      say $file_content;
    }

    say "There was an error while receiving module.
    Please try again or download it manually.
    https://support.abills.net.ua/index.cgi?get_index=sharing_user_main";
    return 0;
  }

  # Save to file
  return _write_to_file($file_content, $destination);
}

#**********************************************************
=head2 get_abills_version()

=cut
#**********************************************************
sub get_abills_version {
  # Read from VERSION

  if (-f "$base_dir/VERSION") {
    $ABILLS_VERSION = `cat $base_dir/VERSION | awk -F' ' '{ print \$1 }'`;
    chomp $ABILLS_VERSION;
  }

  if ($DEBUG) {
    print "Current version : $ABILLS_VERSION \n";
  }

  return $ABILLS_VERSION;
}

#**********************************************************
=head2 check_used_perl_modules()

  Reads list of modules needed for normal using ABillS

=cut
#**********************************************************
sub check_used_perl_modules {

  my $cpanm = `which cpanm`;
  chomp($cpanm);

  if (!$cpanm) {
    print "cpanminus is not installed \n";
    `cpan App::cpanminus`;
  }

  if ($DEBUG > 2) {
    print "Checking for perl modules \n";
  }

  # Read file and form two-level array for $Module and Perl::Module
  my $cant_require_module = sub {
    my ($name) = shift;
    undef $@;
    $name =~ s/::/\//g;
    eval {require $name . '.pm'};
    $@;
  };

  my %perl_modules_for_Module = (
    'System'  => [
      'JSON',
      'Try::Tiny',
      'DBD::mysql',
      'DBI',
      'Digest::MD5',
      'Digest::SHA1',
      'Imager::QRCode',
      'Spreadsheet::WriteExcel',
      'XML::Simple',
      'Text::CSV'
    ],
    'Netlist' => [ 'Nmap::Parser' ]
  );

  foreach my $module ('System', keys %ENABLED_MODULES) {
    if (exists $perl_modules_for_Module{$module}) {

      foreach my $perl_mod (@{$perl_modules_for_Module{$module}}) {
        if ($DEBUG > 2) {
          print "  Checking for module $perl_mod \n";
        }

        if ($cant_require_module->($perl_mod)) {
          print "  Installing Perl module : $perl_mod \n";
          sleep 1;
          `cpanm $perl_mod`
        }
      }
    }

  }

  if ($DEBUG) {
    print "Finished checking perl modules \n";
  }

}

#**********************************************************
=head2 check_perl_version()

=cut
#**********************************************************
sub check_perl_version {
  my ($recommended_version) = shift;

  my $normalize = sub {
    my $literal = shift;
    my ($major, $minor, $subv) = $literal =~ /^(\d+)\.(\d{3})(\d*)/;

    $minor = int($minor || 0);
    $subv = int($subv || 0);

    "v$major.$minor.$subv";
  };

  if ($DEBUG) {
    print "Checking perl version. Current: $] Recommended: $recommended_version\n";
  }

  my $normalized_recommended = $normalize->($recommended_version);
  my $normalized_minimal = $normalize->($minimal_perl_version);
  my $normalized_current = $normalize->($]);

  if ($] lt $minimal_perl_version) {
    die "Your PERL version ($normalized_current) is lower then minimal $normalized_minimal. \n"
  }
  elsif ($] lt $recommended_version) {
    print "
  #################################################################
  #                    Outdated perl version                      #
  #################################################################
  
  Your PERL version ($normalized_current) is lower then recommended.
  Perl community works hard to make Perl faster and more stable.
  We as developers are using new stable features, so code needs higher versions of Perl
  Consider upgrading Perl at least to $normalized_recommended\n
  
  ";
  }

}

#**********************************************************
=head2 check_sql_version()

=cut
#**********************************************************
sub check_sql_version {
  print "Checking MySQL Server version \n" if ($DEBUG);

  # Get version
  my $version_str = `mysql --version | awk -F' ' '{ print \$5 }'`;
  chomp $version_str;

  my $split_and_compare = sub {
    my ($ver_1, $ver_2) = @_;

    my @vers1 = split('\.', $ver_1);
    my @vers2 = split('\.', $ver_2);

    my $lower_length = ($#vers1 < $#vers2) ? $#vers1 : $#vers2;

    my $res = 1;
    for (my $i = 0; $i <= $lower_length; $i++) {
      last if ($vers1[$i] >= $vers2[$i]);
      if ($vers1[$i] < $vers2[$i]) {
        $res = 0;
      }
    }

    $res;
  };

  my $sql_version = 0;
  if ($version_str && $version_str =~ /([0-9.]+)-?/) {
    $sql_version = $1;
  }

  print "  Current MySQL Server version : $sql_version \n" if ($DEBUG > 2);

  # Compare with recommended and show warning if less
  if ($split_and_compare->($recommended_sql_version, $sql_version)) {
    print "
  #################################################################
  #                    Outdated MySQL version                     #
  #################################################################
  
  Your MySQL version ($sql_version) is lower then recommended.
  Consider upgrading MySQL at least to $recommended_sql_version\n\n";
    return 0;
  }

  return 1;
}


#**********************************************************
=head2 check_ssh_access()

=cut
#**********************************************************
sub check_ssh_access {

  my @identities = ();

  # Check for SSH key present
  my $system_wide_identity_file_str =
    `cat '/etc/ssh/ssh_config' | grep -E '^\ +IdentityFile' | awk -F' ' '{ print \$2 }'`;

  my $user_idenity_file_str = '';
  if (-f '/root/.ssh/config') {
    $user_idenity_file_str =
      `cat '/root/.ssh/config' | grep -E '^\ +IdentityFile' | awk -F' ' '{ print \$2 }'`;
    print "User identities : \n" . $user_idenity_file_str if ($DEBUG);
  }

  push(@identities, split('\n', $user_idenity_file_str)) if ($user_idenity_file_str);
  push(@identities, split('\n', $system_wide_identity_file_str)) if ($system_wide_identity_file_str);

  # Check each identity for connection to git@abills.net.ua
  my $ssh = `which ssh`;
  chomp($ssh);
  my $has_access_with_identity = sub {
    my $key = shift;
    my $args = join(' ', $ssh, ($key ? "-i $key" : ""), '-o BatchMode=yes', '-q', $GIT_REPO_HOST, '> /dev/null 2>&1');
    print "Checking SSH access with : $args \n" if ($DEBUG);
    system($args) == 0;
  };

  # Find identity
  my $valid_identity = undef;

  foreach my $file (@identities) {
    if ($has_access_with_identity->($file)) {
      $valid_identity = $file;
      last;
    }
  }

  if (!$valid_identity) {
    print " ### Don't have access to repo \n\n";
    return 0;

    # TODO: Look for key and save it to /root/.ssh/config
    # TODO: Ask for credentials and save it to $PREFIX/.credentials

    #    Host abills.net.ua
    #      User git
    #      Hostname abills.net.ua
    #      IdentityFile ~/.ssh/id_dsa.anton

  }

  return 1;

}

#**********************************************************
=head2 _get_support_credentials()

=cut
#**********************************************************
sub _get_support_credentials {
  my $try_num = shift // 0;

  if ($try_num >= 5) {
    die "Can't authenticate\n";
  }

  my $username = $OPTIONS{USERNAME};
  my $password = $OPTIONS{PASSWORD};

  if (!$OPTIONS{USERNAME} || !$OPTIONS{PASSWORD}) {
    my $tries_left = sprintf("%d tries left", 5 - $try_num);
    say "Please enter your ABillS Support login and password for server registration ($tries_left)";
    $username = _read_input('USERNAME', 'Login');
    $password = _read_input('PASSWORD', 'Password');
  }

  my $access_check = web_request($SUPPORT_URL, {
      POST        => "user=$username&passwd=$password&index=10&json=1",
      COOKIE      => 1,
      INSECURE    => 1,
      JSON_RETURN => 1,
      DEBUG       => $DEBUG > 4
    });

  if (!$access_check || ($access_check->{errno} && $access_check->{errno} eq '2')) {

    if ($access_check->{errstr} && $access_check->{errstr} =~ /Timeout/i) {
      die " Cannot authenticate against $SUPPORT_URL.\n\n Error : \n" . ($access_check->{errstr} || '') . " \n";
    }
    else {
      say "Can't parse response but no 'Access deny' was received";
      my $user_confirmed_json_is_ok = _read_input(
        'USER_CONFIRMED_AUTH',
        "Do you want to proceed? (y/n)",
        undef,
        {
          CHECK => sub {$_[0] && $_[0] =~ /y|n/i}
        }
      );
      if ($user_confirmed_json_is_ok =~ /n/i) {
        die " No confirmation to skip broken JSON \n";
      }
    }
  }
  elsif ($access_check->{TYPE} && $access_check->{errstr}) {
    print " $access_check->{TYPE} : $access_check->{errstr} \n";
    # Try again
    delete $OPTIONS{USERNAME};
    delete $OPTIONS{PASSWORD};
    return _get_support_credentials(++$try_num);
  }

  return wantarray ? ($username, $password) : [ $username, $password ];
}


#**********************************************************
=head2 _read_input($name, $prompt, $default_value, $attr) - read input from user

  $name           - name for variable (unique through program)
  $prompt         - string to show user before he writes value
  $default_value  - default value (will be shown to user), pass undef to prevent empty value
  $attr           - hash_ref
    CHECK         - coderef to check value. if returns false, will ask again
    COMPLETE_LIST - list for autocomplete

=cut
#**********************************************************
sub _read_input {
  my ($name, $prompt, $default_value, $attr) = @_;

  return $OPTIONS{$name} if ($OPTIONS{$name});

  if (defined $default_value) {
    $prompt .= " [$default_value]";
  };

  $prompt .= " : ";
  $attr //= {};

  my @complete_arguments = $prompt;
  if ($attr->{COMPLETE_LIST} && ref $attr->{COMPLETE_LIST} eq 'ARRAY') {
    push @complete_arguments, @{ $attr->{COMPLETE_LIST} || [] };
  }

  ASK_VALUE:
  my $input = Term::Complete::Complete(@complete_arguments);

  # If empty value is not permitted, ask again
  if (!$input && !defined $default_value) {
    say ' Empty value is not allowed ';
    goto ASK_VALUE;
  }

  # If can check and check fails, ask again
  if (defined $attr->{CHECK} && !$attr->{CHECK}->($input)) {
    delete $OPTIONS{$name};
    goto ASK_VALUE;
  }

  # Save to main options hash, so we never ask same value again
  $OPTIONS{$name} = $input;

  return $input;
}

#**********************************************************
=head2 _read_file($path)

=cut
#**********************************************************
sub _read_file {
  my ($path) = @_;

  my $content = '';

  open(my $fh, '<', $path) or return 0;
  while (<$fh>) {
    $content .= $_;
  }

  return $content;
}

#**********************************************************
=head2 _write_to_file($file_content, $destination)

  Arguments:
     $file_content - what to write
     $destination  - where to write
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub _write_to_file {
  my ($file_content, $destination) = @_;

  open (my $fh, '>', $destination) or do {
    say " !!! Can't save file $destination : $!";
    return 0;
  };

  print $fh $file_content;
  close($fh);

  return 1;
}

#**********************************************************
=head2 _get_directory_size() returns size in Kb

=cut
#**********************************************************
sub _get_directory_size {
  my ($dir) = @_;

  my $size = `du -s -BK $dir | awk -F' ' '{print \$1}'`;
  chomp $size;

  if ($size && $size =~ /^(\d+)/) {
    $size = $1;
  }
  else {
    return 0;
  }

  return $size ? int($size) : 0;
}

#**********************************************************
=head2 _db_execute() execute sql file

  Arguments:
     $file - path to .sql file

  Returns:

=cut
#**********************************************************
sub _db_execute_from_file {
  my ($file) = @_;

  say " --------------------- ";
  say "|Update file $file.|";
  say " --------------------- ";
  my $update_content .= _read_file($TEMP_DIR . '/abills/db/update/' . $file);

  _db_statements_execute($update_content);

  return 1;
}

#**********************************************************
=head2 _db_statements_execute() query all sql

  Arguments:
     $sql_content - sql content from changelog or update files

  Returns:

=cut
#**********************************************************
sub _db_statements_execute {
  my ($sql_content) = @_;
  return 0 unless $sql_content;

  $sql_content =~ s/\n+//gm;

  my @commands_to_execute = split('\;', $sql_content);

  foreach my $command (@commands_to_execute) {
    $admin->query(qq{$command}, 'do');

    if ($admin->{errno}) {
      say "$admin->{errno}";
    }
  }

  return 1;
}

#**********************************************************
=head2 _download_and_parse_sql_updates() download sql update from wiki

  Arguments:
     $update_url  - changelog URL
     $update_date - date from $conf{version} OR from file VERSION

  Returns:

=cut
#**********************************************************
sub _download_and_parse_sql_updates {
  my ($update_url, $update_date) = @_;
  say "Download sql updates";

  my $update_sql_result = web_request($update_url, {
      CURL           => 1,
      REQUEST_PARAMS => {
      },
      DEBUG          => $DEBUG > 4
    }
  );

  # make array of all changelog dates
  my (@changelog_dates_array) = $update_sql_result =~ /(\d{2}\.\d{2}\.\d{4})/gm;

  foreach my $changelog_each_date (@changelog_dates_array) {
    $changelog_each_date =~ s/(\d{2})\.(\d{2})\.(\d{4})/$3$2$1/gm;

    # check if right date
    if ($changelog_each_date > $update_date) {
      say " --------------------- ";
      say "Update sql for date: $changelog_each_date";
      say " --------------------- ";

      my $start_accordion = "<accordion title=\"$changelog_each_date\"><panel title=\"MySQL\"><code mysql>";
      my $end_accordion = "<\/code><\/panel><\/accordion>";

      my ($sql_content) = $update_sql_result =~ /$start_accordion(.+?)$end_accordion/gsm;
      _db_statements_execute($sql_content);
    }
  }

  return 1;
}