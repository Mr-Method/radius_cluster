=head2 NAME

  Stalker Web interface

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Iptv,
  $Tv_service,
  $db,
  $html,
  $admin,
  %lang,
  %tp_list,
  %channel_list
);

my $Tariffs = Tariffs->new( $db, \%conf, $admin );

#**********************************************************
=head2 stalker_console($attr) - Stalker user managment

  Arguments:
    $attr

=cut
#**********************************************************
sub stalker_console{
  #my ($attr) = @_;

  if ( ! $Tv_service || $Tv_service->{SERVICE_NAME} ne 'Stalker'){
    $html->message( 'err', $lang{ERROR}, "Stalker not connected", { ID => 889 });
    return 0;
  }

  my $service_id = $FORM{SERVICE_ID};

  if ( $FORM{hangup} ){
    iptv_account_action({ hangup => 1, UID => $FORM{UID}  });
  }
  elsif ( $FORM{send_message} ){
    $FORM{UID} = $Iptv->{CID};
    iptv_account_action({ send_message => 1, %$Iptv, %FORM  });
    return $Tv_service->{error};
  }
  elsif ( $FORM{add} || $FORM{change} ){
    #    if ( !$users ){
    #      $users = $user;
    #    }
    #    $users->info( $users->{UID} || $FORM{UID}, { SHOW_PASSWORD => 1, } );
    #    $users->pi( { UID => $users->{UID} || $FORM{UID} } );
    #    $Tv_service->user_add({ %{$users}, %{$Iptv}, %FORM });
    return $Tv_service->{error};
  }
  #  elsif ( $FORM{del} ){
  #    $Tv_service->user_action( { %{$users}, %{$Iptv}, del => 1, MAC => $FORM{MAC} } );
  #    if ( !_error_show( $Tv_service, { MESSAGE => $Tv_service->{errstr} } ) ){
  #      $html->message( 'info', $lang{INFO}, "$lang{DELETED}\n ID: $FORM{del}\n MAC: ". ($FORM{MAC} || q{}) );
  #    }
  #    else {
  #      if($Tv_service->{errstr} =~ /Account not found/){
  #        delete $Tv_service->{error};
  #        return 0;
  #      }
  #    }
  #    return $Tv_service->{error};
  #  }

  my @header_arr = ("$lang{ACCOUNTS}:index=$index&SERVICE_ID=$service_id",
    "STB:index=$index&list=STB&SERVICE_ID=$service_id",
    "$lang{CHANNELS}:index=$index&list=ITV&SERVICE_ID=$service_id",
    "$lang{SUBSCRIBES}:index=$index&list=ITV_SUBSCRIPTION&SERVICE_ID=$service_id",
    "$lang{TARIF_PLANS}:index=$index&list=tariffs&SERVICE_ID=$service_id",
    "CONSOLE:index=$index&list=console&SERVICE_ID=$service_id");
  print $html->table_header( \@header_arr, { TABS => 1 } );

  # Get tps
  my $list = $Tariffs->list({
    MODULE       => 'Iptv',
    NEW_MODEL_TP => 1,
    COLS_NAME    => 1
  });

  foreach my $tp ( @{$list} ){
    $tp_list{ $tp->{id} } = $tp->{tp_id};
  }
  if ( $FORM{register} ){
    if ( !$tp_list{ $FORM{TP_ID} } ){
      $html->message( 'err', $lang{ERROR}, "$lang{TARF_PLAN} $lang{NOT_EXIST}" );
    }
    else{
      $users->add( { %FORM } );
      $FORM{TP_ID} = $tp_list{ $FORM{TP_ID} };
      if ( !_error_show( $users, { MESSAGE => 'Stalker' } ) ){
        $Iptv->user_add( { %FORM, UID => $users->{UID} } );
      }
    }
  }
  elsif ( $FORM{tp_add} ){
    if ( $FORM{EXTERNAL_ID} ){
      $FORM{ID} = $FORM{EXTERNAL_ID};
    }
    $Tariffs->add( { %FORM, MODULE => 'Iptv' } );
    if ( !_error_show( $Tariffs ) ){
      $html->message( 'info', "Stalker",
        "$lang{TARIF_PLAN} $lang{ADDED} [ $Tariffs->{INSERT_ID} ]\n " . $html->button( "$lang{CONFIG}",
          "index=" . get_function_index( 'iptv_tp' ) . "&TP_ID=$Tariffs->{INSERT_ID}", { BUTTON => 1 } ) );
      $tp_list{ $FORM{ID} } = $Tariffs->{INSERT_ID};
    }
  }

  if ( $FORM{list} ){
    iptv_stalker_show_list( $FORM{list} );
    return 0;
  }
  elsif ( $FORM{del} ){
    return 0;
  }

  if(! $Tv_service->can('get_users')) {
    return 1;
  }

  $Tv_service->get_users();
  if (_error_show( $Tv_service, { MESSAGE => "Stalker : $lang{ERROR}" } )) {
    return 0;
  }

  # Get abills users
  my %register_stb = ();
  $list = $Iptv->user_list({
    PAGE_ROWS => 1000000,
    CID       => '_SHOW',
    COLS_NAME => 1
  });

  foreach my $line ( @{$list} ){
    $register_stb{ $line->{cid} } = $line->{uid};
  }

  my @TITLE = ();

  if ( $Tv_service->{RESULT}->{results} ){
    @TITLE = keys %{ $Tv_service->{RESULT}->{results}->[0] };
  }

  my $table = $html->table({
    width   => '100%',
    title   => [ @TITLE, '-' ],
    caption => $lang{ACCOUNTS},
    ID      => 'STALKER_CONSOLE'
  });

  foreach my $account_hash ( @{ $Tv_service->{RESULT}->{results} } ){
    next if (! $account_hash);
    my @row = ();
    foreach my $key (@TITLE) {
      my $val = $account_hash->{$key};
      if ($val){
        Encode::_utf8_off( $val );
      }
      else {
        $val //= q{};
      }

      if ( $key eq 'tariff_plan' ){
        if ( $val && !$tp_list{$val} ){
          $val = "$val " . $html->br() . $html->color_mark( $lang{NOT_EXIST}, 'red' ) . $html->button( $lang{ADD},
            "ID=$val&index=" . get_function_index( 'iptv_tp' ), { class => 'add' } );
        }
      }
      elsif ( ref $val eq 'ARRAY' ){
        $val = join( $html->br(), @{$val} );
      }
      elsif ( $key eq 'stb_mac' ){
        $val = $html->button($val, "index=$index&list=STB_MODULES&MAC=$val" );
      }
      elsif ( $key eq 'login' ){
        $val = $html->button( $val, "index=7&search=1&type=11&LOGIN=$val" );
      }
      elsif ( $key eq 'status' ){
        $val = ($val) ? $html->color_mark( $lang{ENABLE}, 'success' ) : $html->color_mark( $lang{DISABLE}, 'danger' );
      }
      elsif ( $key eq 'online' ){
        $val = ($val) ? $html->color_mark( $lang{YES}, 'success' ) : $html->color_mark( $lang{NO}, 'danger' );
      }

      push @row, $val;
    }

    my $stb_mac = $account_hash->{stb_mac} || q{};
    if ( $stb_mac && $register_stb{ $stb_mac } ){
      push @row, $html->button( $lang{SHOW}, "index=15&UID=$register_stb{ $stb_mac }",
          { class => 'show', TITLE => $account_hash->{stb_mac} } );
    }
    else{
      push @row, $html->button( $lang{ADD}.'-----',
          "index=$index&register=1&MAC=" . (($account_hash->{login}) ? $account_hash->{login} : $stb_mac)
            . "&PASSWORD="
            . "&TP_ID=". ($account_hash->{tariff_plan} || '')
            . "&STATUS=". ($account_hash->{status} || '')
            . "&CREATE_BILL=1"
            . "&CID=". $stb_mac
          , { class => 'add' } );
    }

    push @row, $html->button( $lang{DEL}, "index=$index&list=". ($FORM{list} || '') ."&MAC=$stb_mac&del=1",
        { MESSAGE => "$lang{DEL} $stb_mac ?", class => 'del' } );

    $table->addrow( @row );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 iptv_stalker_show_list($list_name)

=cut
#**********************************************************
sub iptv_stalker_show_list{
  my ($list_name) = @_;

  my $request = '';
  my %PARAMS_HASH = ();
  $pages_qs .= "&list=$FORM{list}";

  my $list_type = $FORM{list} || q{};

  if ( $list_name eq 'ITV' ){
    my $list = $Iptv->channel_list( { COLS_NAME => 1, PAGE_ROWS => 10000 } );
    foreach my $line ( @{$list} ){
      $channel_list{ $line->{num} } = $line->{name};
    }
    $request = "ITV";
  }
  elsif ( $list_name eq 'console' ){
    my @action_methods = ('GET', 'POST', 'PUT');
    my $action_method = $html->form_select(
      'COMMAND',
      {
        SELECTED  => $FORM{COMMAND} || 'GET',
        SEL_ARRAY => \@action_methods,
      }
    );
    print $html->form_main(
        {
          CONTENT =>
          "$lang{PREFIX}: " . $html->form_input( 'REQUEST', $FORM{REQUEST} ) . "$lang{PARAMS}: " . $html->form_input( 'PARAMS',
            $FORM{PARAMS} ) . "$lang{ACTION}: " . $action_method,
          HIDDEN  => {
            list  => "console",
            index => "$index",
          },

          #class  => 'form-inline',
          SUBMIT  => { show => "$lang{SHOW}" }
        }
      );
    if ( $FORM{REQUEST} ){
      $pages_qs .= "&REQUEST=$FORM{REQUEST}";
      $request = $FORM{REQUEST};
      $list_name .= " : $request ";
    }

    foreach my $line ( split( /&/, $FORM{PARAMS} || q{} ) ){
      if($line){
        my ($k, $v) = split( /=/, $line );
        $PARAMS_HASH{$k} = $v;
      }
    }
  }
  elsif ( $FORM{reboot} ){
    $request = "send_event/". $FORM{MAC};
    $PARAMS_HASH{event} = 'reboot';
  }
  else{
    $request = "$list_name/". ($FORM{MAC} || q{});
  }

  $Tv_service->_send_request({
      ACTION  => $request,
      COMMAND => $FORM{COMMAND},
      %PARAMS_HASH,
      DEBUG   => $FORM{DEBUG},
    });

  _error_show( $Tv_service, {
      ID      => 860,
      MESSAGE => $Tv_service->{errstr}
    });

#  my %info_oids = (
#    enable_monitoring => $lang{MONITORING},
#    number            => $lang{NUM},
#    url               => 'URL',
#    hd                => 'HD',
#    name              => $lang{NAME},
#    id                => 'ID',
#    base_ch           => $lang{BASE},
#  );

  my $FUNCTION_FIELDS = "iptv_console:del:mac;serial_number:&list=$list_type&del=1&COMMENTS=1&SERVICE_ID=".$FORM{SERVICE_ID};    #":$lang{DEL}:MAC:&del=1&COMMENTS=del",

  if ( $list_type eq 'tariffs' ){
    $FUNCTION_FIELDS = "iptv_console:add:external_id;name:&list=$list_type&tp_add=1&SERVICE_ID=".$FORM{SERVICE_ID};
  }
  elsif ( $list_type eq 'ITV' ){
    $FUNCTION_FIELDS = '';
    if ( $FORM{import_channels} ){
      $Iptv->channel_del( 0, { ALL => 1 } );
      my $channels_count = 0;
      foreach my $account_hash ( @{ $Tv_service->{RESULT}->{results} } ){
        $Iptv->channel_add(
          {
            ID       => $account_hash->{id},
            NAME     => $account_hash->{name},
            NUM      => $account_hash->{number},
            PORT     => $account_hash->{id},
            DESCRIBE => $account_hash->{name},
            DISABLE  => 0
          }
        );
        _error_show( $Iptv, { MESSAGE => "$lang{CHANNEL}: [$account_hash->{number}] $account_hash->{name}" } );
        $channels_count++;
      }

      $html->message('info', $lang{INFO}, "$lang{IMPORT} # $channels_count");
    }
  }
  elsif ( $list_type eq 'STB' ){
    $FUNCTION_FIELDS = "iptv_console:hangup:mac;name:&list=$list_type&reboot=1&SERVICE_ID=".$FORM{SERVICE_ID};
  }

  result_former({
    FUNCTION_FIELDS => $FUNCTION_FIELDS, #":$lang{DEL}:MAC:&del=1&COMMENTS=del",
    #EXT_TITLES      => \%info_oids,
    SELECT_VALUE    => {
      online => {
        0 => "$lang{NO}:danger",
        1 => "$lang{YES}:success",
      },
      status => {
        0 => "$lang{DISABLE}:danger",
        1 => "$lang{ENABLE}:success",
      }
    },
    TABLE         => {
      width            => '100%',
      caption          => 'new ' . ($list_type || 'getUserList') . ' ' . $html->button( 'API', "",
          { GLOBAL_URL => 'http://wiki.infomir.eu/doku.php/stalker:rest_api_v1', target => '_new' } ),
      qs               => $pages_qs,
      SHOW_COLS_HIDDEN => { visual => $FORM{visual}, },
      header           => ($list_name eq 'ITV') ? $html->button( "$lang{IMPORT} $lang{CHANNELS}", "index=$index&list=ITV&import_channels=1&SERVICE_ID=".$FORM{SERVICE_ID},
            { BUTTON => 1 } )   : '',
      ID               => 'TV_STALKER_LIST',
    },
    FILTER_COLS   => {
      account              => 'search_link:iptv_users_list:ID',
      SubscriberProviderID => 'search_link:iptv_users_list:ID',
      external_id          => 'iptv_show_tp:EXTERNAL_ID',
      number               => 'iptv_show_channels:number,name,id',
      name                 => '_utf8_encode',
      ls                   => 'search_link:iptv_users_list:ID',
      login                => 'search_link:form_users_list:LOGIN',
    },
    DATAHASH      => $Tv_service->{RESULT}->{results},
    TOTAL         => 1
  });

  if ( $Tv_service->{RESULT} && ref $Tv_service->{RESULT}->{results} eq 'HASH' ){
    my $table = $html->table(
      {
        width   => '100%',
        title   => [ $lang{PARAMS}, $lang{VALUE} ],
        caption => "$lang{LIST}: $list_name",
        ID      => 'CLOSE_PERIOD'
      }
    );

    while (my ($key, $val) = each %{ $Tv_service->{RESULT}->{results} }) {
      my @row = ();
      if ( ref $val eq 'ARRAY' ){
        push @row, $key, join( $html->br(), @{$val} );
      }
      else{
        if ( $key eq 'mac' ){
          $val = $html->button( $val, "index=$index&list=STB_MODULES&MAC=$val&SERVICE_ID=".$FORM{SERVICE_ID} );
        }
        push @row, "$key", "$val";
      }
      $table->addrow( @row );
    }
    print $table->show();
    return 0;
  }

  return 1;
}

##**********************************************************
#=head2 stalker_tariff_export($attr) - STALKER DB: stalker export tariff plan
#
#=cut
##**********************************************************
#sub stalker_tariff_export{
#  my ($attr) = @_;
#
#  if ( defined( $Iptv_stalker ) ){
#    if ( !_error_show( $Iptv_stalker ) ){
#
#      #Export from DB stalker - table tariff_plan
#      my $list_tariffs = $Iptv_stalker->stalker_db_list_tariffs();
#      foreach my $stalker_tp_id ( @{$list_tariffs} ){
#        $Iptv_stalker->stalker_tp_export( $stalker_tp_id->[0] );
#      }
#      foreach my $line ( @{$list_tariffs} ){
#
#        #print $line->[0] . 'oz';
#        $Iptv_stalker->replace_interval_id( $line->[0] );
#
#        #push(@stalker_tp_id, $line->[0]);
#      }
#      if ( !defined( $attr->{WITHOUT_SUBSCRIPTION} ) ){
#        $Iptv_stalker->stalker_subscribe_export();
#      }
#      return 0;
#
#      #Add intervals to abills with stalkers tariff ids
#      #$Iptv_stalker->intervals_stalker_tp(\@stalker_tp_id);
#    }
#  }
#
#  #$Iptv_stalker->stalker_tp_export()
#  return 1;
#}

##**********************************************************
#=head2 stalker_export($attr) - STALKER DB: Stalker export
#
#=cut
##**********************************************************
#sub stalker_export{
#  #my ($attr) = @_;
#
#  if ( defined( $Iptv_stalker ) ){
#    $Iptv_stalker->stalker_channel_export();
#    if ( !$Iptv_stalker->{errno} ){
#      if ( !defined( $FORM{stalker_del} && !defined( $FORM{stalker_change} ) ) ){
#        $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
#      }
#    }
#    else{
#      $html->message( 'err', $lang{ERROR}, "$Iptv_stalker->{errno} $Iptv_stalker->{errstr}" );
#    }
#  }
#
#  return 1;
#}


1;