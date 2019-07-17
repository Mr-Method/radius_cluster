# billd plugin
#
# DESCRIBE:
#
#**********************************************************

use Abills::Base qw/cmd in_array convert startup_files _bp int2ip/;
use Abills::Misc qw/form_purchase_module cross_modules_call _function get_function_index/;
use JSON;

use utf8;
use Log qw/log_print/;
use POSIX qw/strftime/;

our ($db, $debug, $Admin, %permissions, $argv, %conf, $OS, $DATE, $TIME, @MODULES, %lang, $base_dir, $SELF_URL);
exit if (!$conf{PUSH_ENABLED});
$conf{CROSS_MODULES_DEBUG} = '/tmp/cross_modules';

$SELF_URL //= $conf{BILLING_URL} || '';

use Abills::Sender::Core;
my $Sender = Abills::Sender::Core->new($db, $Admin, \%conf, {
    SENDER_TYPE => 'Push'
  });

my $json = JSON->new->utf8(1);
my $DEBUG = ($argv && $argv->{DEBUG}) ? $argv->{DEBUG} : 0;

$DATE //= POSIX::strftime("%Y-%m-%d", localtime());
my (undef, $month, $day) = split('-', $DATE);

_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

my $events = collect_events();
foreach my $aid ( keys %{$events} ) {
  send_events($aid, $events->{$aid}) if ( scalar (@{$events->{$aid}}) );
}

#check_reminders();

#**********************************************************
=head2 collect_events()

=cut
#**********************************************************
sub collect_events {
  my %events_for_admin = ();
  my $admins_list = $Admin->list({
    ADMIN_NAME => '_SHOW',
    BIRTHDAY   => '_SHOW',
    DISABLE    => 0,
    COLS_NAME  => 1,
  });
  _error_show($Admin);
  
  my @all_aids = map { $_->{aid} } @{$admins_list};
  
  # Initialize array for each admin
  $events_for_admin{$_} = [ ] foreach (@all_aids);
  
  foreach my $adm ( @{$admins_list} ) {
    my $aid = $adm->{aid};
    my $this_adm_events = collect_admin_events($aid);
    
    if ( $adm->{birthday} ) {
      
      my ($adm_year, $adm_month, $adm_day) = split('-', $adm->{birthday});
      if ( $adm_month && $adm_day && ($month == $adm_month && ($adm_day - $day > 0 && $adm_day - $day <= 1)) ) {
        my $birthday_event = _generate_birthday_reminder($adm->{admin_name} || $adm->{login} || $admin->{name});
        foreach my $other_aid ( grep { $_ != $aid } @all_aids ) {
          push(@{$events_for_admin{$other_aid}}, $birthday_event);
        }
        
        if ( $adm_day - $day == 0 ) {
          push(@{$events_for_admin{$aid}}, {
              TITLE => 'Happy birthday!',
              TEXT  => $conf{NOTEPAD_BIRTHDAY_GREETINGS_TEXT} || $birthday_event->{TEXT}
            });
        }
      }
    }
    
    _bp($aid, $this_adm_events) if ($DEBUG > 1);
    
    push (@{ $events_for_admin{$aid} }, @{ $this_adm_events });
  }
  
  return \%events_for_admin;
}

#**********************************************************
=head2 collect_admin_events($aid)

=cut
#**********************************************************
sub collect_admin_events {
  my ($aid) = @_;
  
  local $admin = Admins->new($db, \%conf);
  $admin->info($aid);
  
  my $language = get_administrator_language($admin);
  
  my $cross_modules_return = cross_modules_call('_events', {
      UID    => $user->{UID},
      PERIOD => 300,
      SILENT => $DEBUG > 0,
      DEBUG  => $DEBUG
    });
  
  my %admin_modules = ('Events' => 1, 'Notepad' => 1);
  my $admin_groups_ids = $admin->{SETTINGS}->{GROUP_ID} || '';
  
  if ( in_array('Events', \@MODULES) ) {
    
    if ( $admin_groups_ids ) {
      
      # Changing 'AND' to 'OR'
      $admin_groups_ids =~ s/, /;/g;
      my $groups_list = $Events->group_list( {
        ID         => $admin_groups_ids,
        MODULES    => '_SHOW',
        COLS_UPPER => 0
      });
      
      if ( !_error_show($Events) ) {
        foreach my $group ( @{$groups_list} ) {
          my $group_modules_string = $group->{modules} || '';
          my @group_modules = split(',', $group_modules_string);
          map { $admin_modules{$_} = 1 } @group_modules;
        }
      }
    }
  }
  
  my @events = ();
  foreach my $module ( sort keys %{$cross_modules_return} ) {
    next if ($admin_groups_ids && !$admin_modules{$module});
    
    my $result = $cross_modules_return->{$module};
    if ( $result && $result ne '' ) {
      # Transform event json text to perl hashref
      eval {
        my $decoded_result = $json->decode('[' . $result . ']');
        
        if ( $decoded_result && ref $decoded_result eq 'ARRAY' ) {
          push (@events, @{$decoded_result});
        }
      }
    }
  }
  
  return \@events;
}

#**********************************************************
=head2 send_events()

=cut
#**********************************************************
sub send_events {
  my ($aid, $adm_events) = @_;
  return if (!$aid);
  
  foreach my $reminder ( @{$adm_events} ) {
    $Sender->send_message({
      AID     => $aid,
      MESSAGE => $reminder->{TEXT},
      TITLE   => $reminder->{TITLE}
    });
  }
}

#**********************************************************
=head2 _generate_birthday_reminder()

=cut
#**********************************************************
sub _generate_birthday_reminder {
  my ($for_name) = @_;
  
  return {
    TITLE => 'Birthday',
    TEXT  => $for_name || 'Guess who :)'
  }
  
}


#**********************************************************
=head2 get_administrator_language()

=cut
#**********************************************************
sub get_administrator_language {
  my ($admin) = @_;
  $admin->settings_info($admin->{aid});
  
  if ( $admin->{WEB_OPTIONS} ) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS});
    foreach my $line ( @WO_ARR ) {
      my ($k, $v) = split(/=/, $line);
      next if (!$k);
      $admin->{SETTINGS}->{$k} = $v;
      
      if ( $html ) {
        $html->{$k} = $v;
      }
    }
  }
  
  my $language = $admin->{SETTINGS}->{language} || $conf{default_language} || 'russian';
  
  if ( !$html->{language} || $html->{language} ne $language ) {
    %lang = ();
    
    # Load main language
    my $main_english = $base_dir . '/language/english.pl';
    require $main_english;
    
    if ( $language ne 'english' ) {
      my $main_file = $base_dir . '/language/' . $language . '.pl';
      require $main_file;
    }
    
    # Load modules lang files
    foreach my $module ( @MODULES ) {
      my $english_lang = $base_dir . "/Abills/modules/$module/lng_english.pl";
      require $english_lang if ( -f $english_lang);
      
      if ( $language ne 'english' ) {
        my $lang_file = $base_dir . "/Abills/modules/$module/lng_$language.pl";
        require $lang_file if ( -f $lang_file );
      }
      
    }
  }
  
  return $language;
}

##**********************************************************
#=head2 check_reminders()
#
#=cut
##**********************************************************
#sub check_reminders {
#
#  my $periodic_reminders_list = $Notepad->show_reminders_list({ COLS_UPPER => 0 });
#  my $notes_list = $Notepad->notes_list( {
#    PAGE_ROWS        => 3,
#    STATUS           => 0,
#    DATE             => "<$DATE $TIME;>0000-00-00",
#    COLS_NAME        => 1,
#    COLS_UPPER       => 0,
#    SHOW_ALL_COLUMNS => 1,
#    AID              => '_SHOW',
#  } );
#
#  foreach my $reminder ( @{$periodic_reminders_list}, @{ $notes_list } ) {
#    next if (!$reminder->{aid});
#
#    $Sender->send_message({
#      AID     => $reminder->{aid},
#      MESSAGE => $reminder->{text},
#      TITLE   => $reminder->{subject}
#    });
#  }
#
#  return 1;
#}


1
