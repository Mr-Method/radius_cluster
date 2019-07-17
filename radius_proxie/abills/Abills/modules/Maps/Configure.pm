#package Maps::Configure;
use strict;
use warnings FATAL => 'all';
use v5.16;

=head1 NAME

  Maps::Configure - forms for webinterface

=cut


require JSON;
JSON->import(qw/to_json from_json/);

use Abills::Base qw/_bp in_array/;
use Abills::Experimental;
use Maps::Shared qw/:all MAPS_ICONS_DIR MAPS_ICONS_DIR_WEB_PATH LAYER_ID_BY_NAME CLOSE_OUTER_MODAL_SCRIPT/;

our ($db,
  $admin,
  %conf,
  $html,
  %lang,
  %permissions,
  $Nas
);

my $Address = Address->new( $db, $admin, \%conf );
require Control::Address_mng;

our ($Maps, @MAPS_CUSTOM_ICONS);
#**********************************************************
=head2 maps_route_types()

=cut
#**********************************************************
sub maps_route_types {
  my %TEMPLATE_ROUTE_TYPE = ();
  my $show_add_form = $FORM{add_form} || 0;
  
  if ( $FORM{add} ) {
    $Maps->route_types_add({ %FORM });
    $show_add_form = !show_result($Maps, $lang{ADDED});
  }
  elsif ( $FORM{change} ) {
    $Maps->route_types_change({ %FORM });
    show_result($Maps, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ( $FORM{chg} ) {
    my $tp_info = $Maps->route_types_info($FORM{chg});
    if ( !_error_show($Maps) ) {
      %TEMPLATE_ROUTE_TYPE = %{$tp_info ? $tp_info : { }};
      $show_add_form = 1;
    }
  }
  elsif ( $FORM{del} ) {
    $Maps->route_types_del({ ID => $FORM{del} });
    show_result($Maps, $lang{DELETED});
  }
  
  if ( $show_add_form ) {
    
    # Default line color is black
    $TEMPLATE_ROUTE_TYPE{COLOR} ||= '#ffffff';
    
    $html->tpl_show(
      _include('maps_route_types', 'Maps'),
      {
        %TEMPLATE_ROUTE_TYPE,
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }
  
  result_former(
    {
      INPUT_DATA      => $Maps,
      FUNCTION        => 'route_types_list',
      DEFAULT_FIELDS  => "ID,NAME,COLOR,FIBERS_COUNT",
      FUNCTION_FIELDS => 'change, del',
      EXT_TITLES      => {
        'name'         => $lang{NAME},
        'id'           => 'ID',
        'fibers_count' => $lang{FIBERS},
        'color'        => $lang{COLOR},
        'comments'     => $lang{COMMENTS}
      },
      FILTER_COLS     => { name => '_translate' },
      TABLE           => {
        width   => '100%',
        caption => "$lang{ROUTE} $lang{TYPES}",
        qs      => $pages_qs,
        ID      => 'MAPS_ROUTE_TYPES',
        header  => '',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1" . ':add',
      },
      MAKE_ROWS       => 1,
      SKIP_USER_TITLE => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Maps',
      TOTAL           => 1
    }
  );
}

#**********************************************************

=head2 maps_route_groups()

=cut

#**********************************************************
sub maps_route_groups {
  
  my %TEMPLATE_GROUP = ();
  my $show_add_form = $FORM{add_form} || 0;
  
  if ( $FORM{add} ) {
    $Maps->route_groups_add({ %FORM });
    $show_add_form = !show_result($Maps, $lang{ADDED});
  }
  elsif ( $FORM{change} ) {
    $Maps->route_groups_change({ %FORM });
    show_result($Maps, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ( $FORM{chg} ) {
    my $tp_info = $Maps->route_groups_info($FORM{chg});
    if ( !_error_show($Maps) ) {
      %TEMPLATE_GROUP = %{$tp_info ? $tp_info : { }};
      $show_add_form = 1;
    }
  }
  elsif ( $FORM{del} ) {
    $Maps->route_groups_del({ ID => $FORM{del} });
    show_result($Maps, $lang{DELETED});
  }
  
  if ( $show_add_form ) {
    
    my %deleting_self_if_presented_option = (ID => '_SHOW');
    if ( $FORM{chg} ) {
      $deleting_self_if_presented_option{ID} = '!' . $FORM{chg};
    }
    
    $TEMPLATE_GROUP{PARENT_GROUP} = $html->form_select(
      'PARENT_ID',
      {
        SELECTED    => $FORM{PARENT_ID} || $TEMPLATE_GROUP{PARENT_ID} || '',
        SEL_LIST    => $Maps->route_groups_list({ NAME => '_SHOW', %deleting_self_if_presented_option, COLS_NAME => 1 })
        ,
        NO_ID       => 1,
        SEL_OPTIONS => { '' => '' },
      }
    );
    
    $html->tpl_show(
      _include('maps_route_groups', 'Maps'),
      {
        %TEMPLATE_GROUP,
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }
  
  result_former(
    {
      INPUT_DATA      => $Maps,
      FUNCTION        => 'route_groups_list',
      DEFAULT_FIELDS  => "ID,NAME,COMMENTS,PARENT_NAME",
      FUNCTION_FIELDS => 'change, del',
      EXT_TITLES      => {
        'name'        => $lang{NAME},
        'id'          => 'ID',
        'comments'    => $lang{COMMENTS},
        'parent_name' => $lang{PARENT_F},
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{ROUTE} $lang{GROUPS}",
        qs      => $pages_qs,
        ID      => 'MAPS_ROUTE_GROUPS',
        header  => '',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1" . ':add',
      },
      MAKE_ROWS       => 1,
      SKIP_USER_TITLE => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Maps',
      TOTAL           => 1
    }
  );
  
  print $html->tree_menu($Maps->route_groups_list({ ID => '_SHOW', 'NAME' => '_SHOW', 'PARENT_ID' => '_SHOW' }),
    $lang{GROUPS}, { COL_SIZE => 12 });
}

#**********************************************************
=head2 maps_show_custom_point_form() - Show form for adding point

=cut
#**********************************************************
sub maps_show_custom_point_form {
  my %attrs = ();
  my $max_id_hash = $Maps->points_max_ids_for_types();
  
  if ( $FORM{CLOSEST_BUILDS} ) {
    $attrs{HAS_CLOSEST} = 1;
    my $closest_builds_list = $Address->build_list( {
      LOCATION_ID   => $FORM{CLOSEST_BUILDS},
      DISTRICT_NAME => '_SHOW',
      STREET_NAME   => '_SHOW',
      COLS_NAME     => 1,
    } );
    _error_show($Address);
    
    my @address_list = ();
    for my $build ( @{$closest_builds_list} ) {
      my $full_address = qq{ $build->{district_name}, $build->{street_name}, $build->{number} };
      push @address_list, { id => $build->{id}, name => $full_address };
    }
    
    $attrs{CLOSEST_SELECT} = $html->form_select( 'CLOSEST_LOCATION_ID', {
        SEL_LIST    => \@address_list,
        NO_ID       => 1,
        SEL_OPTIONS => { '' => '' }
      } )
  }
  
  my $address_sel = $html->tpl_show( templates('form_show_hide'), {
      NAME    => $lang{ADDRESS},
      CONTENT => $html->tpl_show( templates('form_address_build_sel'), { }, { OUTPUT2RETURN => 1 } ),
      PARAMS  => $attrs{HAS_CLOSEST} ? 'collapsed-box' : ''
    }, { OUTPUT2RETURN => 1 });
  
  $html->tpl_show(
    _include('maps_add_custom_point', 'Maps'),
    {
      LAST_IDS        => JSON::to_json($max_id_hash, { utf8 => 0 }),
      TYPE_ID_SELECT  => _maps_object_types_select({ OUTPUT2RETURN => 1 }),
      COORDX          => $FORM{COORDX},
      COORDY          => $FORM{COORDY},
      TYPES_PAGE_HREF => $SELF_URL . '?index=' . get_function_index('maps_point_types_main'),
      ADDRESS_SEL     => $address_sel,
      %attrs
    }
  );
  #  }
  
  return 1;
}

#**********************************************************
=head2 maps_districts_main()

=cut
#**********************************************************
sub maps_districts_main {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;
  
  if ($FORM{add}) {
    my $new_point_id = maps_add_external_object(LAYER_ID_BY_NAME->{DISTRICT}, \%FORM);
    show_result($Maps, $lang{ADDED} . ' ' . $lang{OBJECT});
    $FORM{OBJECT_ID} = $new_point_id;
    
    $Maps->districts_add({%FORM});
    $show_add_form = show_result($Maps, $lang{ADDED});
    
    if ($FORM{RETURN_FORM} && $html->{TYPE} eq 'json'){
      foreach (split(',\s?', $FORM{RETURN_FORM})){
        push (@{ $html->{JSON_OUTPUT} }, {
            $_ => '"' . ( $FORM{$_} || q{} ) . '"'
          });
      }
    }
  }
  elsif ($FORM{change}) {
    $Maps->districts_change({%FORM});
    show_result($Maps, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{del}) {
    $Maps->districts_del({}, { district_id => $FORM{del} });
    show_result($Maps, $lang{DELETED});
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Maps->districts_info($FORM{chg});
    if (!_error_show($Maps)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }
  
  return 1 if ($FORM{MESSAGE_ONLY});
  
  if ($show_add_form) {
    $TEMPLATE_ARGS{DISTRICT_ID_SELECT} = sel_districts({ DISTRICT_ID => $TEMPLATE_ARGS{DISTRICT_ID} });
    $TEMPLATE_ARGS{COLOR} ||= '#ffffff';
    
    $html->tpl_show(
      _include('maps_district', 'Maps'),
      {
        %TEMPLATE_ARGS,
        %FORM,
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }
  
  return 1 if ($FORM{TEMPLATE_ONLY});
  
  my Abills::HTML $table; ($table) = result_former({
    INPUT_DATA      => $Maps,
    FUNCTION        => 'districts_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'DISTRICT_ID,DISTRICT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      district_id       => '#',
      district     => $lang{DISTRICT},
      object_id     => $lang{MAP},
    },
    FILTER_VALUES => {
      # RESULT FORMER doesn't support naming of key field, so just copy existing value to 'id'
      district_id => sub {
        my ($district_id, $line) = @_;
        $line->{id} = $district_id;
        return $district_id;
      }
    },
    FILTER_COLS     => {
      #      type   => '_translate',
      #      point_id => '_maps_result_former_show_custom_point_on_map_btn:ID:ID,COORDX'
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DISTRICTS},
      ID      => 'DISTRICTS_TABLE'
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Maps',
  });
  
  print $table->show();
  
  return 1;
}

#**********************************************************
=head2 maps_objects_main()

=cut
#**********************************************************
sub maps_objects_main {
  
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;
  my $qs = '';
  
  # Every object linked to address can add new address
  if ( $FORM{ADD_ADDRESS_BUILD} && $FORM{STREET_ID} ) {
    $Address->build_add( { %FORM } );
    if ( !_error_show($Address) ) {
      $FORM{LOCATION_ID} = $Address->{INSERT_ID};
    }
  }
  
  if ( $FORM{add} ) {
    if ( $FORM{PLANNED} ) {
      $FORM{CREATED} = '0000-00-00 00:00:00';
    }
    $Maps->points_add( { %FORM } );
    $show_add_form = !show_result( $Maps, $lang{ADDED} );
  }
  elsif ( $FORM{change} ) {
    $Maps->points_change( { %FORM } );
    show_result( $Maps, $lang{CHANGED} );
    $show_add_form = 1;
  }
  elsif ( $FORM{chg} ) {
    
    my $tp_info = $Maps->points_info( $FORM{chg} );
    if ( !_error_show($Maps) ) {
      
      # Get all linked objects
      my $children = $Maps->points_list({
        PARENT_ID => $FORM{chg},
        TYPE      => '_SHOW',
        NAME      => '_SHOW',
      });
      _error_show($Maps);
      my @links = map {
        $html->button($_->{name}, "index=$index&chg=$_->{id}", { });
      } @{$children};
      
      # Quick add link
      $tp_info->{id} //= '';
      $tp_info->{name} //= '';
      $tp_info->{location_id} //= '';
      my $params_to_send = join('&',
        "PARENT_ID=$tp_info->{id}",
        "LOCATION_ID=$tp_info->{location_id}",
      );
      
      push(@links, $html->button( $lang{ADD}, "index=$index&add_form=1&$params_to_send" ));
      
      my $map_btn = _maps_result_former_show_custom_point_on_map_btn( undef, {
          VALUES => { ID => $tp_info->{id} }
        });
      
      %TEMPLATE_ARGS = %{$tp_info};
      $TEMPLATE_ARGS{CHILDREN_LINKS} = join('<br/>', @links);
      $TEMPLATE_ARGS{SHOW_MAP_BTN} = 1;
      $TEMPLATE_ARGS{MAP_BTN} = $map_btn;
      
      # Inverting 'planned' to show 'installed'
      $TEMPLATE_ARGS{PLANNED_SELECT} = $html->form_select('PLANNED', {
          SELECTED => $tp_info->{planned},
          SEL_HASH => {
            0 => $lang{YES},
            1 => $lang{NO}
          },
          NO_ID => 1
        });
      
      
      $show_add_form = 1;
    }
  }
  elsif ( $FORM{del} ) {
    $Maps->points_del( { ID => $FORM{del} } );
    _maps_object_delete($FORM{del});
    
    show_result( $Maps, $lang{DELETED} );
  }
  
  if ( $FORM{MESSAGE_ONLY} ) {
    if ( $FORM{IN_MODAL} ) {
      print CLOSE_OUTER_MODAL_SCRIPT;
    }
    return 1;
  }
  
  if ( $show_add_form || $FORM{search_form} ) {
    $TEMPLATE_ARGS{TYPE_ID_SELECT} = _maps_object_types_select({ SELECTED => $TEMPLATE_ARGS{TYPE_ID}, OUTPUT2RETURN => 1 });
    
    $TEMPLATE_ARGS{PARENT_ID_SELECT} = _maps_parent_object_select({
      PARENT_ID   => $TEMPLATE_ARGS{PARENT_ID},
      LOCATION_ID => $TEMPLATE_ARGS{LOCATION_ID} || '_SHOW',
      
      # Exclude this object id from selection as parent
      ID          => ($TEMPLATE_ARGS{ID} ? ('!' . $TEMPLATE_ARGS{ID}) : '_SHOW'),
    });
  }
  
  if ( $show_add_form ) {
    
    my %address_params = ();
    if ( $TEMPLATE_ARGS{LOCATION_ID} || $FORM{LOCATION_ID} ) {
      my $build_list = $Address->build_list( {
        LOCATION_ID   => $TEMPLATE_ARGS{LOCATION_ID} || $FORM{LOCATION_ID},
        DISTRICT_NAME => '_SHOW',
        DISTRICT_ID   => '_SHOW',
        STREET_NAME   => '_SHOW',
        STREET_ID     => '_SHOW',
        COLS_UPPER    => 1,
        COLS_NAME     => 1
      } );
      _error_show($Address);
      
      %address_params = (
        %{$build_list->[0]},
        ADDRESS_DISTRICT => $build_list->[0]->{DISTRICT_NAME},
        ADDRESS_STREET   => $build_list->[0]->{STREET_NAME},
        ADDRESS_BUILD    => $build_list->[0]->{NUMBER}
      );
    }
    
    $TEMPLATE_ARGS{LAST_IDS} = JSON::to_json($Maps->points_max_ids_for_types(), { utf8 => 0 });
    
    if ($FORM{IN_MODAL}){
      $TEMPLATE_ARGS{FORM_SUBMIT} = 'ajax-submit-form';
    }
    
    $html->tpl_show( _include('maps_object', 'Maps'), {
        %TEMPLATE_ARGS,
        ADDRESS_SEL       => $html->tpl_show(templates('form_address_build_sel'), \%address_params,
          { OUTPUT2RETURN => 1, ID => 'form_address_build_sel' }),
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }
  elsif ( $FORM{search_form} ) {
    form_search({ SEARCH_FORM => $html->tpl_show(_include('maps_object_search', 'Maps'),
        { %FORM, %TEMPLATE_ARGS, },
        { OUTPUT2RETURN => 1 }),
      ADDRESS_FORM            => 1,
      PLAIN_SEARCH_FORM       => 1
    });
  }
  else {
    my $type_select = _maps_object_types_select({
      AUTOSUBMIT    => 'form',
      SEL_OPTIONS   => { '' => $lang{ALL} },
      EX_PARAMS     => '',
      OUTPUT2RETURN => 1,
    });
    
    my $planned_input = $html->form_input( 'PLANNED', 1, {
        TYPE      => 'checkbox',
        STATE     => $FORM{PLANNED},
        ex_params => 'data-return="1"',
      } );
    
    $html->tpl_show( _include('maps_objects_filter_panel', 'Maps'), {
        TYPE_SELECT      => $type_select,
        PLANNED_CHECKBOX => $planned_input
      } );
    
    if ( $FORM{TYPE_ID} ) {
      $LIST_PARAMS{TYPE_ID} = $FORM{TYPE_ID};
      $qs .= "&TYPE_ID=$FORM{TYPE_ID}";
    }
    
    if ( $FORM{PLANNED} ) {
      $LIST_PARAMS{CREATED} = '0000-00-00 00:00:00';
      $qs .= "&PLANNED=$FORM{PLANNED}";
    }
  }
  
  return 1 if ($FORM{TEMPLATE_ONLY});
  
  my Abills::HTML $table; ($table) = result_former({
    INPUT_DATA      => $Maps,
    FUNCTION        => 'points_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,TYPE,CREATED,COORDX,COMMENTS',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id       => '#',
      name     => $lang{NAME},
      type     => $lang{TYPE},
      comments => $lang{COMMENTS},
      created  => $lang{CREATED},
      coordx   => $lang{MAP},
    },
    FILTER_COLS     => {
      type   => '_translate',
      coordx => '_maps_result_former_show_custom_point_on_map_btn:ID:ID,COORDX'
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{OBJECTS},
      ID      => 'OBJECTS_TABLE',
      qs      => $qs,
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add" . ";$lang{SEARCH}:index=$index&search_form=1:search"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Maps',
  });
  
  print $table->show();
  
  return 1;
}

#**********************************************************
=head2 filter_panel($attr)

  Arguments:
    $attr - hash_ref
      TITLES     - hash_ref of COLUMN_NAMES and TYPES
      EXT_TITLES - hash_ref of column_names and translation

  Returns:
    $html

  Example:

  filter_panel({
      COLUMNS => {
        ID        => 'INT',
        NAME      => 'STR',
        TYPE_NAME => [ '$lang{BUILD}', '$lang{ROUTE}', '$lang{USER}' ],
        CREATED   => 'DATE',
      },
      EXT_TITLES => {
        id        => 'ID',
        name      => $lang{NAME},
        type_name => $lang{TYPE},
        comments  => $lang{COMMENTS},
        created   => $lang{CREATED},
      }
    });

=cut
#**********************************************************
sub filter_panel {
  my ($attr) = @_;
  
  my @titles = sort keys %{$attr->{COLUMNS}};
  my @translated_titles = map { $attr->{EXT_TITLES}->{lc $_} } @titles;
  
  my $select = $html->form_select('filter_columns', {
      SEL_ARRAY    => \@translated_titles,
      ARRAY_NUM_ID => 1,
    });
  
  my $filter_json = JSON::to_json( $attr->{COLUMNS}, { utf8 => 0 } );
  
  $html->tpl_show( templates('form_filter_panel'), {
      SELECT       => $select,
      FILTERS_JSON => $filter_json
    } );
  
  return 1;
}

#**********************************************************
=head2 maps_point_types_main()

=cut
#**********************************************************
sub maps_point_types_main {
  
  my $show_template = 0;
  my $Maps_obj = { };
  
  if ( $FORM{show_add_form} ) {
    $show_template = 1;
  }
  elsif ( $FORM{chg} ) {
    $Maps_obj = $Maps->point_types_info($FORM{chg});
    _error_show($Maps);
    $Maps_obj->{CHANGE_ID} = "ID";
    $show_template = 1;
  }
  elsif ( $FORM{add} ) {
    $Maps->point_types_add(\%FORM);
    show_result($Maps, $lang{ADDED});
  }
  elsif ( $FORM{change} ) {
    $Maps->point_types_change(\%FORM);
    show_result($Maps, $lang{CHANGED});
  }
  elsif ( $FORM{del} ) {
    $Maps->point_types_del({ ID => $FORM{del} });
    _error_show($Maps);
    
    show_result( $Maps, $lang{DELETED} );
  }
  
  if ( $show_template ) {
    my @map_icons = qw(
      build_green.png
      nas_green.png
      wifi_green.png
      well_green.png
      route_green.png
      equipment_green.png
      cable_green.png
      splitter_green.png
      muff_green.png
      );
    
    my $user_defined_map_icons = $Maps->icons_list({ NAME => '_SHOW', FILENAME => '_SHOW' });
    
    if ( $user_defined_map_icons && ref $user_defined_map_icons eq 'ARRAY' ) {
      push @map_icons, map { $_->{filename} } @{$user_defined_map_icons};
    }
    
    if ( @MAPS_CUSTOM_ICONS && scalar @MAPS_CUSTOM_ICONS > 0 ) {
      push @map_icons, @MAPS_CUSTOM_ICONS;
    }
    
    my $icon_select = $html->form_select(
      'ICON',
      {
        SELECTED  => $Maps_obj->{ICON},
        SEL_ARRAY => \@map_icons,
        NO_ID     => 1,
        ID        => 'ICON_SELECT'
      }
    );
    
    my $add_icon_link = $html->button( '', 'index=' . get_function_index('maps_icons_main') . '&add_form=1', {
        ICON      => 'glyphicon glyphicon-plus',
        ID        => 'ADD_ICON_BUTTON',
        class     => 'btn btn-success',
        ex_params => ' target="_blank" '
      } );
    
    $html->tpl_show(
      _include('maps_point_types', 'Maps'),
      {
        %{$Maps_obj},
        MAPS_ICONS_WEB_DIR => MAPS_ICONS_DIR_WEB_PATH,
        ICON_SELECT        => $icon_select,
        ADD_ICON_BUTTON    => $add_icon_link,
        SUBMIT_BTN_NAME    => ($FORM{chg}) ? $lang{CHANGE_} : $lang{ADD},
        SUBMIT_BTN_ACTION  => ($FORM{chg}) ? "change" : "add"
      }
    );
  }
  
  # TODO: show icon images
  my Abills::HTML $table; ($table) = result_former({
    INPUT_DATA      => $Maps,
    FUNCTION        => 'point_types_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,ICON,COMMENTS',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id       => 'ID',
      name     => $lang{NAME},
      icon     => $lang{ICON},
      comments => $lang{COMMENTS}
    },
    FILTER_COLS     => {
      name => '_translate'
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{OBJECT_TYPES}",
      ID      => 'OBJECT_TYPE_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&show_add_form=1:add"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Maps',
  });
  
  print $table->show();
  
  return 1;
}

#**********************************************************
=head2 maps_icons_main()

=cut
#**********************************************************
sub maps_icons_main {
  my %TEMPLATE_ICON = ();
  my $show_add_form = $FORM{add_form} || 0;
  
  if ( $FORM{add} ) {
    $Maps->icons_add( { %FORM } );
    $show_add_form = !show_result( $Maps, $lang{ADDED} );
  }
  elsif ( $FORM{change} ) {
    $Maps->icons_change( { %FORM } );
    show_result( $Maps, $lang{CHANGED} );
    $show_add_form = 1;
  }
  elsif ( $FORM{chg} ) {
    my $tp_info = $Maps->icons_info( $FORM{chg} );
    if ( !_error_show($Maps) ) {
      %TEMPLATE_ICON = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ( $FORM{del} ) {
    $Maps->icons_del( { ID => $FORM{del} } );
    show_result( $Maps, $lang{DELETED} );
  }
  
  my $open_upload_modal_btn = $html->button('UPLOAD', "get_index=_maps_icon_ajax_upload\&header=2", {
      ICON          => 'glyphicon glyphicon-upload',
      LOAD_TO_MODAL => 1,
      class         => 'btn btn-success',
      ID            => 'UPLOAD_BUTTON',
    });
  
  if ( $show_add_form ) {
    $html->tpl_show(
      _include('maps_icon', 'Maps'),
      {
        %TEMPLATE_ICON,
        MAPS_ICONS_WEB_DIR => MAPS_ICONS_DIR_WEB_PATH,
        FILENAME_SELECT    => _maps_icon_filename_select(\%TEMPLATE_ICON) || "$lang{NO_ICONS} $lang{IN} MAPS_ICONS_DIR"
        ,
        UPLOAD_BTN         => $open_upload_modal_btn,
        SUBMIT_BTN_ACTION  => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME    => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }
  
  my Abills::HTML $table; ($table) = result_former({
    INPUT_DATA      => $Maps,
    FUNCTION        => 'icons_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,PATH,COMMENTS',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id       => '#',
      name     => $lang{NAME},
      path     => $lang{PATH},
      comments => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{ICONS},
      ID      => 'ICONS_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Maps',
  });
  
  print $table->show();
}

#**********************************************************
=head2 _maps_icon_ajax_upload()

=cut
#**********************************************************
sub _maps_icon_ajax_upload {
  return unless ($FORM{IN_MODAL});
  
  if ( !$FORM{UPLOAD_FILE} ) {
    $html->tpl_show( _include('maps_icon_ajax_upload_form', 'Maps'), {
        CALLBACK_FUNC => '_maps_icon_ajax_upload',
        TIMEOUT       => '0',
      } );
    return 1;
  }
  
  # Remove TPL_DIR part
  my $upload_path = MAPS_ICONS_DIR;
  $upload_path =~ s/\/Abills\/templates\///g;
  
  my $uploaded = upload_file($FORM{UPLOAD_FILE}, {
      PREFIX     => $upload_path,
      EXTENTIONS => 'jpg,jpeg,png,gif'
    });
  
  if ( $uploaded ) {
    $html->message('info', $lang{SUCCESS});
  }
  
  return 1;
}


#**********************************************************

=head2 maps_route_add($attr)

=cut

#**********************************************************
sub maps_route_add {
  
  #my ($attr) = @_;
  
  $Maps->{ACTION} = 'add';
  $Maps->{ACTION_LNG} = $lang{ADD};
  
  if ( $FORM{add} ) {
    if ( $FORM{NAME} ) {
      $Maps->routes_add({ %FORM });
      if ( !$Maps->{errno} ) {
        $html->message('info', $lang{INFO}, "$lang{ADDED}");
      }
    }
    else {
      $html->message('info', $lang{INFO}, "$lang{FIELDS_FOR_NAME_ARE_REQUIRED}");
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ) {
    $Maps->routes_del({ ID => $FORM{del} });
    if ( !$Maps->{errno} ) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }
  elsif ( $FORM{change} ) {
    if ( $FORM{NAME} ) {
      $Maps->routes_change({ %FORM });
      
      if ( !$Maps->{errno} ) {
        $html->message('info', $lang{INFO}, "$lang{CHANGED}");
        $Maps->{ACTION} = 'change_route';
        $Maps->{ACTION_LNG} = $lang{CHANGE};
      }
    }
    else {
      $html->message('info', $lang{INFO}, "$lang{FIELDS_FOR_NAME_ARE_REQUIRED}");
    }
  }
  elsif ( $FORM{chg} ) {
    $Maps->{ACTION} = 'change';
    $Maps->{ACTION_LNG} = $lang{CHANGE};
    $Maps->route_info({ ID => $FORM{chg} });
    
    if ( !$Maps->{errno} ) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
    }
  }
  
  my $list = $Nas->list(
    {
      LOCATION_ID => "!",
      PAGE_ROWS   => '1000',
      COLS_NAME   => 1
    }
  );
  
  $Maps->{NAS1_SEL} = $html->form_select(
    'NAS1',
    {
      SELECTED       => $Maps->{NAS1} || $FORM{NAS1} || q{},
      SEL_LIST       => $list,
      SEL_KEY        => 'nas_id',
      SEL_VALUE      => 'nas_name',
      MAIN_MENU      => get_function_index('form_nas'),
      MAIN_MENU_ARGV => "chg=" . ($FORM{NAS_ID} || q{})
    }
  );
  
  $Maps->{NAS2_SEL} = $html->form_select(
    'NAS2',
    {
      SELECTED       => $Maps->{NAS2} || $FORM{NAS2} || q{},
      SEL_LIST       => $list,
      SEL_KEY        => 'nas_id',
      SEL_VALUE      => 'nas_name',
      MAIN_MENU      => get_function_index('form_nas'),
      MAIN_MENU_ARGV => "chg=" . ($FORM{NAS_ID} || q{})
    }
  );
  
  $Maps->{TYPES} = $html->form_select(
    "TYPE",
    {
      SELECTED => $Maps->{TYPE} || $FORM{TYPE},
      SEL_LIST => translate_list_value($Maps->route_types_list({ COLS_NAME => 1, ID => '_SHOW', NAME => '_SHOW' })),
      NO_ID    => 1,
    }
  );
  
  my %deleting_self_if_presented_option = (ID => '_SHOW');
  if ( $FORM{chg} ) {
    $deleting_self_if_presented_option{ID} = '!' . $FORM{chg};
  }
  
  $Maps->{PARENT_ROUTE_ID} = $html->form_select(
    'PARENT_ID',
    {
      SELECTED    => $FORM{PARENT_ID} || $Maps->{PARENT_ID} || '',
      SEL_LIST    =>
      $Maps->routes_list({ NAME => '_SHOW', NAS1 => '_SHOW', NAS2 => '_SHOW', %deleting_self_if_presented_option,
        COLS_NAME               => 1 }),
      NO_ID       => 1,
      SEL_VALUE   => 'name,nas1,nas2',
      SEL_OPTIONS => { '' => '' },
      MAIN_MENU   => get_function_index('maps_routes_list'),
    }
  );
  
  $Maps->{GROUP_ID} = $html->form_select(
    'GROUP_ID',
    {
      SELECTED    => $FORM{GROUP_ID} || $Maps->{GROUP_ID} || '',
      SEL_LIST    => $Maps->route_groups_list({ NAME => '_SHOW', COLS_NAME => 1 }),
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' },
      MAIN_MENU   => get_function_index('maps_route_groups'),
    }
  );
  
  $html->tpl_show(_include('maps_add_route', 'Maps'), { %FORM, %{$Maps} });
  
  return 1;
}


#**********************************************************

=head2 maps_routes_list()

=cut

#**********************************************************
sub maps_routes_list {
  
  #my ($attr) = @_;
  
  if ( $FORM{add_form} || $FORM{route} ) {
    maps_route_add();
  }
  
  result_former(
    {
      INPUT_DATA      => $Maps,
      FUNCTION        => 'routes_list',
      DEFAULT_FIELDS  => 'ID, NAME, TYPE_NAME, NAS1, NAS2, LENGTH, PARENT_ID, GROUP_NAME, POINTS',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        name         => $lang{NAME},
        type_name    => $lang{TYPE},
        descr        => $lang{DESCRIBE},
        length       => $lang{LENGTH},
        nas1         => "$lang{NAS} 1",
        nas2         => "$lang{NAS} 2",
        nas1_port    => "$lang{NAS} 1 $lang{PORT}",
        nas2_port    => "$lang{NAS} 2 $lang{PORT}",
        points       => $lang{MAPS},
        fibers_count => $lang{FIBERS},
        color        => $lang{COLOR},
        parent_id    => $lang{ROUTE},
        group_name   => $lang{GROUP},
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{ROUTES}",
        qs      => $pages_qs . "&route=1",
        ID      => 'EXCHANGE_RATE',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
      },
      FILTER_COLS     => {
        points    => 'form_add_map:ID:ID,COORDX,POINTS,add=1',
        type_name => '_translate',
        nas1      => '_maps_result_former_nas_id_filter',
        nas2      => '_maps_result_former_nas_id_filter',
        parent_id => '_maps_result_former_parent_route_id_filter'
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      TOTAL           => 1
    }
  );
  
  # Not using result former return $list because of incomplete columns
  my $routes_list = $Maps->routes_list({ ID => '_SHOW', 'NAME' => '_SHOW', 'PARENT_ID' => '_SHOW', COLS_NAME => 1,
    COLS_UPPER                              => 1 });
  print $html->tree_menu($routes_list, $lang{ROUTES}, { COL_SIZE => 12 });
  
  return 1;
}


#**********************************************************
=head2 maps_builds_quick()

=cut
#**********************************************************
sub maps_builds_quick {
  
  my $can_check_online = 0;
  my %location_is_online = ();
  
  my $Sessions;
  if (in_array('Internet', \@MODULES)) {
    $can_check_online = 1;
    require Internet::Sessions;
    Internet::Sessions->import();
    $Sessions = Internet::Sessions->new($db, $admin, \%conf);
  
    # Get online
    my $online_list = $Sessions->online({
      UID       => '_SHOW',
      COLS_NAME => 1
    });
    _error_show($Sessions) and return 0;
  
    # Get location_ids for users
    my $builds_for_users = $users->list({
      UID         => join(';', map {$_->{uid}} @{$online_list}),
      LOCATION_ID => '!',
      COLS_NAME   => 1
    });
    _error_show($users) and return 0;
  
    # Create online lookup_table
    foreach ( @{$builds_for_users} ) {
      $location_is_online{$_->{build_id}} = 1;
    }
  }
  
  my $districts_list = $Address->district_list( {
    COLS_NAME => 1,
    SORT      => 'd.name',
    PAGE_ROWS => 10000
  } );
  return if (_error_show($Address));
  
  foreach my $district ( @{$districts_list} ) {
    # Get all streets
    my $streets_list = $Address->street_list( {
      DISTRICT_ID => $district->{id},
      STREET_NAME => '_SHOW',
      SECOND_NAME => '_SHOW',
      COLS_NAME   => 1,
      SORT        => 's.name',
      PAGE_ROWS   => 10000
    } );
    return if (_error_show($Address));
    
    my $streets_content = '';
    foreach my $street ( @{$streets_list} ) {
      my $builds_list = $Address->build_list( {
        STREET_ID => $street->{id},
        COLS_NAME => 1,
        SORT      => 1,
        PAGE_ROWS => 10000
      } );
      return if (_error_show($Address));
      
      my $builds_content = '';
      foreach my $build ( @{$builds_list} ) {
        
        my $has_online = ($can_check_online
          && exists $location_is_online{$build->{id}}
          && $location_is_online{$build->{id}}
        );
        
        $builds_content .= $html->button( $build->{number},
          "index=7&type=11&search=1&search_form=1&LOCATION_ID=$build->{id}&BUILDS=$street->{id}", {
            class         => 'btn btn-lg ' .
              (
                ( !$can_check_online )
                  ? 'btn-primary'
                  : $has_online
                    ? 'btn-success'
                    : 'btn-warning'
              ),
            OUTPUT2RETURN => 1
          } );
        
      }
      
      $streets_content .= $html->tpl_show( templates('form_show_hide'), {
          NAME    => $street->{street_name}
            . ( $street->{second_name} ? " ( $street->{second_name} ) " : '' )
            . ' ( ' . (scalar @{$builds_list}) . ' )',
          CONTENT => '<div class="button-block">' . $builds_content . '</div>',
          PARAMS  => 'collapsed-box'
        },
        {
          OUTPUT2RETURN => 1
        } );
    }
    
    $html->tpl_show( templates('form_show_hide'), {
        NAME    => $lang{DISTRICT} . ' ' . $district->{name} . ' ( ' . (scalar @{$streets_list}) . ' )',
        CONTENT => $streets_content,
        PARAMS  => 'collapsed-box'
      } )
  };

  return 1;
}


#**********************************************************
=head2 maps_auto_coords()

=cut
#**********************************************************
sub maps_auto_coords {
  
  # Preparation
  require Maps::GMA;
  Maps::GMA->import();
  my $GMA = Maps::GMA->new($db, $admin, \%conf);
  
  my $maps_index = get_function_index('maps_edit');
  my $single_build_index = get_function_index('maps_auto_coords_single');
  
  my $builds_list = $GMA->get_unfilled_addresses(\%FORM);
  
  if ( $FORM{header} && $FORM{GET_UNFILLED_ADDRESSES} ) {
    #    print "Content-Type: application/json\n\n";
    print JSON::to_json($builds_list, { utf8 => 0 });
    return 1;
  }

  # Show form with parameters
  $html->tpl_show(
    _include('maps_gma_form', 'Maps'),
    {
      COUNTRY_ABBR                   => $FORM{COUNTRY_ABBR} || 'UA',
      DISTRICTS_ARE_NOT_REAL_CHECKED => $FORM{DISTRICTS_ARE_NOT_REAL},
      STREET_SELECT                  => sel_streets({ SEL_OPTIONS => { '' => '' }, MAIN_MENU => 0 }),
      DISTRICT_SELECT                => sel_districts({ }),
    }
  );
  
  my $builds_to_process = scalar @{$builds_list};
  if ( $builds_to_process < 1 ) {
    $html->message('warn', $lang{BUILDS}, $lang{NO_RECORD});
    return 0;
  }
  
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{AUTO_COORDS},
      border     => 1,
      title      => [ '#', $lang{ADDRESS}, $lang{STATUS}, $lang{MAPS} ],
      qs         => $pages_qs,
      ID         => 'GMA_TABLE_ID'
    }
  );
  
  foreach my $build ( @{$builds_list} ) {
    my $manual_add_btn = $html->button('add', "index=$maps_index&LOCATION_ID=$build->{id}&LOCATION_TYPE=BUILD",
      { class => 'add', target => '_blank' });
    $table->addrow($build->{id}, $build->{full_address}, '', ($build->{coordx}) ? $manual_add_btn : $lang{YES});
  }
  
  print $table->show();
  
  my $builds_json = JSON::to_json($builds_list, { utf8 => 0 });
  
  print "<script>var builds_for_auto_coords = $builds_json ; var single_coord_index = '$single_build_index'</script>";
  
  return 1;
}

#**********************************************************

=head2 maps_auto_coords_single() - single build request to make AJAX operations possible

=cut

#**********************************************************
sub maps_auto_coords_single {
  return 0 unless ($FORM{REQUEST_ADDRESS});
  
  # Preparation
  require Maps::GMA;
  Maps::GMA->import();
  my $GMA = Maps::GMA->new($db, $admin, \%conf);
  
  # Parse input
  my $build_id = $FORM{BUILD_ID};
  my $requested_address = $FORM{REQUEST_ADDRESS};
  
  return 0 unless ($build_id);
  
  # Send request
  my $coords = $GMA->get_coords_for($requested_address, $build_id, { ZIP_CODE => ($FORM{ZIP_CODE} && !$conf{MAPS_GMA_SKIP_ZIPCODE}) });
  
  my $status = $coords->{STATUS};
  
  ### Show result ###
  
  my %NAME_FOR_STATUS = (
    1 => $lang{SUCCESS},
    2 => $lang{ERR_ZERO_RESULTS},
    3 => $lang{ERR_NOT_ONLY_RESULT},
    4 => $lang{ERR_NOT_EXACT_RESULT},
  );
  
  my $maps_index = get_function_index('maps_edit');
  
  my %responce = (
    status         => $status,
    message        => $NAME_FOR_STATUS{$status} || $lang{ERR_UNKNOWN},
    requested_id   => $build_id,
    requested_addr => $coords->{requested_address},
    add_index      => $maps_index
  );
  
  if ( $status == 500 ) {
    $responce{set_class} = 'danger';
    $responce{message} = $coords->{ERROR};
  }
  elsif ( $status == 1 ) {
    
    $Maps->changes(
      {
        TABLE        => 'builds',
        CHANGE_PARAM => 'ID',
        DATA         => {
          ID => $build_id,
          %{$coords}
        }
      }
    );
    
    $responce{set_class} = 'success';
    $responce{change_status} = ($Maps->{errno}) ? 1 : 0;
    
  }
  else {
    
    if ( $status == 2 ) {
      
      # Red and marked as non-acceptable
      $responce{set_class} = 'danger';
    }
    elsif ( $status == 3 ) {
      
      # Select from form
      $responce{set_class} = 'info';
      $responce{non_unique_results} = $coords->{RESULTS};
    }
    elsif ( $status == 4 ) {
      
      # Add using bounds
      $responce{set_class} = 'warning';
    }
    
  }
  
  my $json_responce = JSON::to_json(\%responce, { utf8 => 0 });
  
  print $json_responce;
  
  return 1;
}


#**********************************************************

=head2 _maps_result_former_nas_id_filter() - returns button to nas

=cut

#**********************************************************
sub _maps_result_former_nas_id_filter {
  my ($nas_id) = @_;
  return '' unless ( $nas_id );
  
  # Next block should be called only once
  # Not moving it to top level, to prevent loading every time
  state $nases_by_id = undef;
  if ( !$nases_by_id ) {
    my $nases_list = $Nas->list({ SHORT => 1, NAS_NAME => '_SHOW', NAS_ID => '_SHOW', COLS_NAME => 1 });
    _error_show($Nas);
    
    $nases_by_id = sort_array_to_hash($nases_list, 'nas_id');
  }
  
  my $nas = $nases_by_id->{$nas_id};
  return '' unless ( defined $nas );
  
  return $html->button($nas->{nas_name}, "index=62&NAS_ID=$nas->{nas_id}", {});
}

#**********************************************************

=head2 _maps_result_former_parent_route_id_filter()

=cut

#**********************************************************
sub _maps_result_former_parent_route_id_filter {
  my ($route_id) = @_;
  return '' unless ( $route_id );
  
  # Next block should be called only once
  # Not moving it to top level, to prevent loading every time
  state $routes_by_id = undef;
  if ( !$routes_by_id ) {
    my $routes_list = $Maps->routes_list({ ID => '_SHOW', NAME => '_SHOW', COLS_NAME => 1 });
    _error_show($Maps);
    
    $routes_by_id = sort_array_to_hash($routes_list);
  }
  
  my $route = $routes_by_id->{$route_id};
  return '' unless ( defined $route );
  
  return $html->button($route->{name}, "index=" . get_function_index('maps_routes_list') . "&NAS_ID=$route->{id}", {});
}


#**********************************************************
=head2 _maps_result_former_show_custom_point_on_map_btn()

=cut
#**********************************************************
sub _maps_result_former_show_custom_point_on_map_btn {
  my (undef, $attr) = @_;
  
  my $object_id = $attr->{VALUES}->{ID};
  my $custom_point_layer_id = LAYER_ID_BY_NAME->{CUSTOM_POINT} || '';
  
  return '' unless ( $object_id );
  
  # Next block should be called only once
  # Not moving it to top level, to prevent loading every time
  state $objects_by_id = undef;
  
  if ( !$objects_by_id ) {
    my $objects_list = $Maps->points_list({
      NAME        => '_SHOW',
      ID          => '_SHOW',
      ICON        => '_SHOW',
      COORDX      => '_SHOW',
      COORDY      => '_SHOW',
      TYPE_ID     => '_SHOW',
      LOCATION_ID => '_SHOW',
      COLS_NAME   => 1
    });
    _error_show($Maps);
    
    $objects_by_id = sort_array_to_hash($objects_list);
  }
  
  if ( $objects_by_id->{$object_id}->{type_id} && $objects_by_id->{$object_id}->{type_id} == 3 ) {
    return _maps_btn_for_build($objects_by_id->{$object_id}->{location_id});
  }
  
  if ( !$objects_by_id->{$object_id}->{coordx} ) {
    my $icon_attr = '';
    if ( defined $objects_by_id->{$object_id}->{icon} ) {
      my $icon_name = _maps_get_custom_point_icon($objects_by_id->{$object_id}->{icon});
      $icon_attr = "&ICON=$icon_name";
    }
    return $html->button('', "get_index=maps_edit&full=1&add=CUSTOM_POINT$icon_attr&OBJECT_ID=$object_id", {
        ICON => 'glyphicon glyphicon-plus'
      });
  };
  
  return $html->button('', "get_index=maps_edit&full=1&show_layer=$custom_point_layer_id&OBJECT_ID=$object_id",
    { ICON => 'glyphicon glyphicon-globe' }
  );
}



1;