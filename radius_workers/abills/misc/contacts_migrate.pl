#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my $libpath;
our ($Bin, %conf, $base_dir, @MODULES, %lang, %FORM);
BEGIN {
  use FindBin '$Bin';
  
  # Assuming we are in '/usr/abills/misc/'
  $libpath = $Bin . '/../';
}

use lib $libpath;
use lib $libpath . 'lib';
use lib $libpath . 'Abills/mysql';
use lib $libpath . 'Abills';

require 'libexec/config.pl';
$base_dir //= $libpath;

use Abills::Defs;

use Abills::Base qw/_bp parse_arguments in_array/;
use Abills::Misc;

use Abills::SQL;
use Admins;

my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} });
my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );

my %ARGS = %{ parse_arguments(\@ARGV) };
my $debug = 0;
if ( $ARGS{DEBUG} ) {
  $debug = $ARGS{DEBUG};
  _bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });
}

require 'language/english.pl';

main();
exit 0;

#**********************************************************
=head2 main()

=cut
#**********************************************************
sub main {
  require Users;
  Users->import();
  
  my $Users = Users->new($db, $admin, \%conf);
  
  # First should save old contacts
  if (!$ARGS{SKIP_BACKUP}) {
    return unless save_old_contacts();
  }
  
  my $migrate_contacts = $Users->contacts_migrate({ IGNORE_DUPLICATE => $ARGS{IGNORE_DUPLICATE} }) && !$Users->{errno};
  
  if ($migrate_contacts){
    print "Contacts migrated successfully \n";
    print "You should now enable \$conf{CONTACTS_NEW} \n";
  }
  else {
    print "\nSomething was wrong during migrate, so we've to rollback operation \n";
    print "No need to worry, operation was canceled, your contacts are in the same state as before migrate \n";
    print "Maybe you have duplicates (same phone/email for different users). You can use IGNORE_DUPLICATE=1 option. \n";
  }
  
  return 1;
}

#**********************************************************
=head2 save_old_contacts()

  Arguments:
     -
    
  Returns:
  
=cut
#**********************************************************
sub save_old_contacts {
  
  use Control::System qw/ form_sql_backup /;
  my $backup_result = form_sql_backup({
    mk_backup => 1,
    TABLES    => 'users_pi',
    EXTERNAL  => 1
  });
  
  if ( $backup_result && ref $backup_result ){
    print "\n$backup_result->{result}\n\n";
  }
  else {
    return 0;
  }
  
  return 1;
}



