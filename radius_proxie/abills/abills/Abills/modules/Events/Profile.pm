#package Events::Profile;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Events::Profile - functions for per-admin events configuration

=head2 SYNOPSIS

  This package aggregates functions for Profile(9) menu index

=cut

use Abills::Experimental;
use Abills::Base qw/_bp in_array/;

our (
  %lang,
  $html,
  $Events,
  $admin, $db, %conf
);

use Events::UniversalPageLogic;

our @PRIORITY_SEND_TYPES = qw/
  Mail
  Browser
  SMS
  Telegram
  Push
  XMPP
  /;

our @DEFAULT_SEND_TYPES = qw/
  Mail
  Telegram
  /;


#**********************************************************
=head2 events_profile_configure()

=cut
#**********************************************************
sub events_profile_configure {
  
  require Abills::Sender::Core;
  Abills::Sender::Core->import();
  my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);
  
  my @all_sender_plugins = sort keys %Abills::Sender::Core::TYPE_ID_FOR_PLUGIN_NAME;
  
  # Get all methods Sender can use
  my @available_methods = $Sender->available_types();
  my $priorities = $Events->priority_list({ NAME => '_SHOW' });
  _error_show($Events) and return 0;
  
  $FORM{AID} ||= $admin->{AID};
  
  my $aid_send_types = $Events->priority_send_types_list({
    AID        => $admin->{AID},
    SEND_TYPES => '_SHOW'
  });
  _error_show($Events) and return 0;
  my $aid_send_types_by_priority = sort_array_to_hash($aid_send_types, 'priority_id');
  
  if ( $FORM{submit} ) {
    
    foreach my $priority ( @{$priorities} ) {
      next if ( !exists $FORM{'SEND_TYPES_' . $priority->{id}} );
      
      my $new_value = $FORM{'SEND_TYPES_' . $priority->{id}} || '';
      my $current_row = $aid_send_types_by_priority->{$priority->{id}};
      
      if ( !$current_row->{send_types} || $new_value ne $current_row->{send_types} ) {
        my %new_row = (
          AID         => $FORM{AID},
          SEND_TYPES  => $new_value,
          PRIORITY_ID => $priority->{id}
        );
        
        $Events->priority_send_types_add(\%new_row, { REPLACE => 1 });
      }
    }
    
  }
  
  # Configure this admins events send types for each priority
  my $html_tabs = '';
  foreach my $priority ( @{$priorities} ) {
    # Get priority send_types
    my @this_send_types = ();
    # This part allows to separate empty value and when user disabled all methods for type
    if ( defined $aid_send_types_by_priority->{$priority->{id}} ) {
      @this_send_types = split(',\s?', $aid_send_types_by_priority->{$priority->{id}}{send_types} || '');
    }
    else {
      @this_send_types = grep {in_array($_, \@available_methods)} @DEFAULT_SEND_TYPES;
    }
    my %admin_enabled_types = map { $_ => 1 } @this_send_types;
    
    # Form checkboxes
    my $checkboxes_html = '';
    foreach my $send_type ( @all_sender_plugins ) {
  
      my $type_available = in_array($send_type, \@available_methods);
      my $always_on = $priority->{id} == 5;
  
      my $checkbox = $html->form_input('SEND_TYPES_' . $priority->{id}, $send_type, {
          TYPE      => 'checkbox',
          STATE     => ($type_available && $always_on) ? 1 : $admin_enabled_types{$send_type},
          EX_PARAMS => (
              !$type_available
                ? qq{ disabled='disabled' title='$lang{UNAVAILABLE}' }
                : ($always_on)
                  ? q{ readonly='readonly' onclick='return false;' }
                  : ''
          )
        }
      );
  
      my $label = $html->element('label', $checkbox . $send_type);
      my $checkbox_group = $html->element('div', $label, { class => 'checkbox col-md-6 text-left' });
  
      $checkboxes_html .= $checkbox_group;
    }
  
    # Form HTML for pill
    $html_tabs .= $html->tpl_show(_include('events_priority_send_types_tab', 'Events'),
      {
        PRIORITY_ID => $priority->{id},
        ACTIVE      => ($priority->{id} == 3 ? 'active' : ''),
        CHECKBOXES  => $checkboxes_html
      },
      { OUTPUT2RETURN => 1 }
    );
    
  }
  my @priority_tabs_lis = map {
    my $active = ($_->{id} == 3) ? q{class='active'} : ''; # Open NORMAL tab first
    $_->{name} =~ s/^_//g;
    $_->{name} =~ s/_$//g;
    "<li $active><a href='#priority_$_->{id}_tab' data-toggle='pill'>" . _translate('$lang' . uc($_->{name}) ) . "</a></li>"
  } @{$priorities};
  
  # Form tabs menu
  my $priority_tabs_menu = join('', @priority_tabs_lis);
  
  $html->tpl_show(_include('events_priority_send_types', 'Events'),
    {
      TABS_MENU => $priority_tabs_menu,
      TABS      => $html_tabs
    }
  );
  
  return 1;
}

#**********************************************************
=head2 events_profile()

=cut
#**********************************************************
sub events_profile {
  
  if ($FORM{seen}){
    if ($FORM{IDS}){
      $Events->events_change({ID => $_, STATE_ID => 2 }) foreach (split(',\s?', $FORM{IDS}));
    }
    else {
      $Events->events_change({ID => $FORM{ID}, STATE_ID => 2 });
    }
    show_result($Events, "$lang{CHANGED}");
  }
  else {
    events_uni_page_logic(
      'events', # Table name
      {
        # Template variables
        SELECTS    => {
          PRIVACY_SELECT  => { func => '_events_privacy_select', argument => 'PRIVACY_ID' },
          PRIORITY_SELECT => { func => '_events_priority_select', argument => 'PRIORITY_ID' },
          GROUP_SELECT    => { func => '_events_group_select', argument => 'GROUP_ID' },
          STATE_SELECT    => { func => '_events_state_select', argument => 'STATE_ID' },
        },
        
        # Result former variables
        HAS_VIEW   => 1,
        HAS_SEARCH => 1
      }
    );
  }
  return 1 if ( $FORM{MESSAGE_ONLY} );
  
  # Search form
  if ($FORM{search} && !$FORM{search_form} && $FORM{STATE_ID}){
    $LIST_PARAMS{STATE_ID} = $FORM{STATE_ID};
  }
  
  $LIST_PARAMS{PAGE_ROWS} = 10000;
  $LIST_PARAMS{AID} = $admin->{AID};
  
  my ($table) = events_uni_result_former({
    LIST_FUNC       => "events_list",
    DEFAULT_FIELDS  => "ID,TITLE,COMMENTS,PRIORITY_NAME,STATE_NAME,GROUP_NAME",
    HIDDEN_FIELDS   => "PRIORITY_ID,STATE_ID,GROUP_ID,COMMENTS,EXTRA,CREATED,MODULE,AID",
    MULTISELECT_ACTIONS => [
      {
        TITLE    => $lang{DEL},
        ICON     => 'glyphicon glyphicon-trash',
        ACTION   => "$SELF_URL?index=$index&del=1",
        PARAM    => "IDS",
        CLASS    => 'btn-danger',
        COMMENTS => "$lang{DEL}?"
      },
      {
        TITLE  => $lang{SEEN},
        ICON   => 'glyphicon glyphicon-ok',
        ACTION => "$SELF_URL?index=$index&seen=1",
        PARAM  => "IDS"
      }
    ],
    EXT_TITLES      => {
      id            => "#",
      comments      => $lang{COMMENTS},
      module        => $lang{MODULE},
      created       => $lang{CREATED},
      state_name    => $lang{STATE},
      privacy_name  => $lang{ACCESS},
      priority_name => $lang{PRIORITY},
      group_name    => $lang{GROUP},
      title         => $lang{NAME}
    },
    FILTER_COLS     => {
      comments => 0,
      title    => 0,
    },
    FILTER_VALUES   => {
      comments      => \&translate_simple,
      title         => \&translate_simple,
      priority_name => \&translate_simple
    },
    READABLE_NAME   => "$lang{EVENTS}",
    TABLE_NAME      => "EVENTS_TABLE",
    HAS_SEARCH      => 1,
    OUTPUT2RETURN   => 1,
  });
  
  
  my $state_list = $Events->state_list({
    NAME => '_SHOW',
  });
  _error_show($Events) and return 0;
  # Adding all option
  unshift(@$state_list, { id => 0, name => $lang{ALL} });
  
  my $filters_html = join('', map {
      my $button = $html->button(translate_simple($_->{name}), "index=$index&search=1&STATE_ID=$_->{id}");
      $html->element('li', $button, {
          class         => (defined $FORM{STATE_ID} && $FORM{STATE_ID} eq $_->{id} ? 'active' : ''),
          OUTPUT2RETURN => 1,
        });
    } @$state_list
  );

  $html->tpl_show(_include('events_events_profile', 'Events'),
    {
      TABLE   => $table,
      FILTERS => $filters_html,
      CREATE_BTN => $html->button($lang{CREATE}, "index=$index&show_add_form=1",{
          class => 'btn btn-sm btn-primary btn-block margin-bottom'
        })
    }
  );
  
  return 1;
}

#**********************************************************
=head2 events_unsubscribe()

=cut
#**********************************************************
sub events_unsubscribe {
  return if ( !$FORM{GROUP_ID} );
  
  $Events->admin_group_del(undef, { AID => $admin->{AID}, GROUP_ID => $FORM{GROUP_ID} });
  show_result($Events, $lang{DEL});
  
  return 1;
}

#**********************************************************
=head2 events_seen_message()

=cut
#**********************************************************
sub events_seen_message {
  return if ( !$FORM{ID} );
  
  $Events->events_change({ ID => $FORM{ID}, STATE_ID => 2 });
  show_result($Events, $lang{CHANGED});
  
  return 1;
}


1;