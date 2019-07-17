package Abills::Backend::Defs;

use strict;
use warnings FATAL => 'all';

require Exporter;

use parent 'Exporter';
use Abills::Base qw/_bp parse_arguments in_array/;

our %conf;

our $libpath;

BEGIN {
  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../'; #assuming we are in /usr/abills/misc/
  if ($Bin =~ m/\/abills(\/)/) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift(@INC,
    "$libpath",
    "$libpath/Abills",
    "$libpath/lib",
    "$libpath/Abills/modules",
    "$libpath/Abills/mysql"
  );
}

die "No \$libpath \n" if (!$libpath);

require "$libpath/libexec/config.pl";

use Admins;
require Abills::SQL;
use Abills::Backend::PubSub;

our Admins $admin;
our Abills::SQL $db;
our Abills::Backend::PubSub $Pub;

our (
  $base_dir,
  @MODULES, $ARGS,
  $debug
);

our @EXPORT = qw(
  $base_dir
  %conf $db $admin
  @MODULES $ARGS
  $debug $Log $Pub
  register_global
  get_global
);

# Export everything
our @EXPORT_OK = @EXPORT;

$ARGS = parse_arguments(\@ARGV);
$debug //= $ARGS->{DEBUG} || $ARGS->{debug} || 3;

$db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
  CHARSET => $conf{dbcharset},
  # SCOPE   => __FILE__ . __LINE__
});

$admin = Admins->new($db, \%conf);

$base_dir //= '/usr/abills';

use Abills::Backend::Log;
our Abills::Backend::Log $Log;
$Log = Abills::Backend::Log->new('FILE', $debug, 'WebSocket', {
  FILE => $ARGS->{LOG_FILE} || ($base_dir . '/var/log/websocket.log')
});

$Pub = Abills::Backend::PubSub->new();
$Pub->debug(1);

my %GLOBALS = ();

#**********************************************************
=head2 register_global()

=cut
#**********************************************************
sub register_global {
  my ($key, $object) = @_;

  if (exists $GLOBALS{$key}) {
    warn "Registered global twice. $key. "
      . join(',', caller) . " \n";
    return 0;
  }

  $GLOBALS{$key} = $object;
}

#**********************************************************
=head2 get_global()

=cut
#**********************************************************
sub get_global {
  my ($key) = @_;

  if (!exists $GLOBALS{$key}) {
    warn "Unregistered global requested '$key'  at " . join(', ', caller) . " \n";
    return 0;
  }

  return $GLOBALS{$key};
}

1;