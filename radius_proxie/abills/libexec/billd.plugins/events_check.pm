use strict;
use warnings FATAL => 'all';

use vars qw(
  %conf
  $DATE
);

BEGIN{
  use FindBin '$Bin';
  my $libpath = "$Bin/../"; # Assuming we are in /usr/abills/libexec/
  unshift ( @INC, $libpath );
}

use Abills::Base qw (_bp in_array days_in_month);
require Abills::Misc;

require "libexec/config.pl";

my $backup_dir = $conf{BACKUP_DIR} || "/usr/abills/backup/";
$backup_dir =~ s/\/\//\//g;
main();

#**********************************************************
=head2 main() - entry point

=cut
#**********************************************************
sub main{
  check_backups();
  return 1;
}


sub check_backups{
  # FIXME: using special (not Abills::Misc version)
  my $backup_files = _get_files_in( $backup_dir, {FILTER => '\.gz'});

  # Check if yesterday backup exists
  my $yesterday_date = date_dec( 1, $DATE );


  unless ( in_array( "stats-$yesterday_date.sql.gz", $backup_files ) ){
    generate_new_event( "SYSTEM", "Yesterday backup does not exists!" );
  };

  foreach my $backup_file_name ( @{$backup_files} ){
    unless ( check_backup( $backup_file_name ) ){
      generate_new_event( 'SYSTEM', 'Backup check fails for ' . $backup_file_name );
    };
  }

  return 1;
}

#**********************************************************
=head2 check_backup($filename) - checks backup is correct

  Arguments:
    $filename - path to backup to check

  Returns:
    boolean

=cut
#**********************************************************
sub check_backup{
  my ($filename) = @_;

  my $stats = _stats_for_file($backup_dir . '/' . $filename);

  # 20 is minimum Gzip packed file size;
  return 0 if (!$stats->{size} || $stats->{size} <= 20);

  return 1;
}

#**********************************************************
=head2 generate_new_event($name, $message)

  Arguments:
    $name - name for event
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub generate_new_event{
  my ($name, $comments) = @_;

  #  print "EVENT: $name, $comments \n";
  print $comments . "\n";
  my $add_result = `/usr/abills/misc/events.pl ADD=events MODULE="$name" COMMENTS="$comments" STATE_ID=1 OUTPUT=JSON`;

  if ( $add_result !~ /"status":0/m ){
    print "Error adding";
    print $add_result
  }

  return 1;
}

#**********************************************************
=head2 date_dec($num_of_days, $date_string) - decrement date

  Arguments:
    $num_of_days - days to decrement
    $date_string - date in "YYYY-MM-DD" format

  Returns:
    string in "YYYY-MM-DD" format

=cut
#**********************************************************
sub date_dec{
  my ($num_of_days, $date_string) = @_;

  return 0 if ($num_of_days < 0);
  my ($year, $month, $day) = split( "-", $date_string );

  while($num_of_days--){
    $day--;
    if ( $day == 0 ){
      $month--;
      if ( $month == 0 ){
        $year--;
        $month = 12;
      }
      $day = days_in_month( {DATE => "$year-$month-01"} );
    }
  }
  return "$year" . "-" . (length $month < 2 ? '0' : '' ) . $month . "-" . (length $day < 2 ? '0' : '' ) . $day ;
}



1;