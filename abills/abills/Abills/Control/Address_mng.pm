=head1 NAME

  Address Manage functions

=cut


use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array load_pmodule);
use Address;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  @bool_vals,
  $users
);

my $Address = Address->new( $db, $admin, \%conf );

#**********************************************************
=head2 form_districts()

=cut
#**********************************************************
sub form_districts{
  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{IMPORT} ){
    my @rows = split( /[\r\n]+/, $FORM{IMPORT}{Contents} );
    my %steets_ids = ();
    my $counts = 0;
    foreach my $line ( @rows ){
      my %info = ();
      ($info{STREET_NAME},
        $info{NUMBER},
        $info{FLORS},
        $info{ENTRANCES},
        $info{FLATS},
        $info{CONTRACT_ID},
        $info{CONTRACT_DATE},
        $info{CONTRACT_PRICE},
        $info{COMMENTS}
      ) = split( /\t/, $line );

      while(my (undef, $v) = each %info) {
        $v =~ s/^\"|\"$//g if($v);
      }

      #Get street id
      if ( !$steets_ids{$info{STREET_NAME}} ){
        my $list = $Address->street_list( {
          STREET_NAME => $info{STREET_NAME},
          COLS_NAME   => 1
        } );

        if ( $Address->{TOTAL} > 0 ){
          $info{STREET_ID} = $list->[0]->{id};
        }
        else{
          $Address->street_add( {
            NAME        => $info{STREET_NAME},
            DISTRICT_ID => $FORM{ID}
          } );

          if ( _error_show( $Address ) ){
            last;
          }

          $info{STREET_ID} = $Address->{INSERT_ID};
        }

        $steets_ids{$info{STREET_NAME}} = $info{STREET_ID};
      }
      else{
        $info{STREET_ID} = $steets_ids{$info{STREET_NAME}};
      }

      $Address->build_add( \%info );
      _error_show( $Address );

      $counts++;
    }
    $html->message( 'info', $lang{IMPORT}, "$lang{ADDED}: $counts" );
  }
  elsif ( $FORM{add} && $FORM{NAME} ){
    $Address->district_add( { %FORM } );

    if ( !$Address->{errno} ){
      if ( $FORM{FILE_UPLOAD} ){
        my $name = '';
        if ( $FORM{FILE_UPLOAD}{filename} && $FORM{FILE_UPLOAD}{filename} =~ /\.(\S+)$/i ){
          $name = $Address->{INSERT_ID} . '.' . lc( $1 );
        }
        upload_file( $FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 } );
      }

      $html->message( 'info', $lang{DISTRICT}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Address->district_change( \%FORM );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{DISTRICTS}, "$lang{CHANGED}" );
      if ( $FORM{FILE_UPLOAD} ){
        my $name = '';
        if ( $FORM{FILE_UPLOAD}{filename} && $FORM{FILE_UPLOAD}{filename} =~ /\.([a-z0-9]+)$/i ){
          $name = $FORM{ID} . '.' . lc( $1 );
        }

        upload_file( $FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 } );
      }
    }
  }
  elsif ( $FORM{chg} ){
    $Address->district_info( { ID => $FORM{chg} } );

    if ( !$Address->{errno} ){
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = "$lang{CHANGE}";
      $FORM{add_form} = 1;
      $html->message( 'info', $lang{DISTRICTS}, "$lang{CHANGING}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->district_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{DISTRICTS}, "$lang{DELETED}" );
    }
  }

  _error_show( $Address );

  my $countries_hash;
  ($countries_hash, $Address->{COUNTRY_SEL}) = sel_countries( { COUNTRY => $Address->{COUNTRY} } );

  if ( $FORM{add_form} ){
    $html->tpl_show( templates( 'form_district' ), $Address );
  }

  my $list = $Address->district_list( { %LIST_PARAMS, COLS_NAME => 1 } );
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{DISTRICTS},
      title      =>
      [ "#", $lang{NAME}, $lang{COUNTRY}, $lang{CITY}, $lang{ZIP}, $lang{STREETS}, $lang{MAP}, '-' ],
      ID         => 'DISTRICTS_LIST',
      FIELDS_IDS => $Address->{COL_NAMES_ARR},
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=$index&add_form=1:add",
    }
  );

  foreach my $line ( @{$list} ){
    my $map = $bool_vals[0];

    if ( in_array( 'Maps', \@MODULES ) ){
      $map = $html->button( '', "DISTRICT_ID=$line->{id}&ZOOM=16&index=" . get_function_index( 'maps_edit' ),
        { ICON => 'glyphicon glyphicon-globe' } );
    }

    $table->addrow(
      $line->{id},
      $line->{name},
      ($line->{country} && $countries_hash->{ $line->{country} })  ? $countries_hash->{ $line->{country} } : q{},
      $line->{city},
      $line->{zip},
      $html->button( $line->{street_count},
        "index=" . get_function_index( 'form_streets' ) . "&DISTRICT_ID=$line->{id}" ),
      $map,
      $html->button( $lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' } )
      .' '. $html->button( $lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} [$line->{id}] $line->{name}?", class => 'del' } )
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_streets() - Street list

=cut
#**********************************************************
sub form_streets{

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{BUILDS} ){
    form_builds();
    return 0;
  }
  elsif ( $FORM{add} ){
    $Address->street_add( { %FORM } );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Address->street_change( \%FORM );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Address->street_info( { ID => $FORM{chg} } );

    if ( !$Address->{errno} ){
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = "$lang{CHANGE}";
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{CHANGING}" );
      $FORM{add_form} = 1;
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->street_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_STREET}, "$lang{DELETED}" );
    }
  }
  _error_show( $Address );

  $Address->{DISTRICTS_SEL} = sel_districts({ DISTRICT_ID => $Address->{DISTRICT_ID} });

  if ( $FORM{add_form} ){
    if ($conf{STREET_TYPE}) {
      $Address->{STREET_TYPE_SELECT} = _street_type_select($Address->{TYPE});
      $Address->{STREET_TYPE_VISIBLE} = 1;
    }
    $html->tpl_show( templates( 'form_street' ), $Address );
  }

  if ( $FORM{DISTRICT_ID} ){
    $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID};
    $pages_qs .= "&DISTRICT_ID=$LIST_PARAMS{DISTRICT_ID}";
    $Address->district_info({ ID => $FORM{DISTRICT_ID} }) if(! $FORM{chg});
  }

  #$html->tpl_show(templates('form_street_search'), $Address);
  if($FORM{search_form}){
    form_search({ SEARCH_FORM => $html->tpl_show(templates('form_street_search'),
                                  { %$Address,  %FORM },
                                  { OUTPUT2RETURN => 1 }),
      PLAIN_SEARCH_FORM => 1});
  }

  if ( !$FORM{sort} ){
    $LIST_PARAMS{SORT} = 2;
  }

  my Abills::HTML $table;
  ($table) = result_former( {
    INPUT_DATA      => $Address,
    FUNCTION        => 'street_list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'ID,STREET_NAME,BUILD_COUNT,USERS_COUNT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      build_count => 'form_show_link:ID:ID,add=1',
      users_count => 'search_link:form_search:STREET_ID,type=11',
    },
    EXT_TITLES      => {
      street_name   => $lang{NAME},
      district_name => $lang{DISTRICT},
      second_name   => $lang{SECOND_NAME},
      build_count   => $lang{BUILDS},
      users_count   => $lang{USERS}
    },
    TABLE           => {
      caption => $lang{STREETS}.': '. ($Address->{NAME} || q{}),
      qs      => $pages_qs,
      ID      => 'STREETS_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&DISTRICT_ID=" . ($FORM{DISTRICT_ID} || '') . ":add; $lang{SEARCH}:index=$index&search_form=1&DISTRICT_ID=" . ($FORM{DISTRICT_ID} || '') . ":search",
      SHOW_COLS_HIDDEN => {
        DISTRICT_ID => $FORM{DISTRICT_ID}
      }
    },
    MAKE_ROWS       => 1,
  } );

  print $table->show();
  $table = $html->table(
    {
      rows       => [ [
        "$lang{STREETS}: " . $html->b( $Address->{TOTAL} ),
        "$lang{BUILDS}: " . $html->b( $Address->{TOTAL_BUILDS} || 0 ),
        "$lang{USERS}: " . $html->b( $Address->{TOTAL_USERS} || 0),
        "$lang{DENSITY_OF_CONNECTIONS}: " . $html->b( $Address->{DENSITY_OF_CONNECTIONS} || 0 )
      ] ]
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_builds() - Build managment

=cut
#**********************************************************
sub form_builds{

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = "$lang{ADD}";

  my $maps_enabled = in_array( 'Maps', \@MODULES );

  if ( !$FORM{qindex} && !$FORM{xml} && $FORM{BUILDS} ){
    my @header_arr = (
      "$lang{INFO}:index=$index&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? "&chg=$FORM{chg}" : ''),
      "Media:index=$index&media=1&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? "&chg=$FORM{chg}" : '')
    );

    print $html->table_header( \@header_arr, { TABS => 1 } );
  }

  if ( $FORM{media} ){
    form_location_media();
    return 1;
  }

  if ( $FORM{add} ){
    $Address->build_add( { %FORM } );

    if ( !$Address->{errno} ){

      $html->message( 'info', $lang{ADDRESS_BUILD},
        "$lang{ADDED}\n " );
    }
  }
  elsif ( $FORM{change} ){
    $FORM{PLANNED_TO_CONNECT} = $FORM{PLANNED_TO_CONNECT} ? $FORM{PLANNED_TO_CONNECT} : 0;
    $FORM{NUMBERING_DIRECTION} = $FORM{NUMBERING_DIRECTION} ? $FORM{NUMBERING_DIRECTION} : 0;
    $Address->build_change( \%FORM );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Address->build_info( { ID => $FORM{chg} } );
    if ( !$Address->{errno} ){
      $Address->{PLANNED_TO_CONNECT_CHECK}=$Address->{PLANNED_TO_CONNECT}?'checked':'';
      $Address->{NUMBERING_DIRECTION_CHECK}=$Address->{NUMBERING_DIRECTION}?'checked':'';
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = "$lang{CHANGE}";
      $FORM{add_form} = 1;
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{CHANGING}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->build_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{DELETED}" );
    }
  }

  _error_show( $Address );

  if ( $FORM{add_form} ){
    if ( $maps_enabled && $FORM{chg} ) {
      $Address->{MAP_BLOCK_VISIBLE} = 1;

      if ( $Address->{COORDX} && $Address->{COORDX} != 0) {
        $Address->{MAP_BTN} = $html->button( '',
          "get_index=maps_show_map&show=BUILD&OBJECT_ID=$Address->{ID}&header=1",
          { class => 'glyphicon glyphicon-globe', target => '_blank' } );
      }
      else {
        $Address->{MAP_BTN} = $html->button( '',
          "get_index=maps_edit&add=BUILD&OBJECT_ID=$Address->{ID}&LOCATION_ID=$Address->{ID}&header=1",
          { class => 'add', target => '_blank' } );
      }

    }
    $Address->{STREET_SEL} = sel_streets($Address);
    $html->tpl_show( templates( 'form_build' ), $Address );
  }

  my $street_name = '';
  if ($FORM{BUILDS}){
    $pages_qs .= "&BUILDS=$FORM{BUILDS}";

    my $street_list = $Address->street_list( {
      ID          => $FORM{BUILDS},
      STREET_NAME => '_SHOW',
      SECOND_NAME => '_SHOW',
      PAGE_ROWS   => 1,
      COLS_NAME   => 1
    } );

    if (!$Address->{errno} && $street_list && $street_list->[0]){
      $street_name = " : " . $street_list->[0]{street_name}
        . ( ($street_list->[0]{second_name}) ? " ( $street_list->[0]{second_name} )" : '');
    }
  }
  
  $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID} if ($FORM{DISTRICT_ID});
  $LIST_PARAMS{STREET_ID} = $FORM{BUILDS};
  $LIST_PARAMS{PLANNED_TO_CONNECT}  = $FORM{PLANNED_TO_CONNECT};
  $LIST_PARAMS{NUMBERING_DIRECTION} = $FORM{NUMBERING_DIRECTION};
    
  my @status_bar = (
    "$lang{PLANNED_TO_CONNECT}:index=$index&BUILDS=" . ($FORM{BUILDS} || '') . "&PLANNED_TO_CONNECT=1",
    "$lang{ALL}:index=$index&BUILDS=" . ($FORM{BUILDS} || '')
  );

  result_former( {
    INPUT_DATA      => $Address,
    FUNCTION        => 'build_list',
    MAP             => 1,
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  =>
    'NUMBER,BLOCK,FLORS,ENTRANCES,FLATS,STREET_NAME,USERS_COUNT,USERS_CONNECTIONS,ADDED' . ($maps_enabled ? ',COORDX' : ''),
    FUNCTION_FIELDS => 'msgs_admin:$lang{MESSAGE}:location_id:&add_form=1,change,del',
    EXT_TITLES      => {
      number              => $lang{NUM},
      flors               => $lang{FLORS},
      entrances           => $lang{ENTRANCES},
      flats               => $lang{FLATS},
      street_name         => $lang{STREET},
      users_count         => $lang{USERS},
      users_connections   => "$lang{DENSITY_OF_CONNECTIONS} %",
      added               => $lang{ADDED},
      location_id         => 'LOCATION ID',
      coordx              => $lang{MAP} . ' X',
      coordy              => $lang{MAP} . ' Y',
      planned_to_connect  => $lang{PLANNED_TO_CONNECT},
      block               => $lang{BLOCK}
    },
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      users_count => 'search_link:form_search:LOCATION_ID,type=11',
      coordx      => 'form_add_map:ID:ID,COORDX,add=1',
      number      =>  in_array( 'Dom', \@MODULES )?'form_show_construct:ID:ID,':'',
    },
    # for button MESSAGE
    FILTER_VALUES => {
      street_name => sub {
        my ($number, $line) = @_;
        $line->{location_id} = $line->{id};
        return $number;
      }
    },
    TABLE           => {
      width            => '100%',
      caption          => $lang{BUILDS} . $street_name,
      qs               => $pages_qs,
      ID               => 'BUILDS_LIST',
      header           => $html->table_header(\@status_bar),
      EXPORT           => 1,
      SHOW_COLS_HIDDEN => { 'BUILDS' => $FORM{BUILDS} },
      MENU             => "$lang{ADD}:index=$index&add_form=1&BUILDS=$FORM{BUILDS}:add",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}


#**********************************************************
=head2 form_show_construct()

=cut
#**********************************************************
sub form_show_construct{
  my ($id,$attr) = @_;

  return $html->button( $id, "index=". get_function_index('dom_info') ."&LOCATION_ID=$attr->{VALUES}->{ID}" );
}

#**********************************************************
=head2 form_show_link()

=cut
#**********************************************************
sub form_show_link{
  my ($params, $attr) = @_;

  return $html->button( $params, "index=$index&BUILDS=$attr->{VALUES}->{ID}" );

  return $params;
}

#**********************************************************
=head2 form_location_media($attr)

=cut
#**********************************************************
sub form_location_media{

  if ( $FORM{show} ){
    $Address->location_media_info( { ID => $FORM{show} } );
    print "Content-Type: $Address->{CONTENT_TYPE}\n\n";
    print "$Address->{CONTENT}";
    return 1;
  }
  elsif ( $FORM{add} ){
    $Address->location_media_add( {
        %FORM,
        LOCATION_ID  => $FORM{chg},
        CONTENT      => $FORM{FILE}{Contents},
        FILESIZE     => $FORM{FILE}{Size},
        FILENAME     => $FORM{FILE}{filename},
        CONTENT_TYPE => $FORM{FILE}{'Content-Type'},
      } );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->location_media_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{DELETED}" );
    }
  }

  _error_show( $Address );

  $html->tpl_show( templates( 'form_location_media' ), $Address );

  my $list = $Address->location_media_list( { LOCATION_ID => $FORM{chg}, COLS_NAME => 1 } );

  foreach my $line ( @{$list} ){
    my $del_btn = $html->button( $lang{DEL}, "index=$index&media=1&chg=$FORM{chg}&BUILDS=$FORM{BUILDS}&del=$line->{id}",
      {
        MESSAGE => "$lang{DEL} [$line->{id}] $line->{comments}?", class => 'del' } );

    print "<div class='row'>
    <div class='col-md-4'>
    ID: $line->{id} <br>
    $lang{COMMENTS}: $line->{comments} <br>
    $lang{FILE}: $line->{filename} <br>
    $del_btn
    </div>
    <div class='col-md-8 bg-success'>
      <img src='$SELF_URL?qindex=$index&media=1&chg=$FORM{chg}&BUILDS=$FORM{BUILDS}&show=$line->{id}'>
    </div>
    </div>\n";
  }

  return 1;
}

#**********************************************************
=head2 form_add_map($coordx, $attr)

=cut
#**********************************************************
sub form_add_map{
  my ($coordx, $attr) = @_;

  if ($coordx && $attr->{VALUES}->{ID} && in_array('Maps', \@MODULES)) {
    load_module('Maps');
    return $html->button( '',
      "get_index=maps_show_map&show_build=$attr->{VALUES}->{ID}&header=1",
      { class => 'glyphicon glyphicon-globe', target => '_maps' } );
  }

  if ($attr->{VALUES}->{ID} && in_array('Maps', \@MODULES)) {
    load_module('Maps');
    return _maps_btn_for_build($attr->{VALUES}->{ID});
  }

  if ( $attr->{VALUES}->{POINTS} ){
    return $html->button( '',
      "get_index=maps_show_map&show=ROUTE&OBJECT_ID=$attr->{VALUES}->{ID}&header=1",
      { class => 'glyphicon glyphicon-globe', target => '_maps' } );
  }
  elsif ( $coordx == 0 ){
    if ( defined( $attr->{VALUES}->{POINTS} ) && $attr->{VALUES}->{POINTS} == 0 ){
      return $html->button( 'add',
        'index=' . get_function_index( 'maps_edit' ) . "&add=ROUTE&OBJECT_ID=$attr->{VALUES}->{ID}",
        { class => 'add', target => '_blank' } );
    }
    else{
      # TODO: send address to show in add modal window
      # TODO: check permissions
      return $html->button( 'add',
        'index=' . get_function_index( 'maps_edit' ) . "&add=BUILD2&LOCATION_ID=$attr->{VALUES}->{ID}",
        { class => 'add', target => '_blank' } );
    }
  }
  else{
    # google_maps_show
    return $html->button( '', "get_index=maps_show_map&show=BUILD&OBJECT_ID=$attr->{VALUES}->{ID}&header=1",
      { class => 'glyphicon glyphicon-globe', target => '_blank' } );
  }

  return $coordx;
}

#**********************************************************
=head2 form_address_sel() - Multi address form

=cut
#**********************************************************
sub form_address_sel {

  print "Content-Type: text/html\n\n";

  my $js_list   = "<option></option>";

  my $list_to_options_string = sub {
   my ($array_ref, $value_key, $name_key) = @_;
    $value_key //= 'id';
    $name_key //= 'name';
    
    my $res = '';
    foreach my $line (@$array_ref){
      my $value = $line->{$name_key};
      $value =~ s/\'/&rsquo;/g;
      $res .= "<option value='$line->{$value_key}'>$value</option>";
    }
    
    $res;
  };
  
  # Show builds
  if ($FORM{STREET} || $FORM{STREET_ID}) {
    
    my $builds_list = $Address->build_list({
      STREET_ID => $FORM{STREET} || $FORM{STREET_ID},
      BLOCK     => '_SHOW',
      COORDX    => '_SHOW',
      PAGE_ROWS => 10000,
      COLS_NAME => 1
    });
    
    if ($Address->{TOTAL} > 0) {
      foreach my $line (@$builds_list) {
        $line->{number} =~ s/\'/&rsquo;/g;
        my $value = $line->{number};
        
        if ($line->{block}){
          $value .= "-$line->{block}";
        }
        
        if($FORM{SHOW_UNREG} && $line->{coordx} == 0) {
          $value .= ' (+)';
        }
        
        $js_list .= "<option value='$line->{id}'>$value</option>";
      }
      
    }
    print $js_list;
  }
  # Show streets
  elsif ($FORM{DISTRICT_ID}) {
    my $streets_list = $Address->street_list({
      DISTRICT_ID => $FORM{DISTRICT_ID},
      STREET_NAME => '_SHOW',
      TYPE        => '_SHOW',
      PAGE_ROWS   => 10000,
      SORT        => 2,
      COLS_NAME   => 1
    });

    if ($conf{STREET_TYPE}) {
      my @street_type_list = split (';', $conf{STREET_TYPE});

      $streets_list = [ map { 
        { %$_, 
          street_name => join (' ', ($street_type_list[($_->{type} || 0)]) ? $street_type_list[$_->{type}] : q{}, ($_->{street_name} || q{}))
        }; 
      } @{$streets_list} ];
    }
  
    print $js_list . $list_to_options_string->($streets_list, 'id', 'street_name');
  }
  # Show users
  elsif ($FORM{LOCATION_ID}) {
    my $list = $users->list({
      LOCATION_ID  => $FORM{LOCATION_ID},
      ADDRESS_FLAT => '!',
      PAGE_ROWS    => 1000,
      COLS_NAME    => 1
    });

    my $json_load_error = load_pmodule("JSON", { RETURN => 1 });
    if ($json_load_error) {
      print $json_load_error;
      return 0;
    }
  
    my $json = JSON->new->utf8(0);
    print $json->encode({
      map {
          $_->{address_flat} =>
            {
              uid       => $_->{uid},
              user_name => $_->{login}
            }
      } @{$list}
    });
  }
  # Show districts
  else {
    my $districts_list = $Address->district_list({
      %LIST_PARAMS,
      PAGE_ROWS => 1000,
      COLS_NAME => 1,
      SORT      => 'city',
    });
  
    print $js_list . $list_to_options_string->($districts_list);
  }
  
  exit;
}

#**********************************************************
=head2 sel_countries($attr) - Country Select;

  Arguments:
    $attr
      NAME      - Select object name (Default: COUNTRY)
      COUNTRY   - Selected value
  Returns:
    \%countries_hash, $sel_form

=cut
#**********************************************************
sub sel_countries {
  my ($attr) = @_;

  my %countries_hash = ();

  my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
  my @countries_arr = split(/[\r\n]/, $countries);

  foreach my $c (@countries_arr) {
    my ($id, $name) = split(/:/, $c);
    if ($id && $id =~ /^\d+$/){
      $countries_hash{ int($id) } = $name;
    }
  }

  my $sel_form = $html->form_select($attr->{NAME} || 'COUNTRY',
    {
      SELECTED => $attr->{COUNTRY} || $FORM{COUNTRY} || 0,
      SEL_HASH => { '' => '', %countries_hash },
      NO_ID    => 1
    }
  );

  return \%countries_hash, $sel_form;
}

#**********************************************************
=head2 sel_districts($attr)

  Arguments:
    $attr
      DISTRICT_ID

  Result:
    Select form

=cut
#**********************************************************
sub sel_districts {
  my ($attr) = @_;

  $attr ||= {};

  return $html->form_select(
    "DISTRICT_ID",
    {
      SELECTED    => $attr->{DISTRICT_ID} || $FORM{DISTRICT_ID},
      SEL_LIST    => $Address->district_list( { PAGE_ROWS => 1000, COLS_NAME => 1, } ),
      SEL_OPTIONS => { '' => '--' },
      NO_ID       => 1,
      %{ $attr }
    }
  );
}

#**********************************************************
=head2 sel_streets($attr)

  Arguments:
    $attr
      STREET_ID
      SEL_OPTIONS
      MAIN_MENU

  Results:
    Select form

=cut
#**********************************************************
sub sel_streets {
  my ($attr) = @_;

  $attr ||= {};

  my $list = $Address->street_list( { PAGE_ROWS => 10000, STREET_NAME => '_SHOW', COLS_NAME => 1 } );
  if ($conf{STREET_TYPE}) {
    my @street_type_list = split (';', $conf{STREET_TYPE});
    $list = [ map { 
      { %$_, 
        street_name => join (' ', $street_type_list[$_->{type}], $_->{street_name})
      }; 
    } @{$list} ];
  }

  return $html->form_select(
    "STREET_ID",
    {
      SELECTED       => $attr->{STREET_ID} || $FORM{BUILDS},
      SEL_LIST       => $list,
      SEL_VALUE      => 'street_name',
      NO_ID          => 1,
      SEL_OPTIONS    => $attr->{SEL_OPTIONS},
      MAIN_MENU      => get_function_index( 'form_streets' ),
      MAIN_MENU_ARGV => ( $attr->{STREET_ID} || $FORM{BUILDS} ) ? "chg=" . ( $attr->{STREET_ID} || $FORM{BUILDS} ) : '',
      %{ $attr }
    }
  );
}

#**********************************************************
=head2 full_address_name($location_id)

=cut
#**********************************************************
sub full_address_name {
  my ($location_id) = @_;
  return '' if !$location_id;

  my $info = $Address->address_info($location_id);
  my $street_type = '';
  if ($conf{STREET_TYPE} && $info->{STREET_TYPE}) {
    my @street_types = split (';', $conf{STREET_TYPE});
    $street_type = @street_types[$info->{STREET_TYPE}];
  }
  
  my @address_components = (
    $info->{CITY},
    $info->{ADDRESS_DISTRICT},
    $street_type .' '. ($info->{ADDRESS_STREET} || q{}),
    ($info->{ADDRESS_STREET2} ? "($info->{ADDRESS_STREET2})" : ''),
    $info->{ADDRESS_BUILD},
    ($info->{ADDRESS_BLOCK} ? "-$info->{ADDRESS_BLOCK}" : '')
  );
  
  return join(', ', grep { $_ && $_ ne '' } @address_components);
}

#**********************************************************
=head2 short_address_name($location_id)

=cut
#**********************************************************
sub short_address_name {
  my ($location_id) = @_;
  return '' if !$location_id;
  
  my $info = $Address->address_info($location_id);
  my $street_type = '';
  if ($conf{STREET_TYPE}) {
    $street_type = (split (';', $conf{STREET_TYPE}))[$info->{STREET_TYPE}];
  }
  
  my @address_components = (
    "$street_type $info->{ADDRESS_STREET}",
    ($info->{ADDRESS_STREET2} ? "($info->{ADDRESS_STREET2})" : ''),
    $info->{ADDRESS_BUILD},
    ($info->{ADDRESS_BLOCK} ? "-$info->{ADDRESS_BLOCK}" : '')
  );
  
  return join(', ', grep { $_ && $_ ne '' } @address_components);
}


#**********************************************************
=head2 form_address($attr) - shows form for adding nas addrress

  Arguments:
    $attr
      LOCATION_ID         =>
      FLAT_CHECK_FREE     => 1
      FLAT_CHECK_OCCUPIED => 1
      SHOW                => 1
      FLOOR               => value    - Shows Extra fields entrance and floor at the address box
        and add value into floor input
      ENTRANCE            => value    - Shows Extra fields entrance and floor at the address box
        and add value into entrance input

  Results:
    return $result

  Example:

    $Nas->{ADDRESS_FORM}   = form_address({
      LOCATION_ID => $Nas->{LOCATION_ID},
      FLOOR       => $Nas->{FLOOR},
      ENTRANCE    => $Nas->{ENTRANCE}
    });

=cut
#**********************************************************
sub form_address {
  my ($attr) = @_;
  my %params = ();


  if(! $attr->{SHOW}) {
    $params{PARAMS}='collapsed-box';
  }

  if ( ! $conf{ADDRESS_REGISTER} ) {
    my $countries_hash;
    ($countries_hash, $params{COUNTRY_SEL}) = sel_countries({
        NAME    => 'COUNTRY_ID',
        COUNTRY => $attr->{COUNTRY_ID} });

    return $html->tpl_show(templates('form_address'), { %{ ($attr) ? $attr : {} }, %params }, { OUTPUT2RETURN => 1 });
  }

  if ($attr->{LOCATION_ID}) {
    $Address->address_info($attr->{LOCATION_ID});
    if (in_array('Maps', \@MODULES)) {
      load_module('Maps');
      $Address->{MAP_BTN} = _maps_btn_for_build($attr->{LOCATION_ID});
    }
    if (in_array('Dom', \@MODULES)) {
      $Address->{DOM_BTN} = $html->button("", 'index=' . get_function_index('dom_info') . "&LOCATION_ID=$attr->{LOCATION_ID}",
        { class                                                                   => 'btn btn-default btn-sm',
          ex_params                                                               =>
          "data-tooltip-position='top' data-tooltip='$lang{ADDRESS_BUILD}'", ICON => 'fa fa-building-o ' });
    }
    $Address->{FLAT_CHECK_FREE} = 1;
  }

  if($attr->{REGISTRATION_HIDE_ADDRESS_BUTTON}){
    $Address->{HIDE_ADD_BUILD_BUTTON}   = "style='display:none;'" if (!$conf{REGISTRATION_ADD_PLANNED_BUILDS});
    $Address->{HIDE_ADD_ADDRESS_BUTTON} = "style='display:none;'";
  }

  if (defined($attr->{FLOOR}) || defined($attr->{ENTRANCE})) {
    $Address->{EXT_ADDRESS} = $html->tpl_show(templates('form_ext_address'), { ENTRANCE => $attr->{ENTRANCE}, FLOOR => $attr->{FLOOR} }, { OUTPUT2RETURN => 1 });
  }
    my $result = $html->tpl_show(
      templates('form_show_hide'),
      {
        CONTENT =>
          $html->tpl_show(templates('form_address_sel'), { %$Address, %$attr }, {
            OUTPUT2RETURN => 1,
            ID            => 'form_address_sel',
            %{($attr) ? $attr : {}}
          }),
        NAME    => $lang{ADDRESS},
        ID      => 'ADDRESS_FORM',
        %params
      },
      { OUTPUT2RETURN => 1 }
    );

  return $result;
}

#**********************************************************
=head2 _street_type_select

=cut
#**********************************************************
sub _street_type_select {
  my ($selected) = @_;

  my @street_types = split(';', $conf{STREET_TYPE} || '');

  my $result = $html->form_select(
    "TYPE",
    {
      SELECTED       => $selected,
      SEL_ARRAY      => \@street_types,
      ARRAY_NUM_ID   => 1,
    }
  );

  return $result;
}

1;
