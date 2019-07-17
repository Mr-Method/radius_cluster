#package Layers;
use strict;
use warnings FATAL => 'all';
use v5.16;

=head1 NAME

  Maps::Layers - maps layer objects serializing functions

=head2 SYNOPSIS

  This is part of webinterface that transforms DB objects to JSON

=cut

use Abills::Base qw/_bp in_array/;

our ($MAPS_ENABLED_LAYERS);
use Maps::Shared qw/:all LAYER_ID_BY_NAME $MAPS_ENABLED_LAYERS/;

our ($db,
  $admin,
  %conf,
  $html,
  %lang,
  %permissions,
  $Address,
  $Nas,
  $Maps
);

require JSON;
JSON->import(qw/to_json from_json encode_json decode_json/);



#**********************************************************
=head2 maps_point_info_table($attr) - Make point info window

  Arguments:
    $attr
      OBJECTS - Data form map Hash ref
            [{
              login   => 'test',
              deposit => 1.11
            }]

      TABLE_TITLES - array_ref Location table information fields
      MAP_FILTERS  -

  Returns:
    string - HTML table with information

=cut
#**********************************************************
sub maps_point_info_table {
  my ($attr) = @_;
  my $point_info_object = '<table class="table table-condensed table-hover table-bordered">';
  
  my $objects      = $attr->{OBJECTS};
  my $table_titles = $attr->{TABLE_TITLES};
  
  return q{} unless ($objects && ref $objects eq 'ARRAY' && scalar @{$objects});
  
  my $online_block = $html->element('span', '', {
      class => 'glyphicon glyphicon-ok-circle text-green',
      title => $lang{ONLINE}
    });
  
  # Add headers
  if ($attr->{TABLE_LANG_TITLES} && ref $attr->{TABLE_LANG_TITLES} eq 'ARRAY') {
    $point_info_object .= '<tr>' . join('', map { '<th>' . ($_ || q{}) . '</th>'  } @{$attr->{TABLE_LANG_TITLES}}) . '</tr>';
  }
  
  foreach my $u ( @{$objects} ) {
    $point_info_object .= '<tr>';
    for ( my $i = 0; $i <= $#{$table_titles}; $i++ ) {
      my $value = $table_titles->[$i];
      next if (!$value);
      my $field_id = lc($table_titles->[$i]);
      
      if ( $table_titles->[$i] eq 'LOGIN' && $u->{uid} ) {
        $value = $html->button($u->{$field_id}, "index=15&UID=$u->{uid}");
      }
      elsif ( $table_titles->[$i] eq 'DEPOSIT' && defined($u->{'deposit'})) {
        my $deposit = sprintf("%.2f", $u->{'deposit'});
        
        if ( $u->{$field_id} < 0 ) {
          $value = qq{<p class="text-danger">$deposit</p>};
        }
        else {
          $value = $deposit;
        }
      }
      elsif ( $table_titles->[$i] eq 'ADDRESS_FLAT' ) {
        $value = $html->b($u->{$field_id});
      }
      elsif ( $table_titles->[$i] eq 'ONLINE' ){
        $value = ($u->{$field_id})
          ? $online_block
          : 0;
      }
      elsif ( $attr->{MAP_FILTERS} && $attr->{MAP_FILTERS}->{$field_id} ) {
        my ($filter_fn, @arr) = split(/:/, $attr->{MAP_FILTERS}->{$field_id});
        
        my %p_values = ();
        if ( $arr[1] =~ /,/ ) {
          foreach my $k ( split(/,/, $arr[1]) ) {
            if ( $k =~ /(\S+)=(.*)/ ) {
              my $key = $1;
              my $val = $2;
              
              if ( $val =~ /\{(\S+)\}/ ) {
                $val = $u->{ lc($1) };
              }
              
              $p_values{$key} = $val;
            }
            elsif ( defined($u->{ lc($k) }) ) {
              $p_values{$k} = $u->{ lc($k) };
            }
          }
        }
        
        $value = &{ \&{$filter_fn} }($u->{$field_id}, { PARAMS => \@arr, VALUES => \%p_values });
      }
      else {
        $value = (ref $u eq 'HASH' && $u->{$field_id}) ? $u->{$field_id} : '';
        $value =~ s/[\r\n]/ /g;
      }
      
      $point_info_object .= '<td>' . ($value || q{}) . '</td>';
    }
    
    $point_info_object .= '</tr>';
  }
  
  $point_info_object .= '</table>';
  $point_info_object =~ s/\"/\\\"/gm;
  
  return $point_info_object;
}


#**********************************************************

=head2 maps_builds_show($attr)

  Arguments:
    $attr

  Returns:

=cut

#**********************************************************
sub maps_builds_show {
  my ($attr) = @_;
  
  my $export = $FORM{EXPORT_LIST} || $attr->{EXPORT};
  my $object_info = $attr->{DATA};
  
  
  # ===== OLD CODE (coords in builds table) =====
  my $builds_list = $Address->build_list(
    {
      DISTRICT_ID        => $FORM{DISTRICT_ID} || '>0',
      DISTRICT_NAME      => '_SHOW',
      %LIST_PARAMS,
      NUMBER             => '_SHOW',
      PUBLIC_COMMENTS    => '_SHOW',
      PLANNED_TO_CONNECT => '_SHOW',
      STREET_NAME        => '_SHOW',
      COORDX             => '!',
      COORDY             => '!',
      ZOOM               => '_SHOW',
      COLS_NAME          => 1,
      PAGE_ROWS          => 10000,
      LOCATION_ID        => $attr->{ID} || $FORM{OBJECT_ID} || '_SHOW'
    }
  );
  
  my $count_array = _maps_points_count($builds_list, $object_info);
  
  my $icon_prefix = 'build';
  my $size = 'false';
  if ($conf{MAPS_LAYER_1_ICON_PREFIX}){
    $icon_prefix = $conf{MAPS_LAYER_1_ICON_PREFIX};
    $size = '[15,15]';
  }
  
  my @export_arr = ();
  foreach my $build ( @{$builds_list} ) {
    
    my $info_hash = {};
    my $point_count = 0;
    
    if ( $attr->{CLIENT_MAP} ) {
      $info_hash->{HTML} = $build->{public_comments} || '';
      $point_count = 0;
      if ($build->{planned_to_connect}){
        $info_hash->{COLOR} = 'gray';
      }
    }
    else {
      $info_hash = maps_load_info({LOCATION_ID => $build->{id}});
      $point_count = $info_hash->{COUNT} || (($count_array && ref $count_array eq 'ARRAY') ? scalar @{$count_array} : 0);
    }
    
    next if ($FORM{GROUP_ID} && !$info_hash->{HTML});
    
    my $color = $info_hash->{COLOR} || _maps_point_color($point_count, $count_array);
    my $address_full = "$build->{district_name}, $build->{street_name}, $build->{number}";
    
    my $info_table = $info_hash->{HTML} || q{};

    # REVERSE COORDS
    my $tpl = qq(
      {
        "ID"       : $build->{id},
        "MARKER"   : {
          "ID"       : $build->{id},
          "OBJECT_ID": $build->{id},
          "NAME"     : "$address_full",
          "COORDX"   : $build->{coordy},
          "COORDY"   : $build->{coordx},
          "SIZE"     : $size,
          "TYPE"     : "$icon_prefix\_$color",
          "INFO"     : "$info_table",
          "COUNT"    : $point_count
        },
        "ADDRESS"  : "$address_full",
        "DISTRICT" : $build->{district_id},
        "LAYER_ID" : @{[LAYER_ID_BY_NAME->{BUILD}]}
      }
    );
    
    push @export_arr, $tpl;
  }
  # ===== END OF OLD CODE =====
  
  # ===== NEW CODE (coords in maps_points) =====
  my $coords_list = $Maps->points_list(
    {
      COORDX            => '!',
      COORDY            => '!',
      TYPE_ID           => 3,
      LOCATION_ID       => '_SHOW',
      ADDRESS_FULL      => '_SHOW',
      ID                => '_SHOW',
    }
  );
  
  $count_array = _maps_points_count($coords_list, $object_info);
  
  foreach my $build ( @{$coords_list} ) {
    
    next if (!$build->{location_id});
    
    my $info_hash = {};
    my $point_count = 0;
    
    if (!$attr->{CLIENT_MAP}) {
      $info_hash = maps_load_info({LOCATION_ID => $build->{location_id}});
      $point_count = $info_hash->{COUNT} || (($count_array && ref $count_array eq 'ARRAY') ? scalar @{$count_array} : 0);
    }
    
    next if ($FORM{GROUP_ID} && !$info_hash->{HTML});
    
    my $color = $info_hash->{COLOR} || _maps_point_color($point_count, $count_array);
    my $address_full = $build->{address_full} || q{};
    
    my $info_table = $info_hash->{HTML} || q{};
    
    my $tpl = qq(
      {
        "ID"         : $build->{location_id},
        "OBJECT_ID"  : $build->{id},
        "MARKER"     : {
          "ID"       : $build->{location_id},
          "OBJECT_ID": $build->{id},
          "NAME"     : "$address_full",
          "COORDX"   : $build->{coordx},
          "COORDY"   : $build->{coordy},
          "TYPE"     : "build_$color",
          "INFO"     : "$info_table",
          "COUNT"    : $point_count
        },
        "ADDRESS"  : "$address_full",
        "LAYER_ID" : @{[LAYER_ID_BY_NAME->{BUILD}]}
      }
    );
    
    push @export_arr, $tpl;
  }
  
  
  # ===== END OF NEW CODE =====
  
  # ===== LOAD POLYGONS layer_id = 12 =====
  my $list_builds_objects = _maps_get_layer_objects(12, {
      ID            => $attr->{ID} || '_SHOW',
      OBJECT_ID     => '_SHOW',
      LOCATION_ID   => '_SHOW',
      COLS_NAME     => 1
    });
  
  
  foreach my $build ( @{$list_builds_objects} ) {
    my $build_info = $Maps->points_info($build->{OBJECT_ID}, {
        ADDRESS_FULL  => '_SHOW',
        STREET_NAME   => '_SHOW',
        BUILD_NUMBER  => '_SHOW',
        LOCATION_ID   => '_SHOW',
      });
    unless ($build->{OBJECT_ID}) {
      next;
    }
    
    if ($FORM{OBJECT_ID} && $FORM{OBJECT_ID} != $build_info->{LOCATION_ID} ) {
      next;
    }
    
    my $info_hash = {};
    my $point_count = 0;
#    my $address = '';
    unless ( $attr->{CLIENT_MAP} ) {
      $info_hash = maps_load_info({ LOCATION_ID => $build_info->{LOCATION_ID} });
      $point_count = $info_hash->{COUNT} || (($count_array && ref $count_array eq 'ARRAY') ? scalar @{$count_array} : 0);
    }
    # _bp('', $info_hash, { TO_CONSOLE => 1});
    my $color = $info_hash->{COLOR} || _maps_point_color($point_count);
    my $info_table = $info_hash->{HTML} || q{};
    
    $build_info->{address_full} //= '';
    $info_table //= '';
    
    my $points_json = JSON::to_json($build->{POLYGON}->{POINTS});
    
    my $info = qq{
            {
                "ID"        : $build->{OBJECT_ID},
                "OBJECT_ID" : $build->{OBJECT_ID},
                "POLYGON"   : {
                    "OBJECT_ID" : $build->{OBJECT_ID},
                    "ID"        : $build->{OBJECT_ID},
                    "LAYER_ID"  : 12,
                    "POINTS"    : $points_json,
                    "INFO"      : "$info_table",
                    "COUNT"     : $point_count,
                    "NAME"      : "$build_info->{address_full}",
                    "COLOR"     : "$color"
                },
                "LAYER_ID"  : 12
            }
    };
    push @export_arr, $info;
  }
  
  if ( $export ) {
    return join(", ", @export_arr);
  }
  
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{BUILD} } = 'BUILD';
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{BUILD2} } = 'BUILD2';
  return join(";", map { "ObjectsArray[ObjectsArray.length] = $_;" } @export_arr);
}

#**********************************************************

=head2 maps_routes_show($attr)

=cut

#**********************************************************
sub maps_routes_show {
  my ($attr) = @_;
  
  my $line_opacity = $conf{MAP_LINE_OPACITY} || 0.5;
  
  my $route_info = '';
  my @export_arr = ();
  
  my $list_routes = $Maps->routes_list(
    {
      ID            => $attr->{ID} || '_SHOW',
      TYPE          => '_SHOW',
      TYPE_NAME     => '_SHOW',
      TYPE_COMMENTS => '_SHOW',
      NAS1          => '_SHOW',
      NAS2          => '_SHOW',
      NAS1_PORT     => '_SHOW',
      NAS2_PORT     => '_SHOW',
      LENGTH        => '_SHOW',
      COLOR         => '_SHOW',
      FIBERS_COUNT  => '_SHOW',
      LINE_WIDTH    => '_SHOW',
      POINTS        => '_SHOW',
      GROUP_NAME    => '_SHOW',
      COLS_NAME     => 1,
      ID            => $FORM{ID} || '_SHOW'
    }
  );
  
  #      _bp('', $list_routes, {TO_CONSOLE => 1});
  
  my $maps_route_index = get_function_index('maps_routes_list');
  
  foreach my $route ( @{$list_routes} ) {
    my $list_routes_info = $Maps->routes_coords_list({ ID => $route->{id}, COLS_NAME => 1 });
    
    if ( $list_routes_info->[0]->{id} ) {
      $route->{name} ||= '';
      $route->{nas1} ||= '';
      $route->{nas2} ||= '';
      $route->{nas1_port} ||= '';
      $route->{nas2_port} ||= '';
      $route->{length} ||= '';
      $route->{descr} ||= '';
      $route->{id} ||= '';
      
      $route_info = qq{
      <table>
        <thead></thead>
        <tbody>
          <tr>
            <th><strong>$lang{NAME}:</strong></th>
            <td>$route->{name}</td>
          </tr>
          <tr>
            <th>$lang{TYPE}:</th>
            <td>$route->{type_name}</td>
          </tr>
          <tr>
            <th>NAS1:</th>
            <td>$route->{nas1}</td>
          </tr>
          <tr>
            <th>NAS2:</th>
            <td>$route->{nas2}</td>
          </tr>
          <tr>
            <th>NAS1 $lang{PORT}:</th>
            <td>$route->{nas1_port}</td>
          </tr>
          <tr>
            <th>NAS2 $lang{PORT}:</th>
            <td>$route->{nas2_port}</td>
          </tr>
          <tr>
            <th>$lang{LENGTH}:</th>
            <td>$route->{length}</td>
          </tr>
          <tr>
            <th>$lang{DESCRIBE}:</th>
            <td>$route->{descr}</td>
          </tr>
          <tr>
            <td colspan=2><a href='$SELF_URL?index=$maps_route_index&chg=$route->{id}'>$lang{INFO}</a></td>
          </tr>
        </tbody>
      </table>
      };
      $route_info =~ s/\n//gm;
      
      my @routes_coord_arr = ();
      my @routes_markers_arr = ();
      
      foreach my $route_point ( @{$list_routes_info} ) {
        push @routes_markers_arr, qq {
              {
                "ID"       : $route->{id},
                "POINT_ID" : $route_point->{id},
                "COORDX"   : $route_point->{coordy},
                "COORDY"   : $route_point->{coordx},
                "INFO" : "$route_info",
                "TYPE" : "route_green"
              }
            };
        push @routes_coord_arr, '[' . $route_point->{coordy} . ', ' . $route_point->{coordx} . ']';
      }
      
      my $route_coords_info = join(', ', @routes_coord_arr);
      my $routes_markers = join(', ', @routes_markers_arr);
      
      push @export_arr, qq{
          {
            "MARKERS" : [$routes_markers],
            "POLYLINE" : {
               "ID"       : $route->{id},
               "POINTS": [$route_coords_info],
               "strokeColor" : "$route->{color}",
               "strokeOpacity" : $line_opacity,
               "strokeWeight" : $route->{line_width},
               "INFOWINDOW" : "$route_info"
            },
            "LAYER_ID" : @{[LAYER_ID_BY_NAME->{ROUTE}]}
          }
        };
      
    }
  }
  
  if ( $attr->{EXPORT} ) {
    return join(", ", @export_arr);
  }
  
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{ROUTE} } = 'ROUTE';
  return join(";", map { "ObjectsArray[ObjectsArray.length] = $_;" } @export_arr);
}

#**********************************************************
=head2 maps_wifis_show($attr)

=cut
#**********************************************************
sub maps_wifis_show {
  my ($attr) = @_;
  
  my $list_wifi_objects = _maps_get_layer_objects(2, {
      ID        => $attr->{ID} || '_SHOW',
      OBJECT_ID => '_SHOW',
      COLS_NAME => 1
    });
  # _error_show($Maps);
  
  my @export_arr = ();
  
  foreach my $wifi ( @{$list_wifi_objects} ) {
#    my $wifi_info = $Maps->points_info($wifi->{OBJECT_ID});
    if ($wifi->{CIRCLE}) {
      my $info = qq{
            {
               "ID"        : $wifi->{CIRCLE}->{ID},
               "CIRCLE"    : {
                    "OBJECT_ID" : $wifi->{CIRCLE}->{ID},
                    "RADIUS"    : $wifi->{CIRCLE}->{RADIUS},
                    "COORDX"    : $wifi->{CIRCLE}->{COORDX},
                    "COORDY"    : $wifi->{CIRCLE}->{COORDY},
                    "ID"        : $wifi->{OBJECT_ID},
                    "LAYER_ID"  : 2
                },
                "LAYER_ID"  : 2,
                "OBJECT_ID" : $wifi->{OBJECT_ID}
            }
      };
      push @export_arr, $info;
    }
    if ($wifi->{POLYGON}) {
      my $points_json = JSON::to_json($wifi->{POLYGON}->{POINTS});
      my $info = qq{
            {
                "ID"        : $wifi->{POLYGON}->{ID},
                "OBJECT_ID" : $wifi->{OBJECT_ID},
                "POLYGON"   : {
                    "OBJECT_ID" : $wifi->{OBJECT_ID},
                    "ID"        : $wifi->{OBJECT_ID},
                    "LAYER_ID"  : 2,
                    "POINTS"    : $points_json
                },
                "LAYER_ID"  : 2
            }
      };
      push @export_arr, $info;
    }
    
  }
  # if ( $attr->{EXPORT} ) {
  return join(", ", @export_arr);
  # }
  # $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{WIFI} } = 'WIFI';
  # return join(";", map { "ObjectsArray[ObjectsArray.length] = $_;" } @export_arr);
}

#**********************************************************

=head2 maps_gps_show($attr)

=cut

#**********************************************************
sub maps_gps_show {
  my ($attr) = @_;
  
  require GPS;
  GPS->import();
  my $Gps = GPS->new($db, $admin, \%conf);
  
  my @list_gps = ();
  my $tracked_admins = $Gps->tracked_admins_list();
  
  foreach my $tracker ( @{$tracked_admins} ) {
    push @list_gps, $Gps->tracked_admin_info($tracker->{aid});
  }
  
  my @export_arr = ();
  my $admin_no = 0;
  foreach my $admin_gps ( sort @list_gps ) {
    #Zero means no location for this admin_id;
    if ( $admin_gps == 0 ) { next }
    
    $admin_no++;
    my $info = "$lang{ADMIN}: <strong>$admin_gps->{A_LOGIN}</strong><br />";
    $info .= "$lang{LAST_UPDATE}: <strong>$admin_gps->{gps_time}. Battery : " . ($admin_gps->{battery} || '??'). " %</strong><br />";
    $info .= "<br><button onclick='GPSControls.showRouteFor($admin_gps->{aid}, $admin_no, true)'><i class='fa fa-map-marker'></i>$lang{ROUTE}</button>";
    
    my $admin_icon = $Gps->thumbnail_get($admin_gps->{aid});
    my $icon =
        ($admin_icon)
      ? "/images/$admin_icon"
      : "../location/$admin_no";
    
    #    _bp('', $admin_gps, {TO_CONSOLE => 1});
    
    push @export_arr, qq{
      {
        "MARKER" : {
                     "COORDX"   : $admin_gps->{coord_y},
                     "COORDY"   : $admin_gps->{coord_x},
                     "INFO" : "$info",
                     "TYPE" : "$icon",
                     "META" : { "colorNo" : $admin_no, "ADMIN" :  $admin_gps->{AID}, "x" : $admin_gps->{coord_y}, "y" : $admin_gps->{coord_x} }
                   },
        "LAYER_ID" : @{[LAYER_ID_BY_NAME->{GPS}]}
      }
    };
  }
  
  if ( $attr->{EXPORT} ) {
    return join(", ", @export_arr);
  }
  
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{GPS} } = 'GPS';
  return join(";", map { "ObjectsArray[ObjectsArray.length] = $_;" } @export_arr);
}

#**********************************************************

=head2 maps_gps_route_show($attr)

=cut

#**********************************************************
sub maps_gps_route_show {
  my ($attr) = @_;
  my $aid = $FORM{AID};
  my $date = $FORM{DATE} || $DATE;
  
  return '' unless ($FORM{AID} && $FORM{DATE});
  
  $FORM{TIME_FROM} ||= '00:00';
  $FORM{TIME_TO} ||= '23:59';
  
  my $time_from = ($FORM{TIME_FROM} =~ /\d{2}[:]\d{2}/) ? $FORM{TIME_FROM} : '00:00';
  my $time_to = ($FORM{TIME_TO} =~ /\d{2}[:]\d{2}/) ? $FORM{TIME_TO} : '23:59';
  
  require GPS;
  GPS->import();
  my $Gps = GPS->new($db, $admin, \%conf);
  
  $Gps->{debug} = 1 if ($FORM{DEBUG} && $FORM{DEBUG} > 7);
  my $route = $Gps->tracked_admin_route_info($aid, $date, {
      FROM_TIME => $time_from,
      TO_TIME => $time_to ,
      SHOW_ALL_COLUMNS => 1,
      
      DESC => 1,
    });
  _error_show($Gps) if ($FORM{DEBUG});
  $route ||= { };
  
  my $route_points = $route->{list};
  
  #if no points, show last update date
  if ( !$route_points || scalar @{$route_points} == 0 ) {
    my $full_route = $Gps->tracked_admin_route_info($aid, { DESC => 1, PAGE_ROWS => 1 });    #FIXME: hash params
    _error_show($Gps) if ($FORM{DEBUG});
    
    my $last_message = '';
    if ( $full_route && (my $list = $full_route->{list}) ) {
      if ( $list && scalar @{$list} > 0 && @{$list}[0]->{gps_time} ) {
        $last_message = "$lang{LAST} : @{$list}[0]->{gps_time}; Battery : @{$list}[0]->{battery}";
      }
    }
    
    return qq{ { "MESSAGE" : "GPS: $lang{NO_RECORD} $lang{FOR} $date .<br/> $last_message" } };
  }
  
  my $admin_gps = $route->{admin};
  
  if ( $Gps->{errno} ) {
    return "GPS tracked_admin_route_info ERROR. $Gps->{errstr}";
  }
  
  my @routes_coord_arr = ();
  my @routes_markers_arr = ();
  
  my $info = "$lang{ADMIN}: <strong>$admin_gps->{A_LOGIN}</strong><br />";
  
  foreach my $route_point ( @{$route_points} ) {
  
    $route_point->{battery} ||= 0;
    
    #Save marker
    push @routes_markers_arr, qq {
            {
              "COORDX"   : $route_point->{coord_y},
              "COORDY"   : $route_point->{coord_x},
              "INFO" : "$info <strong> $route_point->{gps_time}. Batt: $route_point->{battery}%</strong> <br />",
              "TYPE" : "user",
              "CENTERED" : "true"
            }
      };
    
    push @routes_coord_arr, '[' . $route_point->{coord_y} . ', ' . $route_point->{coord_x} . ']';
  }
  
  my $route_coords_info = join(', ', @routes_coord_arr);
  my $routes_markers = join(', ', @routes_markers_arr);
  
  my $result = qq{
  {
    "MARKERS" : [$routes_markers],
    "POLYLINE" : {
      "POINTS": [ $route_coords_info ],
      "INFOWINDOW" : "$info"
    },
    "LAYER_ID" : @{[LAYER_ID_BY_NAME->{GPS_ROUTE}]}
  }
      };
  
  if ( $attr->{EXPORT} ) {
    return $result;
  }
  
  return '';
}

#**********************************************************

=head2 maps_traffic_show($attr)

=cut

#**********************************************************
sub maps_traffic_show {
  my ($attr) = @_;
  
  my $export = $FORM{EXPORT_LIST} || $attr->{EXPORT};
  
  #my $object_info = $attr->{DATA};
  
  require Dv_Sessions;
  Dv_Sessions->import();
  my $Dv_sessions = Dv_Sessions->new($db, $admin, \%conf);
  
  our $DATE;
  $DATE ||= strftime "%Y-%m-%d", localtime(time);
  my ($y, $m) = split('-', $DATE);
  require Abills::Base;
  Abills::Base->import('days_in_month');
  
  my $builds_list = $Dv_sessions->reports2(
    {
      FROM_DATE   => "$y-$m-01",
      TO_DATE     => "$y-$m-" . (days_in_month({DATE => "$y-$m-01"})),
      TYPE        => 'BUILD',
      LOCATION_ID => '_SHOW',
      TRAFFIC_SUM => '_SHOW',
      COORDX      => '_SHOW',
      COORDY      => '_SHOW',
      COLS_NAME   => 1
    }
  );
  
  my @json_arr = ();
  foreach my $build ( @{$builds_list} ) {
    
    next if (!($build->{coordy} && $build->{coordx}));
    
    $build->{traffic_sum} = $build->{traffic_sum} * 8 / (1024 * 1024 * 1024);
    $build->{radius} = $build->{traffic_sum} * 16;
    
    my $tpl = qq{
            { "MARKER": {
                  "COORDX"   : $build->{coordy},
                  "COORDY"   : $build->{coordx},
                  "INFO" : "<strong>$lang{TRAFFIC}</strong>: $build->{traffic_sum} <strong>Gb</strong>",
                  "TYPE" : "build_green"
                },
                "CIRCLE": {"RADIUS" : $build->{radius}},
                "LAYER_ID" : @{[LAYER_ID_BY_NAME->{TRAFFIC}]}
            }
    };
    
    push @json_arr, $tpl;
  }
  
  if ( $export ) {
    return join(", ", @json_arr);
  }
  
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{TRAFFIC} } = 'TRAFFIC';
  return join(";", map { "ObjectsArray[ObjectsArray.length] = $_;" } @json_arr);
}


#**********************************************************
=head2 maps_objects_show($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub maps_objects_show {
  my ($attr) = @_;
  my $export = $FORM{EXPORT_LIST} || $attr->{EXPORT};
  
  my $custom_points_list = $Maps->points_list({
    NAME         => '_SHOW',
    ICON         => '_SHOW',
    TYPE         => '_SHOW',
    TYPE_ID      => '_SHOW',
    COORDX       => '_SHOW',
    COORDY       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    COMMENTS     => '_SHOW',
    EXTERNAL     => '0',
    COLS_NAME    => 1,
    %{ $attr ? $attr : { } },
  });
  _error_show($Maps);
  
  my %is_small_icon = (
    5 => 1,
    9 => 1,
    1 => 1
  );
  
  my @export_arr = ();
  foreach my $point ( @{$custom_points_list} ) {
    next if (!($point->{coordy} && $point->{coordx}) || (!$point->{icon}));
    
    my $info = '';
    # Show equipment info for type Equipment
    if ($point->{type_id} && $point->{type_id} == 8 && $point->{comments} && $point->{comments} =~ /NAS_ID\s*(\d+)/) {
      if ( !defined &{'equipment_location_info'} ) {
        load_module('Equipment', $html);
      }
      my $info_hash = equipment_location_info({ NAS_ID => $1 });
      if ($info_hash && $info_hash->{HTML}){
        $info = $info_hash->{HTML};
      }
    }
    
    # Show user menu for ONT type
    
    
    $point->{type} = _translate($point->{type});
    $point->{address_full} ||= '';
    
    my $icon_name = _maps_get_custom_point_icon($point->{icon});
    my $size = (exists $is_small_icon{$point->{type_id}}) ? ' 25, 25 ' : ' 32, 37 ';
    
    $info ||= "<strong>$point->{type} : </strong><a href='$SELF_URL?get_index=maps_objects_main&full=1&chg=$point->{id}'>$point->{name}</a><br/>"
      . "<i>$point->{address_full}</i><br/>";
    
    $info =~ s/\n/ /gm;
    $info =~ s/\+"+/'/gm;
    
    my $tpl = qq{
            {
             "ID"    : $point->{id},
             "OBJECT_ID" : $point->{id},
             "MARKER": {
                  "ID"        : $point->{id},
                  "OBJECT_ID" : $point->{id},
                  "COORDX"    : $point->{coordx},
                  "COORDY"    : $point->{coordy},
                  "SIZE"      : [ $size ],
                  "INFO" : "$info",
                  "TYPE" : "$icon_name"
                },
             "LAYER_ID" : @{[LAYER_ID_BY_NAME->{CUSTOM_POINT}]}
            }
    };
    
    push @export_arr, $tpl;
  }
  
  if ( $export ) {
    return join(", ", @export_arr);
  }
  
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{CUSTOM_POINT} } = 'CUSTOM_POINT';
  return join(";", map { "ObjectsArray[ObjectsArray.length] = $_ ;" } @export_arr);
}

#**********************************************************

=head2 maps_terminals_show()

=cut

#**********************************************************
sub maps_terminals_show {
  
  unless ( in_array('Paysys', \@MODULES) ) {
    return '';
  }
  
  require Paysys;
  Paysys->import();
  my $Paysys = Paysys->new( $db, $admin, \%conf );
  
  my $terminals_list = $Paysys->terminal_list( {
    SHOW_ALL_COLUMNS => 1,
    TYPE             => '_SHOW',
    TYPE_ID          => '_SHOW',
    COMMENT          => '_SHOW',
    DIS_NAME         => '_SHOW',
    ST_NAME          => '_SHOW',
    BD_NUMBER        => '_SHOW',
    COLS_NAME        => 1,
    PAGE_ROWS        => 10000,
    LOCATION_ID      => '!',
    COORDX           => '!',
    COORDY           => '!',
  } );
  _error_show($Paysys);
  
  my @export_arr = ();
  foreach my $point ( @{$terminals_list} ) {
    
    next if (!($point->{coordy} && $point->{coordx}));
    
    my $type_id = $point->{type_id} || 2;
    my $type_name = $point->{name} || 'PrivatBank';
    my $id = $point->{id} || 1;
    
    $point->{comment} //= '';
    $point->{dis_name} //= '';
    $point->{st_name} //= '';
    $point->{bd_number} //= '';
    
    my $info =
      "<strong>$lang{TYPE}</strong>: $type_name </br>"
        . "<strong>$lang{ADDRESS} </strong> $point->{dis_name}, $point->{st_name}, $point->{bd_number}</br>"
        . ($point->{comment} ? "</hr>$point->{comment}" : '');
    
    my $tpl = qq{
            {
              "MARKER": {
                "ID"       : $id,
                "COORDX"   : $point->{coordy},
                "COORDY"   : $point->{coordx},
                "INFO"     : "$info",
                "TYPE"     : "/images/terminals/terminal_$type_id.png"
              },
              "LAYER_ID" : @{[LAYER_ID_BY_NAME->{CUSTOM_POINT}]}
            }
    };
    
    push @export_arr, $tpl;
  }
  
  if ( $FORM{EXPORT_LIST} ) {
    return join(", ", @export_arr);
  }
  
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{CUSTOM_POINT} } = 'CUSTOM_POINT';
  return join(";", map { "ObjectsArray[ObjectsArray.length] = $_ ;" } @export_arr);
}

#**********************************************************
=head2 maps_districts_show()

=cut
#**********************************************************
sub maps_districts_show {
  my $attr = shift;
  
  my $districts_list = $Maps->districts_list({
    OBJECT_ID        => $attr->{ID} || '_SHOW',
    DISTRICT_ID      => $FORM{DISTRICT_ID} || '_SHOW',
    DISTRICT         => '_SHOW',
    #    SHOW_ALL_COLUMNS => 1,
    LIST2HASH        => 'object_id,district_id'
  });
  _error_show($Maps);
  
  my $district_for_object_id = sort_array_to_hash($districts_list, 'object_id');
  
  my @object_ids = map { $_->{object_id} } @{$districts_list};
  
  my $layer_objects = _maps_get_layer_objects(LAYER_ID_BY_NAME->{DISTRICT}, {
      ID => join(';', @object_ids)
    });
  _error_show($Maps);
  
  
  
  foreach my $object (@$layer_objects){
    #    _bp('objet', $object, {TO_CONSOLE => 1});
    $object->{POLYGON}{name} = $district_for_object_id->{$object->{OBJECT_ID}}{district};
  }
  
  if ( $attr->{EXPORT} ) {
    return join(', ', map { JSON::to_json($_) } @{$layer_objects});
  }
  
  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{DISTRICT} } = 'DISTRICT';
  return join(";", map { "ObjectsArray[ObjectsArray.length] = " . JSON::to_json($_) } @{$layer_objects});
}

#**********************************************************

=head2 maps_location_info($attr) - Returns geolocation information about object

  Arguments:
    $attr
      LOCATION_ID   - location id
      TYPE          - map object type

  Returns:
    hash_ref
      HTML  - content for infowindow
      count - numeric label for marker

=cut

#**********************************************************
sub maps_location_info {
  my ($attr) = @_;
  return unless ($attr->{LOCATION_ID});
  $attr->{TYPE} ||= 'BUILD';
  
  my $info = '';
  my $count = 0;
  my $color = '';
  
  state $users_for_location_id;
  state $online_uids;
  if (! $online_uids){
    $online_uids = _maps_get_online_users({SHORT => 1});
  }
  if ( !$users_for_location_id ) {
    my $users_list = _maps_get_users({ RETURN_AS_ARRAY => 1 });
    foreach my $user ( @{$users_list} ) {
      my $location_id = $user->{build_id};
      next unless ($location_id);
      
      if (exists $online_uids->{$user->{uid}} ){
        $user->{online} = 1;
      }
      
      # Sort to hash_ref of  array_refs
      if ( $users_for_location_id->{$location_id} ) {
        push(@{ $users_for_location_id->{$location_id} }, $user);
      }
      else {
        $users_for_location_id->{$location_id} = [ $user ];
      }
    }
  }
  
  if ( defined $users_for_location_id->{ $attr->{LOCATION_ID} } ) {
    $info = maps_point_info_table(
      {
        OBJECTS           => $users_for_location_id->{ $attr->{LOCATION_ID} },
        TABLE_TITLES      => [ 'ONLINE', 'LOGIN', 'DEPOSIT', 'FIO', 'ADDRESS_FLAT' ],
        TABLE_LANG_TITLES => [ $lang{ONLINE}, '', $lang{DEPOSIT}, $lang{USER}, $lang{FLAT} ],
      }
    );
    $count = scalar @{ $users_for_location_id->{ $attr->{LOCATION_ID} } };
    
    if ($conf{MAPS_BUILD_COLOR_BY_ONLINE}){
      $color = ( grep { $_->{online} && $_->{online} == 1 } @{ $users_for_location_id->{ $attr->{LOCATION_ID} } } )
        ? 'green'
        : 'red'
    }
    
  }
  elsif ($FORM{GROUP_ID}) {
    return 0;
  }
  
  return {
    HTML  => $info,
    COUNT => $count,
    COLOR => $color
  }
  
}

#**********************************************************

=head2 maps_info_modules_list()

=cut

#**********************************************************
sub maps_info_modules_list {
  
  my @result_list = ();
  
  our @MAPS_INFO_MODULES;
  my @ext_modules = ('Msgs', 'Maps', 'Equipment', @MAPS_INFO_MODULES);
  
  foreach my $module_name ( @ext_modules ) {
    load_module($module_name, $html);
    my $fn_name = lc($module_name . "_location_info");
    if ( defined &{$fn_name} ) {
      
      push(@result_list, $module_name);
    }
  }
  
  return \@result_list;
}


#**********************************************************

=head2 maps_load_info($attr) - Loads information for location from specified module

  Arguments:
    $attr - hash_ref
      LOCATION_ID   - location id
      TYPE          - map object type

  Returns:
    hash_ref
      HTML  - Infowindow content
      COUNT - count for object

=cut

#**********************************************************
sub maps_load_info {
  my $module_name = $FORM{INFO_MODULE} || 'Maps';
  
  my $fn_name = lc "$module_name\_location_info";
  if ( !defined &{$fn_name} ) {
    load_module($module_name, $html);
  }
  
  if ( defined &{$fn_name} ) {
    my $result = &{ \&{$fn_name} }(@_);
    if ( $result && $result->{HTML} ) {
      $result->{HTML} =~ s/\n/ /gm;
      $result->{HTML} =~ s/\+"+/'/gm;
      return $result;
    }
  }
  
  return { };
}


#**********************************************************

=head2 _maps_points_count($list, $object_info, $attr) - Counts points

  Arguments:
    $list - arr_ref for DB list
    $object_info - DB list
    $attr - hash_ref
      KEY    - string, key for which to count

  Returns:
    arr_ref - array that contains sorted count

=cut

#**********************************************************
sub _maps_points_count {
  my ($list, $object_info, $attr) = @_;
  my $key = (defined $attr->{KEY}) ? $attr->{KEY} : 'id';
  
  my %max_objects_on_point = ();
  foreach my $line ( @{$list} ) {
    if ( $object_info->{ $line->{$key} } ) {
      $max_objects_on_point{ $line->{$key} } = $#{ $object_info->{ $line->{$key} } } + 1;
    }
  }
  
  my @max_arr = sort { $b <=> $a } values %max_objects_on_point;
  
  return \@max_arr;
}

#**********************************************************

=head2 _maps_point_color($point_count, $max_points) - get color for point

  Arguments:
    $point_count  - Point object count
    $max_points   - Points max objects

  Returns:
    string - color name

=cut

#**********************************************************
sub _maps_point_color {
  my ($point_count, $max_points) = @_;
  
  my $color = 'grey';
  
  return $color unless ($point_count);
  
  #Fire for top 3
  if ( $point_count > 2 && $max_points->[2] && $point_count >= $max_points->[2] ) {
    $color = 'fire';
  }
  
  #Other points by colors
  elsif ( $point_count > 0 && $point_count < 3 ) {
    $color = 'grey';
  }
  elsif ( $point_count < 5 ) {
    $color = 'green';
  }
  elsif ( $point_count < 10 ) {
    $color = 'blue';
  }
  elsif ( $point_count >= 10 ) {
    $color = 'yellow';
  }
  
  return $color;
}

#**********************************************************
=head2 _maps_get_custom_point_icon()

=cut
#**********************************************************
sub _maps_get_custom_point_icon {
  my ($icon) = @_;
  
  if ( $icon !~ /^https?\:\/\//o ) {
    my $has_extension = $icon =~ /\.\w{3,4}$/o;
    
    if ( $has_extension ) {
      $icon =~ s/\.\w{3,4}$//;
    }
  }
  
  return $icon;
}

1;