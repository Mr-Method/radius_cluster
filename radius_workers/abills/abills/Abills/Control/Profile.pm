
=head1 NAME

  Admin Profile

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array);
our ($html,
  $admin,
  $db,
  %lang,
  %LANG,
  %permissions,
  %module);

#**********************************************************
=head2 admin_profile() - Admin profile configuration

=cut
#**********************************************************
sub admin_profile {

  admin_info_change();

  require Control::Quick_reports;
  my $quick_reports = form_quick_reports();

  if (! $quick_reports) {
    return 1;
  }

  #our $REFRESH = $admin->{SETTINGS}{REFRESH} || 60;

  my $SEL_LANGUAGE = $html->form_select(
    'language',
    {
      SELECTED => $html->{language},
      SEL_HASH => \%LANG
    }
  );

  # Events groups
  my $events_groups_select = '';
  my $events_groups_show = 'hidden';
  if (in_array('Events', \@MODULES)){
    require Events;
    Events->import();
    
    my $Events = Events->new($db, $admin, \%conf);
    my $this_admin_groups = $Events->groups_for_admin($admin->{AID}) || '';
    _error_show($Events);
    
    my $group_link = '';
    if (my $group_index = get_function_index('events_group')){
      $group_link = "?index=$group_index";
    };
    
    $events_groups_select = _events_group_select({
        SELECTED  => $this_admin_groups || '',
        MULTIPLE => 1,
        MAIN_MENU => $group_link,
      });
    $events_groups_show = '';
  }
  
  my $subscribe_mng_block = profile_get_admin_sender_subscribe_block($admin->{AID}, 6);
  
  $html->tpl_show(templates('form_admin_profile'), {
      QUICK_REPORTS        => $quick_reports,
      SEL_LANGUAGE         => $SEL_LANGUAGE,
      NO_EVENT             => $admin->{SETTINGS}->{NO_EVENT},
      NO_EVENT_SOUND       => $admin->{SETTINGS}->{NO_EVENT_SOUND},
      CONF_PUSH_ENABLED    => $conf{PUSH_ENABLED},
      PUSH_ENABLED         => $admin->{SETTINGS}->{PUSH_ENABLED},
    
      SUBSCRIBE_BLOCK => $subscribe_mng_block,
      
      EVENT_GROUPS_SELECT  => $events_groups_select,
      EVENTS_GROUPS_HIDDEN => $events_groups_show,
    });

  form_profile_search();

  return 1;
}

#**********************************************************
=head2 form_profile_search($attr) -
=cut
#**********************************************************
sub form_profile_search {
  my ($attr) = @_;

  if ($FORM{change_search}) {
    my $search_fields = $FORM{SEARCH_FIELDS} || q{};
    $admin->{SETTINGS}{SEARCH_FIELDS} = $search_fields;
    my $web_option = '';
    while(my($k, $v) = each %{ $admin->{SETTINGS} } ) {
      $web_option .= "$k=$v;" if (defined($v));
    }

    $admin->change({ AID => $admin->{AID}, WEB_OPTIONS => $web_option });
    $html->message('info', $lang{INFO}, "$lang{CHANGED} $search_fields");
    $admin->{SETTINGS}{SEARCH_FIELDS} = $search_fields;
  }

  our @default_search;
  if ($admin->{SETTINGS} && $admin->{SETTINGS}{SEARCH_FIELDS} ) {
    @default_search = split(/,\s+/, $admin->{SETTINGS}{SEARCH_FIELDS});
  }

  my %search_fields = (
    UID         => 'UID',
    BILL_ID     => $lang{BILL},
    LOGIN       => $lang{LOGIN},
    FIO         => $lang{FIO},
    CONTRACT_ID => $lang{CONTRACT},
    EMAIL       => 'E-mail',
    PHONE       => $lang{PHONE},
    COMMENTS    => $lang{COMMENTS},
    ADDRESS_FULL=> $lang{ADDRESS},
    ADDRESS_STREET2 => $lang{SECOND_NAME}
  );

  #Get info fields
  my $prefix = $attr->{COMPANY} ? 'ifc*' : 'ifu*';
  my $list = $Conf->config_list({ PARAM => $prefix,
      SORT  => 2
    });

  my $field_id = '';
  foreach my $line (@$list) {
    if ($line->[0] =~ /$prefix(\S+)/) {
      $field_id = $1;
    }

    my (undef, undef, $name, undef) = split(/:/, $line->[1]);
    my $field_name = uc($field_id);
    $search_fields{$field_name}=_translate($name);
  }

  my $table = $html->table(
    {
      width      => '400',
      caption    => "$lang{SEARCH} $lang{FIELDS}",
      cols_align => [ 'left', 'right', ],
      ID         => 'SEARCH_FIELDS'
    }
  );

  foreach my $key (sort keys %search_fields) {
    $table->addrow( $html->form_input('SEARCH_FIELDS', $key, { TYPE => 'checkbox', STATE => (in_array($key, \@default_search)) ? 'ckecked' : undef }),
      $search_fields{$key}
    );
  }

  print $html->form_main(
      {
        CONTENT=> $table->show(),
        HIDDEN => {
          index   => $index,
        },
        SUBMIT => { change_search => "$lang{CHANGE}" },
        ID     => 'FORM_SEARCH_FIELDS'
      }
    );

  return 1;
}

#**********************************************************
=head2 flist() - Functions list

=cut
#**********************************************************
sub flist {

  my %new_hash = ();
  while ((my ($findex, $hash) = each(%menu_items))) {
    while (my ($parent, $val) = each %$hash) {
      $new_hash{$parent}{$findex} = $val;
    }
  }

  my $h          = $new_hash{0};
  my @last_array = ();

  my @menu_sorted = sort { $b <=> $a } keys %$h;
  my %qm = ();
  if ($admin->{SETTINGS} && $admin->{SETTINGS}->{qm}) {
    my @a = split(/,/, $admin->{SETTINGS}->{qm});
    foreach my $line (@a) {
      my ($id, $custom_name) = split(/:/, $line, 2);
      $qm{$id} = ($custom_name) ? $custom_name : '';
    }
  }

  my $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'left', 'right', 'right', 'left', 'left', 'right' ],
      ID         => 'PROFILE_FUNCTION_LIST'
    }
  );

  my $mi;

  for (my $parent = 0 ; $parent <= $#menu_sorted ; $parent++) {
    my $val    = $h->{$parent};
    my $level  = 0;
    my $prefix = '';
    $table->{rowcolor} = 'active';

    next if (!defined($permissions{ ($parent - 1) }));
    $table->addrow("$level:", "$parent >> " . $html->button($html->b($val), "index=$parent") . "<<", '') if ($parent != 0);

    if (defined($new_hash{$parent})) {
      $table->{rowcolor} = undef;
      $level++;
      $prefix .= "&nbsp;&nbsp;&nbsp;";
      label:
      my $k;
      while (($k, $val) = each %{ $new_hash{$parent} }) {
      #foreach $k ( keys %{ $new_hash{$parent} } ) {
        $val = $new_hash{$parent}{$k};
        my $checked = undef;
        if (defined($qm{$functions{ $k }})) {
          $checked = 1;
          $val     = $html->b($val);
        }

        $table->addrow(
          "$k "
            . $html->form_input(
            'qm_item',
            $functions{ $k }, # $k,
            {
              TYPE          => 'checkbox',
              OUTPUT2RETURN => 1,
              STATE         => $checked
            }
          ),
          $prefix .' '. $html->button($val, "index=$k") . (($module{$k}) ? ' ('. $module{$k} .') '. $functions{ $k }  : ''),
          $html->form_input("qm_name_$k", $qm{$k}, { OUTPUT2RETURN => 1 })
        );

        if (defined($new_hash{$k})) {
          $mi = $new_hash{$k};
          $level++;
          $prefix .= "&nbsp;&nbsp;&nbsp;";
          push @last_array, $parent;
          $parent = $k;
        }
        delete($new_hash{$parent}{$k});
      }

      if ($#last_array > -1) {
        $parent = pop @last_array;
        $level--;

        $prefix = substr($prefix, 0, $level * 6 * 3);
        goto label;
      }
      delete($new_hash{0}{$parent});
    }
  }

  print $html->form_main(
      {
        CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
        HIDDEN  => {
          index        => $index,
          AWEB_OPTIONS => 1,
        },
        SUBMIT => {
              quick_set => $lang{SET} }
      }
    );

  return 1;
}

#**********************************************************
=head2 form_slides_create() - Create slides

=cut
#**********************************************************
sub form_slides_create {

  require Control::Users_slides;

  my ($base_slides, $active_slides) = form_slides_info();

  my $content = '';

  for(my $slide_num=0;  $slide_num <=  $#{ $base_slides }; $slide_num++  ) {
    my $slide_name   = $base_slides->[$slide_num]->{ID};
    my $table = $html->table({
        caption => "$slide_name - $base_slides->[$slide_num]{HEADER}",
        ID      => $slide_name,
        width   => '300',
      }
    );

    my $slide_fields = $base_slides->[$slide_num]{FIELDS};
    my $slide_size = $html->form_select('s_'.$slide_name,
      {
        SELECTED    => 1, #($active_slides->{$slide_name} && $active_slides->{$slide_name}{'SIZE'}) ? $active_slides->{$slide_name}{'SIZE'} : 1,
        SEL_HASH    => { 1 => 1,
          2 => 2,
          3 => 3,
          4 => 4
        },
        NO_ID       => 1
      });

    if ( scalar keys %{ $active_slides } == 0 || ( $slide_name && $active_slides->{$slide_name})) {
      $table->{rowcolor}='info';
    }

    $table->addrow('',
      $html->form_input('ENABLED', $slide_name, { TYPE => 'checkbox', STATE => (scalar keys %$active_slides == 0 || $active_slides->{$slide_name}) ? 'checked' : ''}  ). ' '. $lang{ENABLE},
      $lang{PRIORITY} .':'. $html->form_input('p_'.$slide_name,  ($active_slides->{$slide_name}) ? $active_slides->{$slide_name}{'PRIORITY'} : '' ),
      $lang{SIZE} .':'. $slide_size
    );

    delete($table->{rowcolor});

    foreach my $field_name ( keys %{ $slide_fields } ) {
      $table->addrow(
        $html->form_input($slide_name.'_'. $field_name, '1', { TYPE => 'checkbox', STATE => ( ( $active_slides->{$slide_name} && $active_slides->{$slide_name}{$field_name} )  ) ? 'checked' : '' }),
        $slide_fields->{$field_name},
        $html->form_input('w_'.$slide_name.'_'. $field_name, ($active_slides->{$slide_name}) ? $active_slides->{$slide_name}{'w_'.$field_name} : '' , { EX_PARAMS => "placeholder='$lang{WARNING}'"  }),
        $html->form_input('c_'.$slide_name.'_'. $field_name, ($active_slides->{$slide_name}) ? $active_slides->{$slide_name}{'c_'.$field_name} : '' , { EX_PARAMS => "placeholder='$lang{COMMENTS}'" }),
      );
    }

    $content .= $table->show({ OUTPUT2RETURN => 1 });
  }

  print $html->form_main(
      {
        CONTENT => $content,
        HIDDEN  => {
          SLIDES     => join(',', @$base_slides),
          index      => $index,
        },
        SUBMIT => { action => "$lang{CHANGE}" }
      }
    );

  return 1;
}

#**********************************************************
=head2 profile_get_admin_sender_subscribe_block()

=cut
#**********************************************************
sub profile_get_admin_sender_subscribe_block {
  my ($aid, $col_size) = @_;
  return '' unless ( $aid );
  
  $col_size //= 6;
  
  my %allowed_subscribes = (
    #    PUSH     => $conf{PUSH_ENABLED},
    TELEGRAM   => $conf{TELEGRAM_TOKEN},
    CELL_PHONE => in_array('Sms', \@MODULES)
  );
  
  require Contacts;
  
  my @types_to_search = grep {$allowed_subscribes{$_}} keys %allowed_subscribes;
  return '' unless ( @types_to_search );
  
  if ( $FORM{REMOVE_SUBSCRIBE} ) {
    if ( defined $Contacts::TYPES{uc($FORM{REMOVE_SUBSCRIBE})} ) {
      $admin->admin_contacts_del({
        AID     => $aid,
        TYPE_ID => $Contacts::TYPES{uc($FORM{REMOVE_SUBSCRIBE})}
      });
      _error_show($admin)
        and print $html->message('info', "$lang{UNSUBSCRIBE_FROM} $FORM{REMOVE_SUBSCRIBE}", $lang{SUCCESS});
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't do it now");
    }
  }
  
  my $contacts_list = $admin->admins_contacts_list({
    AID   => $admin->{AID},
    TYPE  => join(';', map {$Contacts::TYPES{$_}} @types_to_search),
    VALUE => '_SHOW'
  });
  _error_show($admin);
  
  my @buttons_html = ();
  
  my $make_subscribe_btn = sub {
    my ($name, $icon_classes, $lang_vars, $attr) = @_;
    
    my $button_text = (!$attr->{UNSUBSCRIBE}) ? "$lang{SUBSCRIBE_TO} $name" : "$lang{UNSUBSCRIBE_FROM} $name";
    
    my $icon_html = $html->element('span', '', { class => $icon_classes, OUTPUT2RETURN => 1 });
    my $text = $html->element('strong', $button_text, { class => $attr->{TEXT_CLASS}, OUTPUT2RETURN => 1 });
    
    my $button = '';
    if ( $attr->{HREF} ) {
      $button = $html->element('a', $icon_html . $text, {
          href       => $attr->{HREF},
          class      => 'btn form-control ' . ($attr->{BUTTON_CLASSES} || ' btn-info '),
          target     => '_blank',
          OUTPUT2RETURN => 1
        });
    }
    else {
      $button = $html->element('button', $icon_html . $text, {
          class => 'btn form-control ' . ($attr->{BUTTON_CLASSES} || ' btn-info '),
          OUTPUT2RETURN => 1
        });
    }
    
    my $lang_text = '';
    if ( $lang_vars && ref $lang_vars eq 'HASH' ) {
      $lang_text = join "; \n", map {
          qq{window['$_'] = '$lang_vars->{$_}'};
        } keys %{$lang_vars};
    }
    
    my $lang_script = ($lang_text) ? $html->element('script', $lang_text) : '';
    
    $button . $lang_script;
  };
  
  if ( $conf{PUSH_ENABLED} ) {
    push @buttons_html, $make_subscribe_btn->(
      'Push',
      'js-push-icon fa fa-bell',
      {
        ENABLE_PUSH           => $lang{ENABLE_PUSH},
        DISABLE_PUSH          => $lang{DISABLE_PUSH},
        PUSH_IS_NOT_SUPPORTED => $lang{PUSH_IS_NOT_SUPPORTED},
        PUSH_IS_DISABLED      => $lang{PUSH_IS_DISABLED},
      },
      {
        BUTTON_CLASSES => 'js-push-button btn-info',
        TEXT_CLASS     => 'js-push-text'
      }
    );
    # Unsubscribe is made via Javascript
  }
  
  if ( $conf{TELEGRAM_TOKEN} ) {
    my $telegram_cont = grep {$_->{type_id} == $Contacts::TYPES{TELEGRAM}} @{$contacts_list};
  
    if (!$telegram_cont) {
      # To build a subscribe link, should get bot name
      if ( !$conf{TELEGRAM_BOT_NAME} ) {
        require Abills::Sender::Telegram;
        Abills::Sender::Telegram->import();
        my $Telegram = Abills::Sender::Telegram->new(\%conf);
        $conf{TELEGRAM_BOT_NAME} = $Telegram->get_bot_name(\%conf, $db);
      }
    
      if ( $conf{TELEGRAM_BOT_NAME} ) {
        my $link_url = 'https://telegram.me/' . $conf{TELEGRAM_BOT_NAME} . '/?start=a_' . ($admin->{SID} || $sid || $admin->{sid});
        push @buttons_html, $make_subscribe_btn->(
          'Telegram',
          'fa fa-telegram',
          undef,
          {
            HREF => $link_url
          }
        );
      }
    }
    else {
      push @buttons_html, $make_subscribe_btn->(
        'Telegram',
        'fa fa-bell-slash',
        undef,
        {
          HREF        => $SELF_URL . '/admin/index.cgi?index=9&REMOVE_SUBSCRIBE=Telegram',
          UNSUBSCRIBE => 1,
          BUTTON_CLASSES => 'btn-success'
        }
      );
    }
  }
  
  my $subscribe_block = join('', map {
      $col_size
        ? "<div class='col-md-$col_size'>$_</div>"
        : $_
    } @buttons_html
  );
  
  return $subscribe_block;
}

#**********************************************************
=head2 admin_info_change() - Admin profile change

=cut
#**********************************************************
sub admin_info_change {
  $admin->info($admin->{AID});
  if ($FORM{chg_pswd} || $FORM{newpassword}) {
    form_passwd();
    if ($FORM{PASSWORD}) {
      $admin->change({
      AID      => $admin->{AID},
      PASSWORD => $FORM{PASSWORD},
    });
    }
  }
  if ($FORM{aedit}) {
    $admin->change({
      AID   => $admin->{AID},
      EMAIL => $FORM{email},
      A_FIO => $FORM{name},
    });
  }

  if ($FORM{clear_settings}){
    $admin->settings_del();
    $admin->change({
      AID   => $admin->{AID},
      WEB_OPTIONS => '',
    });

    $html->message("info", "$lang{SUCCESS}");
  }

  my $passwd_btn = $html->button($lang{CHANGE_PASSWORD}, "index=$index&chg_pswd=1", { class => 'btn btn-xs btn-primary' });
  my $clear_settings_btn = $html->button($lang{CLEAR_SETTINGS}, "index=$index&clear_settings=1", { class => 'btn btn-xs btn-danger' });

  $html->tpl_show(templates('form_admin_info_change'), {
      %$admin,
      CHG_PSW        => $passwd_btn,
      CLEAR_SETTINGS => $clear_settings_btn});

  return 1;
}

1;
