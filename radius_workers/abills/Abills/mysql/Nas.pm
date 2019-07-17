package Nas;

=head1 NAME

  NAS Server configuration and managing

=cut

use strict;
use parent 'main';
my $SECRETKEY = '';
my $IPV6=0;
my $admin;

#**********************************************************
# new
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  my $CONF  = shift;
  $admin    = shift;

  $SECRETKEY = (defined($CONF->{secretkey})) ? $CONF->{secretkey} : '';

  if($CONF->{IPV6}) {
    $IPV6=1;
  }

  my $self = {};
  bless($self, $class);

  $self->{db}=$db;
  $self->{conf}=$CONF;
  $self->{admin}=$admin if ($admin);

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';
  delete($self->{COL_NAMES_ARR});

  my $EXT_TABLES = '';
  if ($attr->{SHOW_MAPS_GOOGLE}) {
    $EXT_TABLES = "INNER JOIN builds b ON (b.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
      $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=b.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
  }
  elsif ($attr->{SHOW_MAPS}) {
    $EXT_TABLES = "INNER JOIN builds b ON (b.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
      $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=b.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
  }

  my $WHERE =  $self->search_former($attr, [
      ['NAS_ID',           'INT', 'nas.id',      'nas.id AS nas_id'      ],
      ['NAS_NAME',         'STR', 'nas.name',    'nas.name AS nas_name'  ],
      ['NAS_IDENTIFIER',   'STR', 'nas.nas_identifier',                1 ],
      ['NAS_IP',           'IP',  'nas.ip',      'INET_NTOA(ip) AS ip'   ],
      ['NAS_TYPE',         'STR', 'nas.nas_type',                      1 ],
      ['DISABLE',          'INT', 'nas.disable',                       1 ],
      ['DESCR',            'STR', 'nas.descr',                         1 ],
      ['NAS_GROUP_NAME',   'STR', 'ng.name',  'ng.name AS nas_group_name'],
      ['ALIVE',            'INT', 'nas.alive',                         1 ],
      ['DOMAIN_ID',        'INT', 'nas.domain_id',                     1 ],
      ['MAC',              'INT', 'nas.mac',                           1 ],
      ['GID',              'INT', 'nas.gid',                           1 ],
      ['DISTRICT_ID',      'INT', 'streets.district_id', 'districts.name'],
      ['LOCATION_ID',      'INT', 'nas.location_id',                   1 ],
      ['MNG_HOST_PORT',    'STR', 'nas.mng_host_port', 'nas.mng_host_port as nas_mng_ip_port', ],
      ['MNG_USER',         'STR', 'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
      ['NAS_MNG_PASSWORD', 'STR', '',    "DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password"],
      ['NAS_RAD_PAIRS',    'STR', 'nas.rad_pairs', 'nas.rad_pairs AS nas_rad_pairs' ],
      ['SHOW_MAPS',        '',    'b.map_x, b.map_y, b.map_x2, b.map_y2, b.map_x3, b.map_y3, b.map_x4, b.map_y4' ],
      ['SHOW_MAPS_GOOGLE', 'SHOW_MAPS_GOOGLE', 'b.coordx, b.coordy' ],
      ['NAS_IDS',          'INT', 'nas.id'              ],
    ],
    { WHERE => 1,
    }
  );

  my $ext_fields = '';

  if (! $attr->{SHORT}) {
    $ext_fields = "nas.id AS nas_id,
  nas.name AS nas_name,
  nas.nas_identifier,
  INET_NTOA(nas.ip) AS nas_ip,
  nas.nas_type,
  ng.name as nas_group_name,
  nas.disable as nas_disable,
  nas.descr,
  nas.alive as nas_alive,
  nas.mng_host_port as nas_mng_ip_port,
  nas.mng_user as nas_mng_user,
  DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password,
  nas.rad_pairs as nas_rad_pairs,
  nas.ext_acct,
  nas.auth_type,";
  }

  $self->query2("SELECT $ext_fields
  $self->{SEARCH_FIELDS}
  nas.mac,
  nas.id
  FROM nas
  LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
  $EXT_TABLES
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};
  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT count(*) AS total
    FROM nas
    LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
    $EXT_TABLES
    $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#***************************************************************
=head2 info($attr)

  Arguments:
    NAS_ID
    IP
    CALLED_STATION_ID

  Returns:
    NAS_INFO

=cut
#***************************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{IP}) {
    $WHERE = "ip=INET_ATON('$attr->{IP}')";
    if ($attr->{NAS_IDENTIFIER}) {
      $WHERE .= " AND (nas_identifier='$attr->{NAS_IDENTIFIER}' or nas_identifier='')";
    }
    else {
      $WHERE .= " AND nas_identifier=''";
    }
  }
  elsif ($attr->{CALLED_STATION_ID}) {
    $WHERE = "mac='$attr->{CALLED_STATION_ID}'";
  }
  else {
    $WHERE = "id='$attr->{NAS_ID}'";
  }

  my $fields = '';

  if ( ! $attr->{SHORT}) {
    $fields = " ,name AS nas_name,
    descr AS nas_describe,
    mng_host_port as nas_mng_ip_port,
    mng_user AS nas_mng_user,
    DECODE(mng_password, '$SECRETKEY') AS nas_mng_password,
    gid,
    address_build,
    address_street,
    address_flat,
    zip,
    city,
    country,
    changed,
    location_id";
  }

  $self->query2("SELECT id as nas_id,
    nas_identifier,
    INET_NTOA(ip) AS nas_ip,
    nas_type,
    auth_type AS nas_auth_type,
    alive AS nas_alive,
    disable AS nas_disable,
    ext_acct AS nas_ext_acct,
    rad_pairs AS nas_rad_pairs,
    mac,
    domain_id
    $fields
 FROM nas
 WHERE $WHERE
 ORDER BY nas_identifier DESC;",
 undef,
 { INFO => 1 }
  );

  if (! $self->{errno} && $self->{LOCATION_ID}) {
    $self->query2("SELECT d.id AS district_id, d.city,
      d.name AS address_district,
      s.name AS address_street,
      b.number AS address_build
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id='$self->{LOCATION_ID}'",
     undef,
     { INFO => 1 }
    );

    if ($self->{errno} && $self->{errno} == 2) {
    	delete $self->{errno};
    }
  }

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS_DISABLE} = (defined($attr->{NAS_DISABLE})) ? 1 : 0;

  my %FIELDS = (
    NAS_ID           => 'id',
    NAS_NAME         => 'name',
    NAS_IDENTIFIER   => 'nas_identifier',
    NAS_DESCRIBE     => 'descr',
    IP               => 'ip',
    NAS_TYPE         => 'nas_type',
    NAS_AUTH_TYPE    => 'auth_type',
    NAS_MNG_IP_PORT  => 'mng_host_port',
    NAS_MNG_USER     => 'mng_user',
    NAS_MNG_PASSWORD => 'mng_password',
    NAS_RAD_PAIRS    => 'rad_pairs',
    NAS_ALIVE        => 'alive',
    NAS_DISABLE      => 'disable',
    NAS_EXT_ACCT     => 'ext_acct',
    ADDRESS_BUILD    => 'address_build',
    ADDRESS_STREET   => 'address_street',
    ADDRESS_FLAT     => 'address_flat',
    ZIP              => 'zip',
    CITY             => 'city',
    COUNTRY          => 'country',
    DOMAIN_ID        => 'domain_id',
    GID              => 'gid',
    MAC              => 'mac',
    CHANGED          => 'changed',
    LOCATION_ID      => 'location_id'
  );

  $attr->{CHANGED} = 1;
  $admin->{MODULE} = '';

  if(! $attr->{NAS_MNG_PASSWORD}) {
    delete $attr->{NAS_MNG_PASSWORD};
  }

  $self->changes2(
    {
      CHANGE_PARAM    => 'NAS_ID',
      TABLE           => 'nas',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->info({ NAS_ID => $self->{NAS_ID} }),
      DATA            => $attr,
      EXT_CHANGE_INFO => "NAS_ID:$self->{NAS_ID}"
    }
  );

  $self->info({ NAS_ID => $self->{NAS_ID} });
  return $self;
}

#**********************************************************
=head2 add($attr) - Add nas server

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  if($admin && $admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  $self->query_add('nas', {
    %$attr,
    NAME           => $attr->{NAS_NAME},
    DESCR          => $attr->{NAS_DESCRIBE},
    AUTH_TYPE      => $attr->{NAS_AUTH_TYPE},
    MNG_HOST_PORT  => $attr->{NAS_MNG_IP_PORT},
    MNG_USER       => $attr->{NAS_MNG_USER},
    MNG_PASSWORD   => ($attr->{NAS_MNG_PASSWORD}) ? "ENCODE('$attr->{NAS_MNG_PASSWORD}', '$SECRETKEY')" : undef,
    RAD_PAIRS      => $attr->{NAS_RAD_PAIRS} || '',
    ALIVE          => $attr->{NAS_ALIVE} || 0,
    DISABLE        => $attr->{NAS_DISABLE},
    EXT_ACCT       => $attr->{NAS_EXT_ACCT},
   });

  $admin->system_action_add("NAS_ID:$self->{INSERT_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 del($id) ADel nas server

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('nas', undef,  { id => $id });
  $self->query_del('nas_ippools', undef, { nas_id => $id });

  $admin->system_action_add("NAS_ID:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 nas_ip_pools_list($attr)

=cut
#**********************************************************
sub nas_ip_pools_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ('np.pool_id=pool.id');

  my $WHERE_NAS =  $self->search_former($attr, [
      ['NAS_ID',          'INT', 'np.nas_id'      ],
      ['STATIC',          'INT', 'pool.static'    ],
    ],
    {
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT if (np.nas_id IS NULL, 0, np.nas_id) AS active_nas_id,
    n.name AS nas_name,
    pool.name AS pool_name,
    pool.ip,
    pool.ip + pool.counts AS last_ip_num,
    pool.counts AS ip_count,
    pool.counts - (SELECT count(*) FROM dv_main dv WHERE dv.ip > pool.ip AND dv.ip <= pool.ip + pool.counts ) AS ip_free,
    pool.priority,
    pool.speed,
    INET_NTOA(pool.ip) as first_ip,
    INET_NTOA(pool.ip + pool.counts) AS last_ip,
    pool.id,
    np.nas_id,
    pool.static
    FROM ippools pool
    LEFT JOIN nas_ippools np ON ($WHERE_NAS)
    LEFT JOIN nas n ON (n.id=np.nas_id)
      GROUP BY pool.id
      ORDER BY $SORT $DESC",
   undef,
   $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 nas_ip_pools_set($attr) NAS IP Pools

=cut
#**********************************************************
sub nas_ip_pools_set {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('nas_ippools', undef,  { nas_id => $self->{NAS_ID} });

  my @MULTI_QUERY = ();

  foreach my $id ( split(/, /, $attr->{ids}) ) {
    push @MULTI_QUERY, [ $id,
                         $attr->{NAS_ID}
                        ];
  }

  $self->query2("INSERT INTO nas_ippools (pool_id, nas_id) VALUES (?, ?);",
      undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  $admin->system_action_add("NAS_ID:$self->{NAS_ID} POOLS:" . (join(',', split(/, /, $attr->{ids}))), { TYPE => 2 });
  return $self->{list};
}

#**********************************************************
=head2 ip_pools_info($id)

=cut
#**********************************************************
sub ip_pools_info {
  my $self = shift;
  my ($id) = @_;

  my $fields_v6 = ($IPV6) ? ", INET6_NTOA(ipv6_prefix) AS ipv6_prefix" : '';

  $self->query2("SELECT *,
      INET_NTOA(ip) AS ip
      $fields_v6
   FROM ippools  WHERE id= ? ;",
   undef,
   { INFO => 1,
     Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 ip_pools_change($attr) - NAS IP Pools change

=cut
#**********************************************************
sub ip_pools_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATIC} = ($attr->{STATIC}) ? $attr->{STATIC} : 0;
  $attr->{GUEST} = ($attr->{GUEST}) ? $attr->{GUEST} : 0;

  $self->changes2(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'ippools',
      DATA            => $attr,
      EXT_CHANGE_INFO => "POOL:$attr->{ID}"
    }
  );

  return $self;
}

#**********************************************************
=head2 ip_pools_list($attr)

=cut
#**********************************************************
sub ip_pools_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if (defined($attr->{STATIC})) {
    push @WHERE_RULES, "pool.static='$attr->{STATIC}'";

    my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
    $self->query2("SELECT '', pool.name,
   pool.ip, pool.ip + pool.counts AS last_ip_num, pool.counts, pool.priority,
    INET_NTOA(pool.ip) AS first_ip, INET_NTOA(pool.ip + pool.counts) AS last_ip,
    pool.id, pool.nas
    FROM ippools pool
    WHERE $WHERE  ORDER BY $SORT $DESC",
    undef,
    $attr
    );
    return $self->{list};
  }

  if (defined($self->{NAS_ID})) {
    push @WHERE_RULES, "pool.nas='$self->{NAS_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "and " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT nas.name, pool.name,
   pool.ip, pool.ip + pool.counts AS last_ip_num, pool.counts, pool.priority,
    INET_NTOA(pool.ip) AS first_ip, INET_NTOA(pool.ip + pool.counts) AS last_ip,
    pool.id, pool.nas
    FROM ippools pool, nas
    WHERE pool.nas=nas.id
    $WHERE  ORDER BY $SORT $DESC",
   undef,
   $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 ip_pools_add($attr)

=cut
#**********************************************************
sub ip_pools_add {
  my $self   = shift;
  my ($attr) = @_;

  $attr->{IPV6_PREFIX}  = undef if (! $IPV6);

  $self->query_add('ippools', { %$attr,
  	                            NAS      => undef,
 	                           });

  $admin->system_action_add("NAS_ID:$attr->{NAS_ID} POOLS:" . (join(',', split(/, /, $attr->{ids}))), { TYPE => 1 });
  return 0;
}

#**********************************************************
=head2 ip_pools_del()

=cut
#**********************************************************
sub ip_pools_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('ippools', { ID => $id });

  $admin->system_action_add("POOL:$id", { TYPE => 10 });
  return 0;
}

#**********************************************************
# Statistic
# stats($self)
#**********************************************************
sub stats {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "WHERE date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m')";
  my $SORT  = ($attr->{SORT} == 1) ? "1,2"         : $attr->{SORT};
  my $DESC  = ($attr->{DESC})      ? $attr->{DESC} : '';

  if (defined($attr->{NAS_ID})) {
    $WHERE .= "and id='$attr->{NAS_ID}'";
  }

  $self->query2("SELECT n.name, l.port_id, count(*),
   if(date_format(max(l.start), '%Y-%m-%d')=curdate(), date_format(max(l.start), '%H-%i-%s'), max(l.start)),
   SEC_TO_TIME(avg(l.duration)), SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)),
   l.nas_id
   FROM dv_log l
   LEFT JOIN nas n ON (n.id=l.nas_id)
   $WHERE
   GROUP BY l.nas_id, l.port_id
   ORDER BY $SORT $DESC;"
  );

  return $self->{list};
}

#**********************************************************
=head2 nas_group_list($attr)

=cut
#**********************************************************
sub nas_group_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
      ['DOMAIN_ID',      'INT', 'g.domain_id'             ],
      ['COUNTS',         'INT', '', 'COUNT(*) AS counts'  ],
    ],
    {
    	WHERE => 1
    }
  );

  my $EXT_TABLES = '';
  if ($attr->{COUNTS}) {
    $EXT_TABLES =  'LEFT JOIN nas n ON (n.gid=g.id)';
  }

  $self->query2("SELECT g.id, g.name, g.comments, g.disable, $self->{SEARCH_FIELDS} g.id AS gid
  FROM nas_groups g
  $EXT_TABLES
  $WHERE
  GROUP BY g.id
  ORDER BY $SORT $DESC;",
  undef,
  $attr
  );

  return $self->{list};
}

#***************************************************************
=head2 nas_group_info($attr);

=cut
#***************************************************************
sub nas_group_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT * FROM nas_groups WHERE id = ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 nas_group_change($attr)

=cut
#**********************************************************
sub nas_group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DISABLE} = (defined($attr->{DISABLE})) ? 1 : 0;

  $self->changes2(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'nas_groups',
      DATA            => $attr,
      EXT_CHANGE_INFO => "NAS_GROUP_ID:$self->{ID}"
    }
  );

  $self->nas_group_info({ ID => $attr->{ID} });

  return $self;
}

#**********************************************************
=head2 nas_group_add($attr)

=cut
#**********************************************************
sub nas_group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('nas_groups', $attr);

  $admin->system_action_add("NAS_GROUP_ID:$self->{INSERT_ID}", { TYPE => 1 });
  return 0;
}

#**********************************************************
=head2 nas_group_del()

=cut
#**********************************************************
sub nas_group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('nas_groups', { ID => $id });

  $admin->system_action_add("NAS_GROUP_ID:$id", { TYPE => 10 });
  return 0;
}

#**********************************************************
=head2 function add_radtest_query() - add query to datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->add_radtest_query({
      COMMENTS   => 'test',
      RAD_QUERY  => 'User-Name=test',
      DATETIME   => 'NOW()'
    });

    $nas->add_radtest_query({
      %FORM
    });

=cut
#**********************************************************
sub add_radtest_query {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('radtest_history', { %$attr });

  return 0;
}

#**********************************************************
=head2 function query_list() - queries list

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $query_list = $nas->query_list({COLS_NAME => 1});

=cut
#**********************************************************
sub query_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT * FROM radtest_history
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM radtest_history",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 function del_query() - del query from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->del_query({ID => $FORM{query_del}});

=cut
#**********************************************************
sub del_query {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('radtest_history', $attr);

  return $self;
}

#***************************************************************
=head2 function query_info() - query info from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->query_info({ID => $FORM{query_info}});

=cut
#***************************************************************
sub query_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT * FROM radtest_history WHERE id = ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] }
  );

  return $self;
}


#**********************************************************
=head2 function add_radtest_query() - add query to datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_add({
      COMMENTS   => 'test',
      RAD_QUERY  => 'User-Name=test',
      DATETIME   => 'NOW()'
    });

    $nas->nas_cmd_add({
      %FORM
    });

=cut
#**********************************************************
sub nas_cmd_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('nas_cmd', { %$attr });

  return 0;
}

#**********************************************************
=head2 function nas_cmd_del() - del query from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_del({ID => $FORM{del}});

=cut
#**********************************************************
sub nas_cmd_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('nas_cmd', $attr);

  return $self;
}

#***************************************************************
=head2 function nas_cmd_info() - query info from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_info({ID => $FORM{ID}});

=cut
#***************************************************************
sub nas_cmd_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT * FROM nas_cmd WHERE id = ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 function nas_cmd_list() - queries list

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $cmd_list = $Nas->nas_cmd_list({COLS_NAME => 1});

=cut
#**********************************************************
sub nas_cmd_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  # if ($attr->{NAS_ID}) {
  #   push @WHERE_RULES, "nas_id = $attr->{NAS_ID}";
  # }

  my $WHERE = $self->search_former($attr, [
     ['ID',             'INT',  'id',         1 ],
     ['NAS_ID',         'INT',  'nas_id',     1 ],
     ['CMD',            'STR',  'cmd',        1 ],
     ['TYPE',           'STR',  'type',       1 ],
     ['COMMENTS',       'STR',  'comments',   1 ],
    ],
    {   WHERE            => 1,
        #USE_USER_PI      => 1,
        #USERS_FIELDS_PRE => 1,
        WHERE_RULES      => \@WHERE_RULES,
    }
  );

  $self->query2(
    "SELECT 
    id,
    nas_id,
    cmd,
    type,
    comments FROM nas_cmd
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM nas_cmd",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 nas_cmd_change($attr)

=cut
#**********************************************************
sub nas_cmd_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'nas_cmd',
      DATA            => $attr,
    }
  );

  return $self;
}

1

