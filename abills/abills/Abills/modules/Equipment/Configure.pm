=head1 NAME

   Equipment Configure

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Equipment,
  %lang,
  $html,
  @port_types,
  $SNMP_TPL_DIR
);

#********************************************************
=head2 equipment_types()

=cut
#********************************************************
sub equipment_types{

  $Equipment->{ACTION} = 'add';
  $Equipment->{ACTION_LNG} = $lang{ADD};

  if ( $FORM{add} ){
    $Equipment->type_add( { %FORM } );

    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Equipment->type_change( { %FORM } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
  }
  elsif ( defined( $FORM{chg} ) ){
    $Equipment->type_info( $FORM{chg} );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" );
    }
    $Equipment->{ACTION} = 'change';
    $Equipment->{ACTION_LNG} = $lang{CHANGE};
  }
  elsif ( defined( $FORM{del} ) && defined( $FORM{COMMENTS} ) ){
    $Equipment->type_del( $FORM{del} );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
  }

  _error_show( $Equipment );

  $html->tpl_show( _include( 'equipment_type', 'Equipment' ), { %{$Equipment}, %FORM } );

  result_former(
    {
      INPUT_DATA        => $Equipment,
      FUNCTION        => 'type_list',
      BASE_FIELDS     => 2,
      FUNCTION_FIELDS => 'change,del',
      EXT_TITLES      => {
        name => $lang{NAME},
      },
      SKIP_USER_TITLE => 1,
      TABLE           => {
        width   => '100%',
        caption => "$lang{TYPES}",
        qs      => $pages_qs,
        ID      => 'EQUIPMENT_TYPES',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      TOTAL           => 1
    }
  );

  return 1;
}

#********************************************************
=head2 equipment_vendor() - Vendor managment

=cut
#********************************************************
sub equipment_vendor{

  $Equipment->{ACTION} = 'add';
  $Equipment->{ACTION_LNG} = $lang{ADD};

  if ( $FORM{add} ){
    $Equipment->vendor_add( { %FORM } );

    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Equipment->vendor_change( { %FORM } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
  }
  elsif ( defined( $FORM{chg} ) ){
    $Equipment->vendor_info( $FORM{chg} );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" );
    }
    $Equipment->{ACTION} = 'change';
    $Equipment->{ACTION_LNG} = $lang{CHANGE};
  }
  elsif ( defined( $FORM{del} ) && defined( $FORM{COMMENTS} ) ){
    $Equipment->vendor_del( $FORM{del} );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
  }

  _error_show( $Equipment );

  $html->tpl_show( _include( 'equipment_vendor', 'Equipment' ), { %{$Equipment}, %FORM } );

  result_former(
    {
      INPUT_DATA        => $Equipment,
      FUNCTION        => 'vendor_list',
      BASE_FIELDS     => 2,
      FUNCTION_FIELDS => 'change,del',
      EXT_TITLES      => {
        name    => $lang{NAME},
        support => $lang{COMMENTS},
        site    => 'www'
      },
      SKIP_USER_TITLE => 1,
      TABLE           => {
        width   => '100%',
        caption => "$lang{VENDOR}",
        qs      => $pages_qs,
        ID      => 'EQUIPMENT_VENDOR',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      TOTAL           => 1
    }
  );

  return 1;
}


#********************************************************
=head2 equipment_model() - Equipment model list

=cut
#********************************************************
sub equipment_model{
  
  $Equipment->{ACTION} = 'add';
  $Equipment->{ACTION_LNG} = $lang{ADD};
  
  my $parse_extra_ports = sub {
    my %extra_ports_types = ();
    my %extra_ports_rows = ();
    
    if ( $FORM{HAS_EXTRA_PORTS} && $FORM{HAS_EXTRA_PORTS} > 0 ) {
      my $extra_ports_count = $FORM{HAS_EXTRA_PORTS};
      for ( my $i = 1; $i <= $extra_ports_count; $i++ ) {
        if ( exists $FORM{"EXTRA_PORT_$i"} && $FORM{"EXTRA_PORT_$i"} ) {
          my $port_type = $FORM{"EXTRA_PORT_$i"};
          $extra_ports_types{$i} = $port_type;
          $extra_ports_rows{$i} = $FORM{"EXTRA_PORT_ROW_$i"} - 1;
        }
      }
    }
    
    {
      EXTRA_PORTS     => \%extra_ports_types,
      EXTRA_PORT_ROWS => \%extra_ports_rows
    };
  };
  
  if ( $FORM{add} ) {
    
    my $EXTRA_PORTS_PARAMS = $parse_extra_ports->(\%FORM);
    $Equipment->model_add( { %FORM, %{ $EXTRA_PORTS_PARAMS || { } } } );
    
    if ( !$Equipment->{errno} ) {
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ) {
    
    my $EXTRA_PORTS_PARAMS = $parse_extra_ports->(\%FORM);
    
    $Equipment->model_change( {
      %FORM,
      %{ $EXTRA_PORTS_PARAMS || { } }
    });
    
    if ( !$Equipment->{errno} ) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
    
    $Equipment->model_info( $FORM{ID} );
    $Equipment->{PORTS_PREVIEW} = equipment_port_panel( $Equipment );
  }
  elsif ( defined( $FORM{chg} ) ) {
    $Equipment->model_info( $FORM{chg} );
    
    if ( !$Equipment->{errno} ) {
      #      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
    
    $Equipment->{PORTS_PREVIEW} = equipment_port_panel( $Equipment );
  }
  elsif ( defined( $FORM{del} ) && defined( $FORM{COMMENTS} ) ) {
    $Equipment->model_del( $FORM{del} );
    if ( !$Equipment->{errno} ) {
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
  }
  
  _error_show( $Equipment );
  
  $Equipment->{TYPE_SEL} = $html->form_select(
    'TYPE_ID',
    {
      SELECTED       => $Equipment->{TYPE_ID} || 0,
      SEL_LIST       => $Equipment->type_list( { COLS_NAME => 1 } ),
      NO_ID          => 1,
      MAIN_MENU      => get_function_index( 'equipment_types' ),
      MAIN_MENU_ARGV => "chg=" . ($Equipment->{TYPE_ID} || '')
    }
  );
  
  $Equipment->{VENDOR_SEL} = $html->form_select(
    'VENDOR_ID',
    {
      SELECTED       => $Equipment->{VENDOR_ID},
      SEL_LIST       => $Equipment->vendor_list( { COLS_NAME => 1, PAGE_ROWS => 50 } ),
      NO_ID          => 1,
      MAIN_MENU      => get_function_index( 'equipment_vendor' ),
      MAIN_MENU_ARGV => "chg=" . ($Equipment->{VENDOR_ID} || '')
    }
  );
  
  my @port_numbering_options = ($lang{BY_ROW}, $lang{BY_COLUMN});
  
  $Equipment->{PORT_NUMBERING_SELECT} = $html->form_select(
    'PORT_NUMBERING',
    {
      SELECTED     => $Equipment->{PORT_NUMBERING},
      SEL_ARRAY    => \@port_numbering_options,
      ARRAY_NUM_ID => 1
    }
  );
  
  $Equipment->{PORTS_TYPE_SELECT} = $html->form_select(
    'PORTS_TYPE',
    {
      SELECTED     => $Equipment->{PORTS_TYPE} || 1,
      SEL_ARRAY    => \@port_types,
      ARRAY_NUM_ID => 1
    }
  );
  
  my @first_port_position_options = ($lang{POSITION_UP}, $lang{POSITION_DOWN});
  
  $Equipment->{FIRST_POSITION_SELECT} = $html->form_select(
    'FIRST_POSITION',
    {
      SELECTED     => $Equipment->{FIRST_POSITION},
      SEL_ARRAY    => \@first_port_position_options,
      ARRAY_NUM_ID => 1
    }
  );
  
  $Equipment->{EXTRA_PORT1_SELECT} = $html->form_select(
    'EXTRA_PORT1',
    {
      SEL_ARRAY    => \@port_types,
      ARRAY_NUM_ID => 1
    }
  );
  
  my @contents = ();
  
  if ( opendir( my $fh, "$SNMP_TPL_DIR" ) ) {
    @contents = grep !/^\.\.?$/, readdir $fh;
    closedir $fh;
  }
  else {
    $html->message( 'err', $lang{ERROR}, "Can't open dir '$SNMP_TPL_DIR' $!" );
    return 0;
  }
  
  $Equipment->{SNMP_TPL_SEL} = $html->form_select(
    'SNMP_TPL',
    {
      SELECTED    => $FORM{SNMP_TPL} || $Equipment->{SNMP_TPL},
      SEL_ARRAY   => \@contents,
      SEL_OPTIONS => { '' => '--' },
    }
  );
  
  $Equipment->{ADD_BUTTON_INDEX} = get_function_index( 'equipment_model' );
  $html->tpl_show( _include( 'equipment_model', 'Equipment' ), { %{$Equipment}, %FORM } );
  $LIST_PARAMS{PAGE_ROWS} = '100000';
  result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'model_list',
    BASE_FIELDS     => 2,
    SKIP_PAGES      => 1,
    DEFAULT_FIELDS  => 'VENDOR_NAME,MODEL_NAME,TYPE_NAME,PORTS',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      vendor_name => $lang{VENDOR},
      model_name  => $lang{NAME},
      type_name   => $lang{TYPE},
      ports       => $lang{PORTS},
#      site        => $lang{SITE},
      manage_web  => 'web',
      manage_ssh  => 'ssh',
      snmp_tpl    => 'SNMP tpl',
      comments    => $lang{COMMENTS},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "$lang{EQUIPMENT}",
      qs      => $pages_qs,
      ID      => 'EQUIPMENT_MODELS_',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:add_form=1&index=$index:add" 
#. ";$lang{SEARCH}:index=$index&search_form=1:search",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
  
  print '<script>$(function () {
  var $table = $(\'#EQUIPMENT_MODELS__\');
  var correct = ($table.find(\'tbody\').find(\'tr\').first().find(\'td\').length - $table.find(\'thead th\').length );
  for (var i = 0; i < correct; i++) {
    $table.find(\'thead th:last-child\').after(\'<th></th>\');
  }
    var dataTable = $("#EQUIPMENT_MODELS__")
      .DataTable({
        "language": {
          paginate: {
              first:    "«",
              previous: "‹",
              next:     "›",
              last:     "»",
          },
          "zeroRecords":    "' . $lang{NOT_EXIST} . '",
          "lengthMenu":     "' . $lang{SHOW} . ' _MENU_",
          "search":         "' . $lang{SEARCH} . ':",
          "info":           "' . $lang{SHOWING} . ' _START_ - _END_ ' . $lang{OF} . ' _TOTAL_ ",
          "infoEmpty":      "' . $lang{SHOWING} . ' 0",
          "infoFiltered":   "(' . $lang{TOTAL} . ' _MAX_)",
        },
        "ordering": false,
        "lengthMenu": [[25, 50, -1], [25, 50, "' . $lang{ALL} . '"]]
      });
    });</script>';
  return 1;
}


1;
