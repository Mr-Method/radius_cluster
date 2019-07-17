=head1 NAME

  TV services

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Filters qw(_utf8_encode);

our (
  $html,
  %lang,
  $db,
  $admin,
  %conf,
);

our Iptv $Iptv;

#**********************************************************
=head2 tv_services($attr)

=cut
#**********************************************************
sub tv_services {

  $Iptv->{ACTION} = 'add';
  $Iptv->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{add} ){
    $Iptv->services_add( { %FORM } );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{SCREENS}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Iptv->services_change( \%FORM );
    if ( !_error_show( $Iptv ) ){
      $html->message( 'info', $lang{SCREENS}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Iptv->services_info( $FORM{chg} );
    if ( !$Iptv->{errno} ){
      $FORM{add_form} = 1;
      $Iptv->{ACTION} = 'change';
      $Iptv->{LNG_ACTION} = $lang{CHANGE};
      $html->message( 'info', $lang{SCREENS}, $lang{CHANGING} );

      if ($Iptv->{MODULE}) {
        my $Tv_service = tv_load_service( $Iptv->{MODULE}, { SERVICE_ID => $Iptv->{ID}, SOFT_EXCEPTION => 1 } );
        if($Tv_service && $Tv_service->{VERSION}) {
          $Iptv->{MODULE_VERSION} = $Tv_service->{VERSION};
        }

        if($Tv_service && $Tv_service->can('tp_export')) {
          $Iptv->{TP_IMPORT} = $html->button("$lang{IMPORT} $lang{TARIF_PLAN}", "index=$index&tp_import=1&chg=$Iptv->{ID}",
            { class => 'btn btn-default btn-success' });

          if($FORM{tp_import}) {
            my %SUBCRIBES_TYPE = (
              0 => $lang{TARIF_PLAN},
              1 => $lang{CHANNELS}
            );

            my $result = $Tv_service->tp_export();
            if($FORM{tp_import} == 2) {
              my $Tariffs = Tariffs->new( $db, \%conf, $admin );
              my $message = '';
              my @tp_ids = split(/,\s?/, $FORM{IDS});

              foreach my $tp_id (@tp_ids) {
                if($FORM{'TP_TYPE_'. $tp_id}) {
                  $Iptv->channel_add({
                    NUM       => $tp_id,
                    NAME      => $FORM{'NAME_'. $tp_id},
                    FILTER_ID => $tp_id,
                  });

                  _error_show($Iptv, { MESSAGE => "$lang{CHANNEL}: ".$tp_id });
                }
                else {
                  $Tariffs->add({
                    SERVICE_ID => $Iptv->{ID},
                    NAME       => $FORM{'NAME_'. $tp_id},
                    FILTER_ID  => $tp_id,
                    ID         => $tp_id,
                    MODULE     => 'Iptv'
                  });
                  _error_show($Tariffs, { MESSAGE => "$lang{TARIF_PLAN}: ".$tp_id });
                }

                $message .= "$Iptv->{ID} $tp_id - $FORM{'NAME_'. $tp_id} $lang{TYPE}:".
                  $SUBCRIBES_TYPE{$FORM{'TP_TYPE_'. $tp_id}} ."\n";
              }
              $html->message('info', $lang{INFO}, $message);
            }
            else {
              my $table = $html->table({
                width       => '100%',
                caption     => $lang{SUBSCRIBES},
                title_plain => [ '#', $lang{NUM}, $lang{NAME}, $lang{TYPE} ],
                ID          => 'IPTV_EXPORT_TPS',
                EXPORT      => 1
              });

              foreach my $tp ( @$result ){
                my $tp_type = $html->form_select('TP_TYPE_'.$tp->{ID}, {
                  SELECTED => 0,
                  SEL_HASH => \%SUBCRIBES_TYPE,
                  NO_ID    => 1
                });

                $table->addrow(
                  $html->form_input('IDS', $tp->{ID}, { TYPE => 'checkbox'}),
                  $tp->{ID},
                  $html->form_input('NAME_'.$tp->{ID}, _utf8_encode($tp->{NAME}), { EX_PARAMS => 'readonly' }),
                  $tp_type
                );
              }

              print $html->form_main({
                CONTENT => $table->show( { OUTPUT2RETURN => 1 } ),
                HIDDEN  => {
                  index     => $index,
                  tp_import => 2,
                  chg       => $Iptv->{ID},
                },
                METHOD  => 'get',
                SUBMIT  => { import => $lang{IMPORT} }
              });

              return 0;
            }
          }
        }

        if($Tv_service && $Tv_service->can('test')) {
          if($FORM{test}) {
            my $result = $Tv_service->test();
            if (!$Tv_service->{errno}) {
              $html->message('info', $lang{INFO}, "$lang{TEST}\n$result");
            }
            else {
              _error_show($Tv_service);
            }
          }
          else {
            $Iptv->{SERVICE_TEST} = $html->button("$lang{TEST}", "index=$index&test=1&chg=$Iptv->{ID}",
              { class => 'btn btn-default btn-info' });
          }
        }
      }
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Iptv->services_del( $FORM{del} );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{SCREENS}, $lang{DELETED} );
    }
  }
  #  elsif ( $FORM{log_del} && $FORM{COMMENTS} ){
  #    $Iptv->services_log_del( "$FORM{log_del}" );
  #    if ( !$Iptv->{errno} ){
  #      $html->message( 'info', $lang{SCREENS}, "$lang{LOG} $lang{DELETED}" );
  #    }
  #  }
  #if ( $FORM{add_form} ){

  $Iptv->{USER_PORTAL_SEL} = $html->form_select(
    'USER_PORTAL',
    {
      SELECTED    => $Iptv->{USER_PORTAL} || 0,
      SEL_HASH    => {
        0 => '--',
        1 => $lang{INFO},
        2 => $lang{CONTROL} || 'Control'
      },
      NO_ID => 1
    }
  );

  $Iptv->{DEBUG_SEL} = $html->form_select(
    'DEBUG',
    {
      SELECTED     => $Iptv->{DEBUG} || 0,
      SEL_ARRAY    => [0,1,2,3,4,5,6,7],
    }
  );

  $Iptv->{USER_PORTAL} = ($Iptv->{USER_PORTAL}) ? 'checked' : '';
  $Iptv->{STATUS} = ($Iptv->{STATUS}) ? 'checked' : '';
  $html->tpl_show( _include( 'iptv_services_add', 'Iptv' ), $Iptv );
  #}

  _error_show( $Iptv );

  result_former({
    INPUT_DATA      => $Iptv,
    FUNCTION        => 'services_list',
    DEFAULT_FIELDS  => 'NAME,MODULE,STATUS,COMMENT',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      name    => $lang{NAME},
      module  => $lang{MODULE},
      status  => $lang{STATUS},
      comment => $lang{COMMENTS},
    },
    SKIP_USERS_FIELDS => 1,
    TABLE           => {
      width      => '100%',
      caption    => "TV SERVICES",
      qs         => $pages_qs,
      ID         => "$lang{TV} $lang{SERVICES}",
    },
    MAKE_ROWS    => 1,
    TOTAL        => 1,
  });

  return 1;
}

#**********************************************************
=head2 tv_services_sel($attr)

  Arguments:
     SERVICE_ID
     FORM_ROW
     USER_PORTAL
     HASH_RESULT
     ALL
     UNKNOWN

  Returns:

=cut
#**********************************************************
sub tv_services_sel {
  my ($attr) = @_;

  my %params = ();

  if($attr->{ALL}) {
    $params{SEL_OPTIONS} = {'' => $lang{ALL}};
  }

  if($attr->{UNKNOWN}) {
    $params{SEL_OPTIONS}->{0} = $lang{UNKNOWN};
  }

  my $active_service = $attr->{SERVICE_ID} || $FORM{SERVICE_ID};

  my $service_list = $Iptv->services_list({
    STATUS      => 0,
    NAME        => '_SHOW',
    USER_PORTAL => $attr->{USER_PORTAL},
    COLS_NAME   => 1
  });

  if($attr->{HASH_RESULT}) {
    my %service_name = ();

    foreach my $line ( @$service_list ) {
      $service_name{$line->{id}}=$line->{name};
    }

    return \%service_name;
  }

  my $result =  $html->form_select(
    'SERVICE_ID',
    {
      SELECTED       => $active_service,
      SEL_LIST       => $service_list,
      EX_PARAMS      => "onchange='autoReload()'",
      MAIN_MENU      => get_function_index( 'tv_services' ),
      MAIN_MENU_ARGV =>($active_service) ? "chg=$active_service" : q{},
      %params
    }
  );

  if(!$active_service && $service_list->[0]) {
    $FORM{SERVICE_ID}=$service_list->[0]->{id};
  }

  if($attr->{FORM_ROW}) {
    $result = $html->tpl_show(
      templates( 'form_row' ),
      {
        ID    => 'SERVICE_ID',
        NAME  => $lang{SERVICE},
        VALUE => $result
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  return $result;
}

#**********************************************************
=head2 tv_load_service($service_name, $attr) - Load service module

  Argumnets:
    $service_name  - service modules name
    $attr
       SERVICE_ID
       SOFT_EXCEPTION

  Returns:
    Module object

=cut
#**********************************************************
sub tv_load_service{
  my ($service_name, $attr) = @_;
  my $api_object;

  my $Iptv_service = Iptv->new( $db, $admin, \%conf );
  if ($attr->{SERVICE_ID}) {
    $Iptv_service->services_info($attr->{SERVICE_ID});
    $service_name = $Iptv_service->{MODULE};
  }

  if(! $service_name) {
    return $api_object;
  }

  $service_name = 'Iptv::' . $service_name;

  eval " require $service_name; ";
  if ( !$@ ){
    $service_name->import();
    $api_object = $service_name->new( $db, $admin, \%conf, { %$Iptv_service, HTML => $html  });

    if ($api_object->{SERVICE_NAME}) {
      if ($api_object->{SERVICE_NAME} eq 'Olltv') {
        require Iptv::Olltv_web;
      }
      elsif($api_object->{SERVICE_NAME} eq 'Stalker') {
        require Iptv::Stalker_web;
      }
    }
  }
  else{
    $FORM{DEBUG}=1;
    print $@ if($FORM{DEBUG});
    $html->message( 'err', $lang{ERROR}, "Can't load '$service_name'. Purchase this module http://abills.net.ua" );
    if (!$attr->{SOFT_EXCEPTION}) {
      die "Can't load '$service_name'. Purchase this module http://abills.net.ua";
    }
  }

  return $api_object;
}


1;