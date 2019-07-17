# billd plugin
#
# DESCRIBE:
#
#**********************************************************

our ($debug, $NAS, %conf, $Admin, $db, $OS);

my $Notepad = Notepad->new($db, $Admin, \%conf);

check_reminders();


#**********************************************************
#
#
#**********************************************************
sub check_reminders {

#  my $active_reminders_list = $Notepad->active_periodic_reminders_list( { DEBUG => $debug} );

  exit;
}


1
