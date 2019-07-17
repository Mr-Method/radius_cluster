package Address;

=head1 NAME

  Address manage functions

=cut

use strict;
use parent 'dbcore';
use Conf;

our $VERSION = 2.05;
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = '';
  $CONF->{BUILD_DELIMITER} = ',' if (! defined($CONF->{BUILD_DELIMITER})) ;

  if(ref $admin eq 'HASH') {
    print ref $admin;
    print "Address ADMIN NOT FOUND//// $admin ///";
    exit;
  }

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}


#**********************************************************
=head2 address_info($id) - Address register full address info

  Arguments:
    $id  - Location id

  Returns:
    Address object
      DISTRICT_ID
      CITY
      ADDRESS_DISTRICT
      ADDRESS_STREET
      ADDRESS_BUILD
      STREET_ID
      ZIP
      COORDX

=cut
#**********************************************************
sub address_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT d.id AS district_id,
      d.city,
      d.name AS address_district,
      s.name AS address_street,
      b.number AS address_build,
      b.block AS address_block,
      s.id AS street_id,
      s.type AS street_type,
      d.zip,
      s.second_name,
      b.coordx,
      s.second_name AS address_street2
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id= ? ",
     undef,
     { INFO => 1,
       Bind => [ $id ]
       }
    );

  return $self;
}

#**********************************************************
=head2 address_list($attr) - returns list of all builds in DB

  Arguments:
    $attr - hash_ref, reserved for future

  Returns:
    Address_list
      DISTRICT_ID
      DISTRICT_NAME
      STREET_ID
      STREET_NAME
      STREET_DISTRICT_ID
      BUILD_ID
      BUILD_NAME
      BUILD_STREET_ID

=cut
#**********************************************************
sub address_list {
  my $self = shift;

  $self->query("SELECT
      d.id            AS district_id,
      d.name          AS district_name,
      s.id            AS street_id,
      s.name          AS street_name,
      s.district_id   AS street_district_id,
      b.id            AS build_id,
      b.number        AS build_name,
      b.street_id     AS build_street_id
    FROM districts d
    LEFT JOIN streets s ON (d.id = s.district_id)
    LEFT JOIN builds b ON (s.id = b.street_id)
    WHERE b.id IS NOT NULL
    ORDER BY district_name;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list};
};

#**********************************************************
=head2 address_parentness($in_array_func, $attr) - Build an parentness tree for districts->streets->builds

  We need to pass here an $in_array function to avoid using Base.pm

  Arguments:
    $in_array_func - refference for a in_array function
    $attr - hash_ref
      STREETS - boolean (do not make builds)



  Returns:
    $list - DB list of builds
    $parentness_hash - districts->streets->builds ierarchy. You can read more doc in HTML::build_parentness_tree()

=cut
#**********************************************************
sub address_parentness {
  my $self = shift;
  my ($in_array_func, $attr) = @_;

  my $list = $self->address_list();

  #Build an parentness tree for districts->streets->builds structures
  my %street_district = ();
  my $filled_streets = [];
  foreach my $hash ( @{ $list } ){
    if (&$in_array_func($hash->{STREET_ID}, $filled_streets)){ next; }

    if ( $street_district{ $hash->{STREET_DISTRICT_ID} } ){
      push @{ $street_district{ $hash->{STREET_DISTRICT_ID} } }, $hash->{STREET_ID};
    }
    else {
      $street_district{ $hash->{STREET_DISTRICT_ID} } = [ $hash->{STREET_ID} ];
    }

    push @{ $filled_streets }, $hash->{STREET_ID};
  }

  my %build_street = ();
  my $filled_builds = [];
  unless ($attr->{STREETS}) {
    foreach my $hash (@{ $list }) {
      if (!$hash->{BUILD_ID} || &{$in_array_func}( $hash->{BUILD_ID}, $filled_builds )) { next; }

      $build_street{ $hash->{BUILD_STREET_ID} }{ $hash->{BUILD_ID} } = '';

      push @{ $filled_builds }, $hash->{BUILD_ID};
    }
  }

  #Replacing street ids in %street_district with a street->builds hash to get a 3 level hash
  foreach my $district_id (keys %street_district){
    my @street_arr = @{ $street_district{$district_id} };

    my $new_hash = { };
    unless ($attr->{STREETS}) {
      foreach my $street_id (@street_arr) {
        $new_hash->{$street_id} = $build_street{$street_id};
      }
    }
    else {
      foreach my $street_id (@street_arr) {
        $new_hash->{$street_id} = $street_id;
      }
    }
    $street_district{$district_id} = $new_hash;
  }

  return ($list, \%street_district);
}

#**********************************************************
=head2 district_list($attr) - District list

=cut
#**********************************************************
sub district_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if($admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  my $WHERE = $self->search_former($attr, [
      ['ID',          'INT',  'd.id'       ],
      ['NAME',        'STR',  'd.name'     ],
      ['COMMENTS',    'STR',  'd.comments' ],
      ['DOMAIN_ID',   'INT',  'd.domain_id'],
      ['COORDX',      'INT',  'd.coordx', 1],
      ['COORDY',      'INT',  'd.coordy', 1],
      ['ZOOM',        'INT',  'd.zoom',   1],
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT d.id,
       d.name,
       d.country,
       d.city,
       zip,
       $self->{SEARCH_FIELDS}
       COUNT(s.id) AS street_count
     FROM districts d
     LEFT JOIN streets s ON (d.id=s.district_id)
   $WHERE
   GROUP BY d.id
   ORDER BY $SORT $DESC",
   undef,
   $attr
  );

  if($self->{errno}) {
    return [];
  }

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total FROM districts d $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 district_info($attr)

=cut
#**********************************************************
sub district_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT id, name, country,
 city, zip, comments, coordx, coordy, zoom
  FROM districts WHERE id= ? ;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 district_change($attr)

=cut
#**********************************************************
sub district_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'districts',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 district_add($attr) - Add district

=cut
#**********************************************************
sub district_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add("districts", {
    %$attr,
    DOMAIN_ID => $attr->{DOMAIN_ID} || $admin->{DOMAIN_ID} || 0
  });

  $admin->system_action_add("DISTRICT:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});

  return $self;
}

#**********************************************************
=head2 district_del($id) - District name

=cut
#**********************************************************
sub district_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('districts', { ID => $id });

  $admin->system_action_add("DISTRICT:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
=head2 street_list($attr) - Street list

=cut
#**********************************************************
sub street_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if($admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  my $WHERE = $self->search_former($attr, [
      ['STREET_NAME',   'STR', 's.name',  's.name AS street_name'        ],
      ['SECOND_NAME',   'STR', 's.second_name',                        1 ],
      ['BUILD_COUNT',   'INT', 'COUNT(DISTINCT b.id) AS build_count', 'COUNT(DISTINCT b.id) AS build_count' ],
      (! $admin->{MAX_ROWS}) ? ['USERS_COUNT',   'STR', '',    'COUNT(pi.uid) AS users_count' ] : [],
      ['DISTRICT_NAME', 'STR', 'd.name',  'd.name AS district_name'      ],
      ['DISTRICT_ID',   'STR', 's.district_id',                        1 ],
      ['TYPE',          'INT', 's.type',                               1 ],
      ['BUILD_NUMBER',  'STR', 'b.number',  'b.number AS build_number',1 ],
      ['BUILD_FLATS',   'INT', 'b.flats','b.number AS build_flats',    1 ],
      ['DOMAIN_ID',     'INT', 'd.domain_id',                            ],
      ['TYPE',          'INT', 's.type',                                 ],
      ['ID',            'INT', 's.id',                                   ]
    ],
    { WHERE => 1,
    }
  );

  my $EXT_TABLE        = '';
  my $EXT_TABLE_TOTAL  = '';
  my $EXT_FIELDS_TOTAL = '';

  if ($attr->{USERS_COUNT} && !$admin->{MAX_ROWS}) {
    $EXT_TABLE        = 'LEFT JOIN users_pi pi ON (b.id=pi.location_id)';
    #$self->{SEARCH_FIELDS}  = . $self->{SEARCH_FIELDS};
    $EXT_TABLE_TOTAL  = ' LEFT JOIN builds b ON (b.street_id=s.id) LEFT JOIN users_pi pi ON (b.id=pi.location_id)';
    $EXT_FIELDS_TOTAL = ', COUNT(DISTINCT b.id), COUNT(pi.uid), SUM(b.flats) / COUNT(pi.uid)';
  }

  my $sql = "SELECT s.id,
    $self->{SEARCH_FIELDS}
    s.id AS street_id,
    s.type
  FROM streets s
  LEFT JOIN districts d ON (s.district_id=d.id)
  LEFT JOIN builds b ON (b.street_id=s.id)
  $EXT_TABLE
  $WHERE
  GROUP BY s.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;";

  $self->query($sql, undef, $attr);

  return [] if $self->{errno};

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $sql = "SELECT COUNT(DISTINCT s.id) $EXT_FIELDS_TOTAL FROM streets s
      LEFT JOIN districts d ON (s.district_id=d.id)
      $EXT_TABLE_TOTAL  $WHERE";
    $self->query($sql);

    if($self->{TOTAL} > 0) {
      ($self->{TOTAL}, $self->{TOTAL_BUILDS}, $self->{TOTAL_USERS},
        $self->{DENSITY_OF_CONNECTIONS}) = @{ $self->{list}->[0] };
    }
    else {
      ($self->{TOTAL}, $self->{TOTAL_BUILDS}, $self->{TOTAL_USERS},
        $self->{DENSITY_OF_CONNECTIONS}) = (0,0,0,0);
    }
  }

  return $list;
}

#**********************************************************
=head2 street_info($attr)

=cut
#**********************************************************
sub street_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM streets WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ]
    });

  return $self;
}

#**********************************************************
=head2 street_change($attr)

=cut
#**********************************************************
sub street_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'streets',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 street_add($attr)

=cut
#**********************************************************
sub street_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add("streets", $attr);

  $admin->system_action_add("STREET:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
=head2 street_del($id)

=cut
#**********************************************************
sub street_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('streets', { ID => $id });

  $admin->system_action_add("STREET:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
=head2 build_list($attr)

=cut
#**********************************************************
sub build_list {
  my $self = shift;
  my ($attr) = @_;
  
  if($admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($SORT == 1 && $DESC eq '') {
    $SORT = "b.number*1";
  }

  my $maps_google_fields = '';
  if ($attr->{SHOW_MAPS_GOOGLE}) {
    push @WHERE_RULES, "(b.coordx<>0 and b.coordy)";
    $maps_google_fields = "b.coordx, b.coordy, ";
  }

  my $WHERE = $self->search_former($attr, [
      ['NUMBER',            'STR', 'b.number',         ],
      ['BLOCK',             'STR', 'b.block',        1 ],
      ['FLORS',             'INT', 'b.flors',        1 ],
      ['ENTRANCES',         'INT', 'b.entrances',    1 ],
      ['FLATS',             'INT', 'b.flats',        1 ],
      ['SCHEMA',            'INT', 'b.schema',       1 ],
      ['DISTRICT_ID',       'INT', 's.district_id',  1 ],
      ['DISTRICT_NAME',     'INT', 'd.name AS district_name',       1 ],
      ['STREET_NAME',       'INT', 's.name', 's.name AS street_name'  ],
      ['USERS_COUNT',       'INT', '', 'COUNT(pi.uid) AS users_count' ],
      ['USERS_CONNECTIONS', 'INT', '', 'ROUND((COUNT(pi.uid) / b.flats * 100), 0) AS users_connections' ],
      ['ADDED',             'DATE','b.added',        1 ],
      ['YANDEX_0',          'INT', 'yandex_0',       1 ],
      ['YANDEX_1',          'INT', 'yandex_1',       1 ],
      ['GOOGLE_X',          'INT', 'coordx',         1 ],
      ['GOOGLE_Y',          'INT', 'coordy',         1 ],
      ['LOCATION_ID',       'INT', 'b.id',   'b.id AS location_id' ],
      ['COORDX',            'INT', 'b.coordx',       1 ],
      ['COORDY',            'INT', 'b.coordy',       1 ],
      ['ZOOM',              'INT', 'd.zoom',         1 ],
      ['STREET_ID',         'INT', 'b.street_id',      ],
      ['ZIP',               'INT', 'b.zip',    'b.zip' ],
      ['PUBLIC_COMMENTS',   'STR', 'b.public_comments',    1 ],
      ['PLANNED_TO_CONNECT','STR', 'b.planned_to_connect', 1 ],
      ['NUMBERING_DIRECTION','STR', 'b.numbering_direction', 1 ],
      ['DOMAIN_ID',         'INT', 'd.domain_id',          1 ],
      ['CITY',              'INT', 'd.city',         1 ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->{SEARCH_FIELDS} .= $maps_google_fields;
  my $EXT_TABLES = '';

  if ($self->{SEARCH_FIELDS} =~ /s\.|d\./) {
    if($attr->{WITH_STREETS_ONLY}) {
      $EXT_TABLES = 'INNER JOIN streets s ON (s.id=b.street_id)';
    }
    else {
      $EXT_TABLES = 'LEFT JOIN streets s ON (s.id=b.street_id)';
    }

    if ($self->{SEARCH_FIELDS} =~ /d\./) {
      $EXT_TABLES .= 'LEFT JOIN districts d ON (d.id=s.district_id)';
    }
  }

  if ($self->{SEARCH_FIELDS} =~ /pi\./) {
    $EXT_TABLES .= 'LEFT JOIN users_pi pi ON (b.id=pi.location_id)';
  }

  $self->query("SELECT b.number, $self->{SEARCH_FIELDS} b.id, b.street_id
      FROM builds b
     $EXT_TABLES
     $WHERE
     GROUP BY b.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;", undef, $attr);

  my $list = $self->{list};

  if ($self->{TOTAL} && $self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total FROM builds b
    $EXT_TABLES
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 build_info($attr)

=cut
#**********************************************************
sub build_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM builds WHERE id= ? ;",
    undef,
   {
     INFO => 1,
     Bind => [ $attr->{ID} ]
    });

  return $self;
}

#**********************************************************
=head2 build_change($attr)

=cut
#**********************************************************
sub build_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'builds',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 build_add($attr)

=cut
#**********************************************************
sub build_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ADD_ADDRESS_BUILD}) {
    my $list = $self->build_list({
      STREET_ID => $attr->{STREET_ID},
      NUMBER    => $attr->{ADD_ADDRESS_BUILD},
      COLS_NAME => 1,
      PAGE_ROWS => 1
    });

    if ($self->{TOTAL} > 0) {
      $self->{LOCATION_ID}=$list->[0]->{id};
      return $self;
    }
    else {
      $attr->{NUMBER}=$attr->{ADD_ADDRESS_BUILD};
    }
  }

  $self->query_add('builds', { ADDED => 'NOW()',
                               %$attr
                             });

  if (!$self->{errno}) {
    $self->{LOCATION_ID} = $self->{INSERT_ID};
    $admin->system_action_add("BUILD:$self->{INSERT_ID}:" . ($attr->{NAME} || $attr->{ADD_ADDRESS_BUILD} || '')
      , { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 build_del($id)

=cut
#**********************************************************
sub build_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('builds', {ID => $id });

  $admin->system_action_add("BUILD:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
=head2 location_media_list($attr)

=cut
#**********************************************************
sub location_media_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM location_media WHERE location_id= ? ;",
    undef,
   {
     Bind => [ $attr->{LOCATION_ID} ],
     %$attr
    });

  my $list = $self->{list};

  return $list;
}


#**********************************************************
=head2 location_media_info($attr)

=cut
#**********************************************************
sub location_media_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM location_media WHERE id= ? ;",
    undef,
   {
     INFO => 1,
     Bind => [ $attr->{ID} ]
    });

  return $self;
}

#**********************************************************
=head2 location_media_change($attr)

=cut
#**********************************************************
sub location_media_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'location_media',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 location_media_add($attr)

=cut
#**********************************************************
sub location_media_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('location_media', $attr);

  $admin->system_action_add("MEDIA:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});

  return $self;
}

#**********************************************************
=head2 location_media_del($id)

=cut
#**********************************************************
sub location_media_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('location_media', {ID => $id });

  $admin->system_action_add("MEDIA:$id", { TYPE => 10 }) if (!$self->{errno});

  return $self;
}

1
