#package Cablecat::Layers;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Cablecat::Layers

=head2 SYNOPSIS

  This package aggregates Maps integration

=cut

our (%lang, $html, %permissions, $Cablecat, $Maps, %MAP_TYPE_ID, %MAP_LAYER_ID);

#**********************************************************
=head2 cablecat_maps_layers()

=cut
#**********************************************************
sub cablecat_maps_layers {
  return {
    LAYERS      => [
      {
        id            => 10,
        name          => 'CABLES',
        lang_name     => $lang{CABLES},
        module        => 'Cablecat',
        structure     => 'POLYLINE',
        clustering    => 0,
        add_func      => 'cablecat_cables',
        custom_params => {
          OBJECT_TYPE_ID               => $MAP_TYPE_ID{CABLE},
          SAVE_AS_GEOMETRY             => 1,
          CALCULATE_PARAMS_JS_FUNCTION => 'findClosestWellsForCable'
        }
      }, {
      id            => 11,
      name          => 'WELLS',
      lang_name     => $lang{WELLS},
      module        => 'Cablecat',
      structure     => 'MARKER',
      clustering    => 1,
      add_func      => 'cablecat_wells',
      custom_params => {
        OBJECT_TYPE_ID => $MAP_TYPE_ID{WELL}
      }
    }
    ],
    SCRIPTS     => [ '/styles/default_adm/js/maps/modules/cablecat.js' ],
    EXPORT_FUNC => {
      10 => 'cablecat_maps_cables',
      11 => 'cablecat_maps_wells',
    }
  }
}

#**********************************************************
=head2 cablecat_maps_cables()

=cut
#**********************************************************
sub cablecat_maps_cables {

  my $cables_list = $Cablecat->cables_list({
    POINT_ID          => $FORM{OBJECT_ID} || $FORM{POINT_ID} || '!',
    NAME              => '_SHOW',
    CABLE_TYPE        => '_SHOW',
    WELL_1            => '_SHOW',
    WELL_2            => '_SHOW',
    WELL_1_ID         => '_SHOW',
    WELL_2_ID         => '_SHOW',
    OUTER_COLOR       => '_SHOW',
    LINE_WIDTH        => '_SHOW',
    LENGTH            => '_SHOW',
    LENGTH_CALCULATED => '_SHOW',
    CAN_BE_SPLITTED   => '_SHOW',
    COMMENTS          => '_SHOW',
    PAGE_ROWS         => 10000
  });
  _error_show($Cablecat);

  # Get all current active objects that cables are linked to
  my @object_ids = map {+$_->{point_id}} @{$cables_list};

  # Joining for DB searching
  my $point_ids = join(';', @object_ids);

  my $points_list = $Maps->points_list({ ID => $point_ids, SHOW_ALL_COLUMNS => 1, EXTERNAL => 1, PAGE_ROWS => 10000 });
  my $layer_objects = _maps_get_layer_objects(10, { OBJECT_ID => $point_ids });

  # Sorting to hashes
  my $points_by_id = sort_array_to_hash($points_list, 'id');
  my $cable_by_point_id = sort_array_to_hash($cables_list, 'point_id');
  my $layer_objects_by_point_id = sort_array_to_hash($layer_objects, 'OBJECT_ID');

  # Caching indexes
  my $well_index = get_function_index('cablecat_wells');
  my $cables_index = get_function_index('cablecat_cables');

  my @objects_to_show = ();
  # Apply cable_info to geometric figures
  foreach (@object_ids) {
    my $cable = $cable_by_point_id->{$_};
    next if (!$cable->{point_id} || !$cable->{id});

    my $polyline = $layer_objects_by_point_id->{$_}->{POLYLINE};
    next if (!$polyline->{id});

    my $point = $points_by_id->{$_};
    next if (!$point);

    $layer_objects_by_point_id->{$_}->{OBJECT_ID} = $point->{id};

    my $line_info = arrays_array2table([
      [ $lang{CABLE}, $html->button($cable->{name}, "index=$cables_index&chg=$cable->{id}", { target => '_blank' }) ],
      [ $lang{CABLE_TYPE}, $cable->{cable_type} ],
      [ "$lang{WELL} 1", ($cable->{well_1} && $cable->{well_1_id})
        ? $html->button($cable->{well_1}, "index=$well_index&chg=$cable->{well_1_id}", { target => '_blank' })
        . maps_show_object_button(11, $cable->{well_1_id})
        : $lang{NO}
      ],
      [ "$lang{WELL} 2", ($cable->{well_2} && $cable->{well_2_id})
        ? $html->button($cable->{well_2}, "index=$well_index&chg=$cable->{well_2_id}", { target => '_blank' })
        . maps_show_object_button(11, $cable->{well_2_id})
        : $lang{NO}
      ],
      [ $lang{LENGTH}, "$cable->{length}, ( $cable->{length_calculated} )" ],
      [ $lang{COMMENTS}, $point->{comments} ],
    ]);

    if ($point->{planned}) {
      $polyline->{strokeOpacity} = '0.5';
    }

    $layer_objects_by_point_id->{$_}->{ID} = $cable->{id};

    #TODO: check which case is required
    $polyline->{id} = $cable->{id};
    $polyline->{ID} = $cable->{id};

    $polyline->{name} = $cable->{name} || '';

    $polyline->{strokeColor} = $cable->{outer_color};
    $polyline->{strokeWeight} = $cable->{line_width} || 1;

    $polyline->{INFOWINDOW} = $line_info;

    if ($FORM{EDIT_MODE}) {
      my $add_inside_link = "$SELF_URL?get_index=cablecat_wells&header=2&add_reserve_form=1";
      my $split_btn = '';
      if ($cable->{can_be_splitted}) {
        $split_btn = qq{<button class="btn btn-default" title="$lang{ADD} $lang{WELL}" onclick="insert_well_on_cable($cable->{id})">
        <span class="glyphicon glyphicon-sound-stereo"></span>
      </button>
      <button class="btn btn-default btn-sm" title="Split cable" onclick="split_cable($cable->{id})">
        <div class="text-small">
          <span class="glyphicon glyphicon-arrow-left"></span>
          <span class="glyphicon glyphicon-arrow-right"></span>
        </div>
      </button>
      }
      }
      my $edit_buttons = qq{
      $split_btn
      <button class="btn btn-danger" onclick="showRemoveConfirmModal({ layer_id : 10, object_id : $polyline->{object_id}, cable_id : $cable->{id} })">
        <span class="glyphicon glyphicon-remove"></span><span>$lang{DEL}</span>
      </button>
    };

      my $add_well_link = "$SELF_URL?get_index=cablecat_cables&header=2&add_well=1";
      $polyline->{ADD_WELL_LINK} = $add_well_link;
      $polyline->{CABLE_ID} = $cable->{id};
      $polyline->{CABLE_CAT} = "<span class='glyphicon glyphicon-scissors'></span><span> $lang{CAT_CABLE}</span>";

      $polyline->{INFOWINDOW} .= $edit_buttons;
      $polyline->{LAYER_ID} = 10;
      $polyline->{ADD_RESERVER} = $lang{ADD} . " " . $lang{CABLE_RESERVE};
      $polyline->{INSIDE_LINK} = $add_inside_link;
    }

    push @objects_to_show, $layer_objects_by_point_id->{$_};
  }

  return join ',', map {JSON::to_json($_, { utf8 => 0 })} @objects_to_show;
}

#**********************************************************
=head2 cablecat_maps_cables_geometry_filter($object_id, $objects_array)

=cut
#**********************************************************
sub cablecat_maps_cables_geometry_filter {
  my ($object_id, $geometry) = @_;

  # Sanitize input
  if (!$object_id
    || !ref $geometry eq 'ARRAY'
    || !scalar(@{$geometry})
    || !$geometry->[0]->{TYPE}
    || !$geometry->[0]->{TYPE} eq 'polyline'
    || !$geometry->[0]->{OBJECT}
    || !$geometry->[0]->{OBJECT}->{POINTS}
    || !ref $geometry->[0]->{OBJECT}->{POINTS} eq 'ARRAY'
    || !scalar(@{$geometry->[0]->{OBJECT}->{POINTS}})
  ) {
    return $geometry;
  };

  # Normally cable will receive only one polyline
  my @polyline_points = @{$geometry->[0]->{OBJECT}->{POINTS}};

  my $cables_list = $Cablecat->cables_list({
    POINT_ID  => $object_id,
    WELL_1_ID => '_SHOW',
    WELL_2_ID => '_SHOW',
  });

  if ($cables_list && ref $cables_list eq 'ARRAY' && scalar @{$cables_list}) {

    # Caching well_id_coords
    my %well_coords = ();

    my $get_cached_coords_for_well = sub {
      my ($well_id) = @_;

      if (!exists $well_coords{$well_id}) {
        my $coords = $Cablecat->wells_coords($well_id);
        $well_coords{$well_id} = [ $coords->{coordx}, $coords->{coordy} ];
      }

      $well_coords{$well_id};
    };

    # Normally, there should be only one object, but should be ready
    foreach my $cable (@{$cables_list}) {
      if ($cable->{well_1_id}) {
        $polyline_points[0] = $get_cached_coords_for_well->($cable->{well_1_id});
      }

      if ($cable->{well_2_id}) {
        $polyline_points[$#polyline_points] = $get_cached_coords_for_well->($cable->{well_2_id});
      }
    }
  }

  $geometry->[0]->{OBJECT}->{POINTS} = \@polyline_points;

  return $geometry;
}

#**********************************************************
=head2 cablecat_maps_wells()

=cut
#**********************************************************
sub cablecat_maps_wells {
  my $wells_list = $Cablecat->wells_list({
    POINT_ID  => $FORM{OBJECT_ID} || $FORM{POINT_ID} || '!',
    NAME      => '_SHOW',
    TYPE_ID   => '_SHOW',
    ICON      => '_SHOW',
    COMMENTS  => '_SHOW',
    PAGE_ROWS => 10000
  });
  _error_show($Cablecat);

  my $coils_list = $Cablecat->coil_list({
    POINT_ID  => '_SHOW',
    NAME      => '_SHOW',
    CABLE_ID  => '_SHOW',
    ID        => '_SHOW',
    PAGE_ROWS => 10000
  });
  _error_show($Cablecat);

  my @object_ids = map {$_->{point_id}} @{$wells_list};

  my $point_ids = join(';', @object_ids);
  _error_show($Maps);

  my $points_list = $Maps->points_list({
    ID               => $point_ids,
    SHOW_ALL_COLUMNS => 1,
    NAME             => '_SHOW',
    ICON             => '_SHOW',
    TYPE             => '_SHOW',
    TYPE_ID          => '_SHOW',
    COORDX           => '!',
    COORDY           => '!',
    COLS_NAME        => 1,
    ADDRESS_FULL     => '_SHOW',
    EXTERNAL         => 1,
  });

  my $points_by_id = sort_array_to_hash($points_list);
  my $well_by_point_id = sort_array_to_hash($wells_list, 'point_id');
  my $wells_index = get_function_index('cablecat_wells');

  my @layer_objects = ();

  # Apply cable_info to geometric figures

  foreach (@object_ids) {
    my $well = $well_by_point_id->{$_};
    my $point = $points_by_id->{$_};

    my $icon_name = $well->{icon} || $point->{icon} || 'well_green';

    next if (!($point->{coordx} && $point->{coordy}));

    my $marker_info = '';
    my $edit_buttons = '';
    $marker_info = arrays_array2table([
      [ $lang{WELL}, $html->button($well->{name}, "index=$wells_index&chg=$well->{id}", { target => '_blank' }) ],
      [ $lang{INSTALLED}, $point->{planned} ? $lang{NO} : $lang{YES} ],
      [ $lang{COMMENTS}, $point->{comments} ],
    ]);

    if ($permissions{5} && $FORM{EDIT_MODE}) {
      my $add_inside_link = "$SELF_URL?get_index=cablecat_wells&header=2"
        . "&add_form=1&PARENT_ID=$well->{id}&POINT_ID=$point->{id}&TEMPLATE_ONLY=1";

      $edit_buttons = qq{
          <button class="btn btn-danger" onclick="showRemoveConfirmModal({ layer_id : 11, id : $point->{id}, well_id : $well->{id} })">
            <span class="glyphicon glyphicon-remove"></span><span>$lang{DEL}</span>
          </button>
          <button class="btn btn-success"
           onclick="loadToModal('$add_inside_link')">
            <span class="glyphicon glyphicon-plus"></span><span>$lang{ADD}</span>
          </button>
        };
    }

    $marker_info .= $edit_buttons;

    push @layer_objects, {
      ID        => +$well->{id},
      OBJECT_ID => $point->{id},
      MARKER    => {
        OBJECT_ID => $point->{id},
        NAME      => $well->{name},
        ID        => +$well->{id},
        COORDX    => $point->{coordx},
        COORDY    => $point->{coordy},
        INFO      => "$marker_info",
        TYPE      => "$icon_name",
        SIZE      => [ 25, 25 ],
        CENTERED  => 1,
      },
      LAYER_ID  => 11
    }
  }

  # Coil information
  @object_ids = map {$_->{point_id}} @{$coils_list};

  $point_ids = join(';', @object_ids);

  $points_list = $Maps->points_list({
    ID               => $point_ids,
    SHOW_ALL_COLUMNS => 1,
    NAME             => '_SHOW',
    ICON             => '_SHOW',
    TYPE             => '_SHOW',
    TYPE_ID          => '_SHOW',
    COORDX           => '!',
    COORDY           => '!',
    COLS_NAME        => 1,
    ADDRESS_FULL     => '_SHOW',
    EXTERNAL         => 1,
  });
  _error_show($Maps);

  $points_by_id = sort_array_to_hash($points_list);
  my $coil_by_point_id = sort_array_to_hash($coils_list, 'point_id');
  foreach (@object_ids) {
    my $coil = $coil_by_point_id->{$_};
    my $point = $points_by_id->{$_};

    my $icon_name = 'coil';

    next if (!($point->{coordx} && $point->{coordy}));

    my $marker_info = '';
    my $edit_buttons = '';
    $marker_info = arrays_array2table([
      [ $lang{CABLE_RESERVE}, $html->button($coil->{name}, "index=$wells_index&chg=$coil->{id}", { target => '_blank' }) ],
      [ $lang{INSTALLED}, $point->{planned} ? $lang{NO} : $lang{YES} ],
      [ $lang{CABLE} . " Id", $coil->{cable_id} ],
      [ $lang{COMMENTS}, $point->{comments} ],
    ]);

    if ($permissions{5} && $FORM{EDIT_MODE}) {

      $edit_buttons = qq{
          <button class="btn btn-danger" onclick="showRemoveConfirmModal({ layer_id : 11, id : $point->{id} })">
            <span class="glyphicon glyphicon-remove"></span><span>$lang{DEL}</span>
          </button>
        };
    }

    $marker_info .= $edit_buttons;

    push @layer_objects, {
      ID        => 9999 + $coil->{id},
      OBJECT_ID => $point->{id},
      MARKER    => {
        OBJECT_ID => $point->{id},
        NAME      => $coil->{name},
        ID        => +$coil->{id},
        COORDX    => $point->{coordx},
        COORDY    => $point->{coordy},
        INFO      => "$marker_info",
        TYPE      => "$icon_name",
        SIZE      => [ 25, 25 ],
        CENTERED  => 1,
      },
      LAYER_ID  => 11
    }
  }

  return join(',', map {JSON::to_json($_, { utf8 => 0 })} @layer_objects);
}

#**********************************************************
=head2 cablecat_maps_ajax()

=cut
#**********************************************************
sub cablecat_maps_ajax {

  if ($FORM{SPLIT_CABLE} && $FORM{CABLE_ID}) {
    push(@{$html->{JSON_OUTPUT}},
      {
        result => _cablecat_break_cable_in_two_parts($FORM{CABLE_ID})
      }
    );
  }

  return 1;
}



1;