package Equipment;

=head1 NAME

  Equipment managment system

=cut

use strict;
use parent 'dbcore';
use warnings FATAL => 'all';
use Socket;

my $admin;
my $CONF;
my $SORT = 1;
my $DESC = '';
my $PG = 0;
my $PAGE_ROWS = 25;

#**********************************************************
# New
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 vendor_list($attr)

=cut
#**********************************************************
sub vendor_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query("SELECT name, site, support, id
    FROM equipment_vendors
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );
  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
  FROM equipment_vendors;", undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 vendor_add($attr)

=cut
#**********************************************************
sub vendor_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_vendors', $attr);

  return $self;
}

#**********************************************************
=head2 vendor_info($id, $attr) - Vendor info

=cut
#**********************************************************
sub vendor_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM equipment_vendors
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 vendor_change($attr)

=cut
#**********************************************************
sub vendor_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_vendors',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 vendor_del($id)

=cut
#**********************************************************
sub vendor_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_vendors', { ID => $id });

  return $self;
}


#**********************************************************
=head2 type_list($attr)

=cut
#**********************************************************
sub type_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query("SELECT name, id
    FROM equipment_types
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 type_add($attr)

=cut
#**********************************************************
sub type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_types', $attr);

  return $self;
}

#**********************************************************
=head2 type_change($attr)

=cut
#**********************************************************
sub type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_types',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 type_del($id)

=cut
#**********************************************************
sub type_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_types', { ID => $id });

  return $self;
}


#**********************************************************
=head2 type_info($id, $attr)

=cut
#**********************************************************
sub type_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM equipment_types
    WHERE id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 model_list($attr)

=cut
#**********************************************************
sub model_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  delete $self->{COL_NAMES_ARR};

  my $WHERE = $self->search_former($attr, [
    [ 'MODEL_NAME', 'STR', 'm.model_name', 1 ],
    [ 'TYPE_ID', 'INT', 'm.type_id', 1 ],
    [ 'TYPE_NAME', 'STR', 't.name AS type_name', 1 ],
    [ 'VENDOR_ID', 'INT', 'm.vendor_id', 'v.name AS vendor_name' ],
    [ 'PORTS', 'INT', 'm.ports', 1 ],
    [ 'SNMP_TPL', 'STR', 'm.snmp_tpl', 1 ],
    [ 'SYS_OID', 'STR', 'm.sys_oid', 1 ],
    [ 'SITE', 'INT', 'm.site', 1 ],
    [ 'MANAGE_WEB', 'STR', 'm.manage_web', 1 ],
    [ 'MANAGE_SSH', 'STR', 'm.manage_ssh', 1 ],
    [ 'COMMENTS', 'STR', 'm.comments', 1 ],
    [ 'MODEL_ID', 'INT', 'm.id', 1 ],
  ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT
        m.model_name,
        v.name AS vendor_name,
        $self->{SEARCH_FIELDS}
        m.id
    FROM equipment_models m
    LEFT JOIN equipment_types t ON (t.id=m.type_id)
    LEFT JOIN equipment_vendors v ON (v.id=m.vendor_id)
    $WHERE
    GROUP BY m.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total
    FROM equipment_models m
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
=head2 model_add($attr)

=cut
#**********************************************************
sub model_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_models', $attr);

  if (!$self->{errno} && $attr->{EXTRA_PORTS}) {
    $self->extra_port_update(
      {
        MODEL_ID        => $self->{INSERT_ID},
        EXTRA_PORTS     => $attr->{EXTRA_PORTS},
        EXTRA_PORT_ROWS => $attr->{EXTRA_PORT_ROWS}
      }
    );
  }

  return $self;
}

#**********************************************************
=head2 model_change($attr)

=cut
#**********************************************************
sub model_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_models',
      DATA         => $attr
    }
  );

  if (!$self->{errno} && $attr->{EXTRA_PORTS}) {
    $self->extra_port_update(
      {
        MODEL_ID        => $attr->{ID},
        EXTRA_PORTS     => $attr->{EXTRA_PORTS},
        EXTRA_PORT_ROWS => $attr->{EXTRA_PORT_ROWS}
      }
    );
  }

  return $self;
}

#**********************************************************
=head2 model_del($id)

=cut
#**********************************************************
sub model_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_models', { ID => $id });

  return $self;
}

#**********************************************************
=head2 model_info($id, $attr) - Get model information

  Arguments:
    $id
    $attr

  Returns:
    Object
=cut
#**********************************************************
sub model_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM equipment_models
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 _list($attr) - Equipment list

=cut
#**********************************************************
sub _list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $SECRETKEY = $CONF->{secretkey} || '';

  if ($admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  my $WHERE = $self->search_former($attr, [
    [ 'TYPE', 'STR', 't.id', 1 ],
    [ 'NAS_NAME', 'STR', 'nas.name', 'nas.name AS nas_name' ],
    [ 'SYSTEM_ID', 'STR', 'i.system_id', 1 ],
    #TYPE_NAME,PORTS
    [ 'TYPE_ID', 'INT', 'm.type_id', 1 ],
    [ 'VENDOR_ID', 'INT', 'm.vendor_id', 1 ],
    [ 'NAS_TYPE', 'STR', 'nas.nas_type', 1 ],
    [ 'MODEL_NAME', 'STR', 'm.model_name', 1 ],
    [ 'SNMP_TPL', 'STR', 'm.snmp_tpl', 1 ],
    [ 'MODEL_ID', 'INT', 'i.model_id', 1 ],
    [ 'VENDOR_NAME', 'STR', 'v.name', 'v.name AS vendor_name' ],
    [ 'DOMAIN_ID', 'INT', 'nas.domain_id' ],
    [ 'STATUS', 'INT', 'i.status', 1 ],
    [ 'DISABLE', 'INT', 'nas.disable', 1 ],
    [ 'TYPE_NAME', 'INT', 'm.type_id', 't.name AS type_name', ],
    [ 'PORTS', 'INT', 'm.ports', 1 ],
    [ 'MAC', 'INT', 'nas.mac', 1 ],
    [ 'PORT_SHIFT', 'INT', 'm.port_shift', 1 ],
    [ 'NAS_IP', 'IP', 'nas.ip', 'INET_NTOA(nas.ip) AS nas_ip' ],
    [ 'MNG_HOST_PORT', 'STR', 'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_ip_port', ],
    #['MNG_USER',         'STR', 'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_USER', 'STR', 'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_PASSWORD', 'STR', '', "DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password" ],
    [ 'NAS_ID', 'INT', 'i.nas_id', 1 ],
    [ 'NAS_GID', 'INT', 'nas.gid', 1 ],
    [ 'NAS_GROUP_NAME', 'STR', 'ng.name', 'ng.name AS nas_group_name' ],
    [ 'DISTRICT_ID', 'INT', 'streets.district_id', 'districts.name' ],
    [ 'LOCATION_ID', 'INT', 'nas.location_id', 1 ],
    [ 'DOMAIN_ID', 'INT', 'nas.domain_id', 1 ],
    [ 'COORDX', 'INT', 'builds.coordx', 1 ],
    [ 'COORDY', 'INT', 'builds.coordy', 1 ],
    [ 'REVISION', 'STR', 'i.revision', 1 ],
    [ 'SNMP_VERSION', 'STR', 'i.snmp_version', 1 ],
    [ 'SERVER_VLAN', 'STR', 'i.server_vlan', 1 ],
    [ 'LAST_ACTIVITY', 'DATE', 'i.last_activity', 1 ],
    [ 'INTERNET_VLAN', 'STR', 'i.internet_vlan', 1 ],
    [ 'TR_069_VLAN', 'STR', 'i.tr_069_vlan', 1 ],
    [ 'IPTV_VLAN', 'STR', 'i.iptv_vlan', 1 ],
  ],
    { WHERE => 1,
    }
  );

  my %EXT_TABLE_JOINS_HASH = ();

  if ($WHERE . $self->{SEARCH_FIELDS} =~ /nas\./) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
  }

  if ($attr->{COORDX} || $attr->{COORDY}) {
    $EXT_TABLE_JOINS_HASH{builds} = 1;
  }

  if ($attr->{ADDRESS_FULL}) {
    $attr->{BUILD_DELIMITER} = ',' if (!$attr->{BUILD_DELIMITER});
    my @fields = @{$self->search_expr($attr->{ADDRESS_FULL}, "STR", "CONCAT(streets.name, ' ', builds.number) AS address_full", { EXT_FIELD => 1 })};

    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{builds} = 1;
    $EXT_TABLE_JOINS_HASH{streets} = 1;
    $EXT_TABLE_JOINS_HASH{disctrict} = 1;
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }

  if ($attr->{NAS_GROUP_NAME}) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{nas_gid} = 1;
  }

  my $EXT_TABLES = $self->mk_ext_tables({ JOIN_TABLES => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN                                    => [ 'nas:LEFT JOIN nas ON (nas.id=i.nas_id)',
      'nas_gid:LEFT JOIN nas_groups ng ON (ng.id=nas.gid)',
      'builds:LEFT JOIN builds ON (builds.id=nas.location_id)',
      'streets:LEFT JOIN streets ON (streets.id=builds.street_id)',
      'disctrict:LEFT JOIN districts ON (districts.id=streets.district_id)',
    ],
    EXTRA_PRE_ONLY                                    => 1,
  });

  $self->query("SELECT
        $self->{SEARCH_FIELDS}
        m.id,
        i.nas_id
    FROM equipment_infos i
      INNER JOIN equipment_models m ON (m.id=i.model_id)
      INNER JOIN equipment_types t ON (t.id=m.type_id)
      INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
      $EXT_TABLES
    $WHERE
    GROUP BY i.nas_id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total
    FROM equipment_infos i
      INNER JOIN equipment_models m ON (m.id=i.model_id)
      INNER JOIN equipment_types t ON (t.id=m.type_id)
      INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
    $EXT_TABLES
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
=head2 _add($attr)

=cut
#**********************************************************
sub _add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_infos', $attr);

  return $self;
}

#**********************************************************
=head2  _change($attr)

=cut
#**********************************************************
sub _change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'NAS_ID',
      TABLE        => 'equipment_infos',
      DATA         => $attr
    }
  );
  return $self;
}

#**********************************************************
=head2 _del($id)

=cut
#**********************************************************
sub _del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_infos', undef, { nas_id => $id });

  return $self;
}

#**********************************************************
=head2 _info($id, $attr) - Equipment unit information

  Arguments:
    $id
    $attr

  Returns:
    Object

=cut
#**********************************************************
sub _info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM equipment_infos
    WHERE nas_id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 port_list($attr)

=cut
#**********************************************************
sub port_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS} = '';
  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, [
    [ 'ADMIN_PORT_STATUS', 'INT', 'p.status', 'p.status AS admin_port_status' ],
    [ 'UPLINK', 'INT', 'p.uplink', 1 ],
    [ 'STATUS', 'INT', 'p.status', 1 ],
    [ 'PORT_COMMENTS', 'INT', 'p.comments', 'p.comments AS port_comments' ],
    #  ['LOGIN',          'STR', 'u.id',               'u.id AS login' ],
    #  ['FIO',            'STR', 'pi.fio',                           1 ],
    #  ['MAC',            'STR', 'dhcp.mac',                         1 ],
    #  ['IP',             'IP',  'dhcp.ip',    'INET_NTOA(dhcp.ip) AS ip' ],
    #  ['NETMASK',        'IP',  'dhcp.netmask', 'INET_NTOA(dhcp.netmask) AS netmask' ],
    #  ['TP_ID',          'INT', 'dv.tp_id',                         1 ],
    #  ['TP_NAME',        'STR', 'tp.name',       'tp.name AS tp_name' ],
    #  ['UID',            'INT', 'u.uid',                            1 ],
    #  ['GID',            'INT', 'u.gid',                            1 ],
    [ 'PORT', 'INT', 'p.port', 1 ],
    [ 'VLAN', 'INT', 'p.vlan', 1 ],
    [ 'NAS_ID', 'INT', 'p.nas_id', ],
  ],
    { WHERE => 1,
      #    USERS_FIELDS=> 1,
      #    USE_USER_PI => 1,
    });

  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /pi\.|u\.|dv\.|tp\.|internet\./ || $WHERE =~ /pi\.|u\.|dv\.|tp\.|internet\./) {
    $EXT_TABLE = "LEFT JOIN users u ON (u.uid=dhcp.uid)" . $EXT_TABLE;
    #LEFT JOIN users_pi pi ON (pi.uid=u.uid)". $EXT_TABLE;
  }

  if ($self->{SEARCH_FIELDS} =~ /internet\./ || $WHERE =~ /internet\./) {
    $EXT_TABLE .= "LEFT JOIN internet_main dv ON (internet.uid=u.uid)
      LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id) ";
  }
  #  else {
  #    if ($self->{SEARCH_FIELDS} =~ /dhcp|dv\.|tp\.|\.u/ || $WHERE =~ /pi\.|u\.|dv\.|tp\./) {
  #      $EXT_TABLE = "LEFT JOIN dhcphosts_hosts dhcp ON (dhcp.nas=p.nas_id AND dhcp.ports=p.port)" . $EXT_TABLE;
  #    }

  #    if ($self->{SEARCH_FIELDS} =~ /dv\.|tp\./) {
  #      $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.uid=u.uid)
  #    LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id AND tp.module='Dv') ";
  #    }
  #  }
  $self->query("SELECT p.port,
   $self->{SEARCH_FIELDS}
   p.nas_id,
   p.id
    FROM equipment_ports p
    $EXT_TABLE
    $WHERE
    GROUP BY p.port
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0 && !$attr->{_SKIP_TOTAL}) {
    $self->query("SELECT COUNT(*) AS total
    FROM equipment_ports p
	$EXT_TABLE
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 port_list_without_group_by($attr)

=cut
#**********************************************************
sub port_list_without_group_by {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS} = '';
  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, [
    [ 'ADMIN_PORT_STATUS', 'INT', 'p.status', 'p.status AS admin_port_status' ],
    [ 'UPLINK', 'INT', 'p.uplink', 1 ],
    [ 'STATUS', 'INT', 'p.status', 1 ],
    [ 'PORT_COMMENTS', 'INT', 'p.comments', 'p.comments AS port_comments' ],
    [ 'PORT', 'INT', 'p.port', 1 ],
    [ 'VLAN', 'INT', 'p.vlan', 1 ],
    [ 'NAS_ID', 'INT', 'p.nas_id', ],
  ],
    { WHERE => 1,
    });

  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /pi\.|u\.|dv\.|tp\.|internet\./ || $WHERE =~ /pi\.|u\.|dv\.|tp\.|internet\./) {
    $EXT_TABLE = "LEFT JOIN users u ON (u.uid=dhcp.uid)" . $EXT_TABLE;
  }

  if ($self->{SEARCH_FIELDS} =~ /internet\./ || $WHERE =~ /internet\./) {
    $EXT_TABLE .= "LEFT JOIN internet_main dv ON (internet.uid=u.uid)
      LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id) ";
  }

  $self->query("SELECT p.port,
   $self->{SEARCH_FIELDS}
   p.nas_id,
   p.id
    FROM equipment_ports p
    $EXT_TABLE
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0 && !$attr->{_SKIP_TOTAL}) {
    $self->query("SELECT COUNT(*) AS total
    FROM equipment_ports p
	$EXT_TABLE
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
=head2  port_add($attr)

=cut
#**********************************************************
sub port_add {
  my $self = shift;
  my ($attr) = @_;

  delete $attr->{ID};
  $self->query_add('equipment_ports', $attr);

  return $self;
}

#**********************************************************
=head2 port_change($attr)

=cut
#**********************************************************
sub port_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_ports',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 port_del($id)

=cut
#**********************************************************
sub port_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_ports', { ID => $id });

  return $self;
}

#**********************************************************
=head2 port_del_nas($id)

=cut
#**********************************************************
sub port_del_nas {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('equipment_ports', {}, { NAS_ID => $attr->{NAS_ID} });

  return $self;
}


#**********************************************************
=head2 port_info($attr)

  Argumnets:
    $attr
      NAS_ID
      PORT

=cut
#**********************************************************
sub port_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
    FROM equipment_ports
    WHERE nas_id = ? AND port = ? ;",
    undef,
    { INFO => 1,
      Bind => [
        $attr->{NAS_ID},
        $attr->{PORT}
      ]
    }
  );

  return $self;
}

#**********************************************************
=head2 equipment_box_type_add($attr)

=cut
#**********************************************************
sub equipment_box_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_box_types', $attr);
  return [] if ($self->{errno});

  $admin->system_action_add("BOX TYPES: $self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 equipment_box_type_info()

=cut
#**********************************************************
sub equipment_box_type_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM equipment_box_types WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# equipment_box_type_del
#**********************************************************
sub equipment_box_type_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_box_types', { ID => $id });

  return [] if ($self->{errno});

  $admin->system_action_add("BOX TYPES: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
# equipment_box_type_change()
#**********************************************************
sub equipment_box_type_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DISABLE} = (!defined($attr->{DISABLE})) ? 0 : 1;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_box_types',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# equipment_box_type_list()
#**********************************************************
sub equipment_box_type_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'MARKING', 'STR', 'marking', ],
    [ 'VENDOR', 'STR', 'vendor', ],
  ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT marking, vendor, units, width, hieght, length, diameter, id
     FROM equipment_box_types
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(id) AS total FROM equipment_box_types $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}


#**********************************************************
# equipment_box_add
#**********************************************************
sub equipment_box_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_boxes', $attr);
  return [] if ($self->{errno});

  $admin->system_action_add("BOX TYPES: $self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
# equipment_box_info()
#**********************************************************
sub equipment_box_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM equipment_boxes WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# equipment_box_del
#**********************************************************
sub equipment_box_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_boxes', { ID => $id });

  return [] if ($self->{errno});

  $admin->system_action_add("BOX: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
# equipment_box_change()
#**********************************************************
sub equipment_box_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DISABLE} = (!defined($attr->{DISABLE})) ? 0 : 1;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_boxes',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# equipment_box_list()
#**********************************************************
sub equipment_box_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'SERIAL', 'STR', 'serial', ],
    [ 'VENDOR', 'STR', 'vendor', ],
  ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT b.serial, bt.marking, b.datetime, b.id
     FROM equipment_boxes b
     LEFT JOIN equipment_box_types bt ON (b.type_id=bt.id)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(id) AS total FROM equipment_box_types $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 extra_port_update($attr)

  Arguments:
    $attr
      MODEL_ID          - Model ID to change ports
      EXTRA_PORTS       - hash_ref  port numbers => type
      EXTRA_PORT_ROWS  - hash_ref  port_number => row

  Returns:


=cut
#**********************************************************
sub extra_port_update {
  my $self = shift;
  my ($attr) = @_;

  #clear and update
  $self->{db}{AutoCommit} = 0;
  $self->query_del('equipment_extra_ports', undef,
    {
      MODEL_ID => $attr->{MODEL_ID}
    }
  );

  while (my ($port_number, $port_type) = each %{$attr->{EXTRA_PORTS}}) {

    $self->query_add('equipment_extra_ports',
      {
        MODEL_ID    => $attr->{MODEL_ID},
        PORT_NUMBER => $port_number,
        PORT_TYPE   => $port_type,
        ROW         => $attr->{EXTRA_PORT_ROWS}->{$port_number}
      }
    );
  }

  $self->{db}{AutoCommit} = 1;

  return $self;
}

#**********************************************************
=head2 extra_ports_list($id)

  Arguments:
    $id - Id of model

  Returns:
    DB_LIST

=cut
#**********************************************************
sub extra_ports_list {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM equipment_extra_ports WHERE model_id= ?", undef, { COLS_NAME => 1, Bind => [ $id ] });

  return $self->{list} || [];
}

#**********************************************************
=head2 vlan_add($attr) - add vlan to db

  Arguments:
    
  Returns:

  Example:
    $Equipment->vlan_add({%FORM});
  
=cut
#**********************************************************
sub vlan_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_vlans', $attr);

  return $self;

}

#**********************************************************
=head2 vlan_change($attr) - change info about vlan

  Arguments:
    
  Returns:

  Example:
    $Equipment->vlan_change({ID => $FORM{id}, %FORM});
  
=cut
#**********************************************************
sub vlan_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_vlans',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 vlan_del($attr) - delete vlan from db

  Arguments:
    
  Returns:

  Example:
    $Equipment->vlan_del({ID => $FORM{del}});
  
=cut
#**********************************************************
sub vlan_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('equipment_vlans', $attr);

  return $self;
}

#**********************************************************
=head2 vlan_info($attr) - get vlan info

  Arguments:
    
  Returns:

  Example:
    $vlan_info = $Equipment->vlan_info({ID => $FORM{chg}});

=cut
#**********************************************************
sub vlan_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query("SELECT *
    FROM equipment_vlans
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 vlan_list($attr) - get vlans list

  Arguments:
    
    
  Returns:

  Example:
    $Equipment->vlan_list({COLS_NAME => 1});
  
=cut
#**********************************************************
sub vlan_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  $self->query("SELECT *
    FROM equipment_vlans
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if($self->{TOTAL} && $self->{TOTAL} > 0) {
    $self->query(
      "SELECT COUNT(*) AS total
     FROM equipment_vlans",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 trap_add

=cut
#**********************************************************
sub trap_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_traps', {
    %$attr,
    TRAPTIME => 'NOW()',
  });

  return $self;
}

#**********************************************************
=head2 traps_del($attr)

=cut
#**********************************************************
sub traps_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM equipment_traps WHERE traptime < CURDATE() - INTERVAL $attr->{PERIOD} day;", 'do');

  return $self;
}

#**********************************************************
=head2 trap_list($attr)

=cut
#**********************************************************
sub trap_list {
  my $self = shift;
  my ($attr) = @_;
  my $GROUP;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? !$attr->{DESC} : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $GROUP = ($attr->{GROUP}) ? "GROUP BY $attr->{GROUP}" : '';

  my $WHERE = $self->search_former($attr, [
    [ 'TRAP_ID', 'STR', 'e.id', ],
    [ 'TRAPTIME', 'STR', 'traptime', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'NAS_IP', 'STR', 'nas_ip', 'INET_NTOA(e.ip) AS nas_ip', ],
    [ 'EVENTNAME', 'STR', 'eventname', 1 ],
    [ 'VARBINDS', 'STR', 'varbinds', 1 ],
    [ 'TRAPOID', 'STR', 'trapoid', 1 ],
    [ 'NAS_ID', 'STR', 'nas.id', 'nas.id AS nas_id', ],
    [ 'DOMAIN_ID', 'STR', 'nas.domain_id', ],
  ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} e.id AS trap_id
     FROM equipment_traps e
     INNER JOIN nas ON (nas.ip=e.ip)
     $WHERE
     $GROUP 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{MONIT}) {
    $self->query("SELECT COUNT(e.id) AS total
      FROM equipment_traps e
      INNER JOIN nas ON (nas.ip=e.ip)
    $WHERE",
      undef, { INFO => 1 });
  }
  return $self->{list_hash} if ($attr->{LIST2HASH});

  return $list;
}

#**********************************************************
=head2 cvlan_list($attr)

=cut
#**********************************************************
sub cvlan_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $SECRETKEY = $CONF->{secretkey} || '';

  if ($admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  my $WHERE = $self->search_former($attr, [
    [ 'TYPE', 'STR', 't.id', 1 ],
    [ 'NAS_NAME', 'STR', 'nas.name', 'nas.name AS nas_name' ],
    [ 'SYSTEM_ID', 'STR', 'i.system_id', 1 ],
    [ 'TYPE_ID', 'INT', 'm.type_id', 1 ],
    [ 'VENDOR_ID', 'INT', 'm.vendor_id', 1 ],
    [ 'NAS_TYPE', 'STR', 'nas.nas_type', 1 ],
    [ 'MODEL_NAME', 'STR', 'm.model_name', 1 ],
    [ 'SNMP_TPL', 'STR', 'm.snmp_tpl', 1 ],
    [ 'MODEL_ID', 'INT', 'i.model_id', 1 ],
    [ 'VENDOR_NAME', 'STR', 'v.name', 'v.name AS vendor_name' ],
    [ 'DOMAIN_ID', 'INT', 'nas.domain_id' ],
    [ 'STATUS', 'INT', 'i.status', 1 ],
    [ 'DISABLE', 'INT', 'nas.disable', 1 ],
    [ 'TYPE_NAME', 'INT', 'm.type_id', 't.name AS type_name', 1 ],
    [ 'NAME_TYPE', 'STR', 't.name', 1 ],
    [ 'PORTS', 'INT', 'm.ports', 1 ],
    [ 'MAC', 'INT', 'nas.mac', 1 ],
    [ 'PORT_SHIFT', 'INT', 'm.port_shift', 1 ],
    [ 'NAS_IP', 'IP', 'nas.ip', 'INET_NTOA(nas.ip) AS nas_ip' ],
    [ 'MNG_HOST_PORT', 'STR', 'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_ip_port', ],
    #['MNG_USER',         'STR', 'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_USER', 'STR', 'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_PASSWORD', 'STR', '', "DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password" ],
    [ 'NAS_ID', 'INT', 'i.nas_id', 1 ],
    [ 'NAS_GID', 'INT', 'nas.gid', 1 ],
    [ 'NAS_GROUP_NAME', 'STR', 'ng.name', 'ng.name AS nas_group_name' ],
    [ 'DISTRICT_ID', 'INT', 'streets.district_id', 'districts.name' ],
    [ 'LOCATION_ID', 'INT', 'nas.location_id', 1 ],
    [ 'DOMAIN_ID', 'INT', 'nas.domain_id', 1 ],
    [ 'COORDX', 'INT', 'builds.coordx', 1 ],
    [ 'COORDY', 'INT', 'builds.coordy', 1 ],
    [ 'REVISION', 'STR', 'i.revision', 1 ],
    [ 'SNMP_VERSION', 'STR', 'i.snmp_version', 1 ],
    [ 'SERVER_VLAN', 'STR', 'i.server_vlan', 1 ],
    [ 'LAST_ACTIVITY', 'DATE', 'i.last_activity', 1 ],
    [ 'INTERNET_VLAN', 'STR', 'i.internet_vlan', 1 ],
    [ 'TR_069_VLAN', 'STR', 'i.tr_069_vlan', 1 ],
    [ 'IPTV_VLAN', 'STR', 'i.iptv_vlan', 1 ],
    [ 'PORT', 'INT', 'p.port', 1 ],
    [ 'VLAN', 'INT', 'p.vlan', 1 ],
    [ 'STATUS', 'INT', 'p.status', 1 ],


  ],
    { WHERE => 1,
    }
  );

  my %EXT_TABLE_JOINS_HASH = ();

  if ($WHERE . $self->{SEARCH_FIELDS} =~ /nas\./) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
  }

  if ($attr->{COORDX} || $attr->{COORDY}) {
    $EXT_TABLE_JOINS_HASH{builds} = 1;
  }

  if ($attr->{ADDRESS_FULL}) {
    $attr->{BUILD_DELIMITER} = ',' if (!$attr->{BUILD_DELIMITER});
    my @fields = @{$self->search_expr($attr->{ADDRESS_FULL}, "STR", "CONCAT(streets.name, ' ', builds.number) AS address_full", { EXT_FIELD => 1 })};

    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{builds} = 1;
    $EXT_TABLE_JOINS_HASH{streets} = 1;
    $EXT_TABLE_JOINS_HASH{disctrict} = 1;
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }

  if ($attr->{NAS_GROUP_NAME}) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{nas_gid} = 1;
  }

  my $EXT_TABLES = $self->mk_ext_tables({ JOIN_TABLES => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN                                    => [ 'nas:LEFT JOIN nas ON (nas.id=i.nas_id)',
      'nas_gid:LEFT JOIN nas_groups ng ON (ng.id=nas.gid)',
      'builds:LEFT JOIN builds ON (builds.id=nas.location_id)',
      'streets:LEFT JOIN streets ON (streets.id=builds.street_id)',
      'disctrict:LEFT JOIN districts ON (districts.id=streets.district_id)',
    ],
    EXTRA_PRE_ONLY                                    => 1,
  });

  $self->query("SELECT
        $self->{SEARCH_FIELDS}
        m.id,
        i.nas_id
    FROM equipment_infos i
      INNER JOIN equipment_models m ON (m.id=i.model_id)
      INNER JOIN equipment_types t ON (t.id=m.type_id)
      INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
      INNER JOIN equipment_ports p ON (i.nas_id=p.nas_id)
      $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total
    FROM equipment_infos i
      INNER JOIN equipment_models m ON (m.id=i.model_id)
      INNER JOIN equipment_types t ON (t.id=m.type_id)
      INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
    $EXT_TABLES
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
=head2 cvlan_svlan_list($attr)

=cut
#**********************************************************
sub cvlan_svlan_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'PORT', 'INT', 'p.port', 1 ],
    [ 'NAS_NAME', 'STR', 'n.name', 1 ],
    [ 'VLAN', 'INT', 'p.vlan', 1 ],
    [ 'NAS_ID', 'INT', 'i.nas_id', ],
    [ 'SERVER_VLAN', 'STR', 'i.server_vlan', 1 ],
    [ 'ONU_VLAN', 'STR', 'onu.vlan', 1 ],
    [ 'ONU_DHCP_PORT', 'STR', 'onu.onu_dhcp_port', 1 ],
  ],
    { WHERE => 1 }
  );

  if ($attr->{ONU}) {
    $self->query("SELECT
      $self->{SEARCH_FIELDS}
      i.nas_id,
      onu.onu_dhcp_port,
      onu.vlan,
      i.server_vlan
      FROM equipment_pon_onu onu
    INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
    INNER JOIN nas n ON (n.id=p.nas_id)
    LEFT JOIN equipment_infos i ON (i.nas_id=n.id)
      $WHERE;",
      undef,
      { COLS_NAME => 1, COLS_UPPER => 1 }
    );
  }
  else {
    $self->query("SELECT
      $self->{SEARCH_FIELDS}
      i.nas_id,
      p.port,
      p.vlan,
      i.server_vlan
      FROM equipment_ports p
      INNER JOIN nas n ON (n.id=p.nas_id)
      LEFT JOIN equipment_infos i ON (i.nas_id=n.id)
      $WHERE;",
      undef,
      { COLS_NAME => 1, COLS_UPPER => 1 }
    );
  }

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 graph_list($attr)

=cut
#**********************************************************
sub graph_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'OBJ_ID', 'INT', 'obj_id', 1 ],
    [ 'PORT',   'STR', 'port',   1 ],
    [ 'PARAM',  'STR', 'param',  1 ],
    [ 'COMMENTS', 'STR', 'comments', 1 ],
    [ 'DATE',   'STR', 'date',   1 ],
    [ 'NAS_ID', 'INT', 'nas_id', 1 ],
    [ 'MEASURE_TYPE', 'STR', 'measure_type', 1 ],
    [ 'NAME',   'STR', 'name',   1 ],
    [ 'TYPE',   'STR', 'type',   1 ],

  ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} g.id, nas_id
    FROM equipment_graphs g
	INNER JOIN equipment_snmp_params p ON (p.id=g.param)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 graph_add($attr)

=cut
#**********************************************************
sub graph_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_graphs', {
    %$attr,
    DATE => 'NOW()',
  });

  return $self;
}

#**********************************************************
=head2 graph_change($attr)

=cut
#**********************************************************
sub graph_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_graphs',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 graph_del($id)

=cut
#**********************************************************
sub graph_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_graphs', { ID => $id });

  return $self;
}


#**********************************************************
=head2 graph_info($id, $attr)

=cut
#**********************************************************
sub graph_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM equipment_graphs
    WHERE id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 mac_log_list($attr)

=cut
#**********************************************************
sub mac_log_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 50;

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'ml.id';

  if ($attr->{NAS_ID} && $attr->{SORT} && $attr->{SORT} == 1) {
    $SORT = 'LPAD(port, 6, 0)';
  }

  my $WHERE = $self->search_former($attr, [
    #      ['ID',        'STR', 'ml.id',    1 ],
    [ 'PORT', 'STR', 'port', 1 ],
    [ 'PORT_NAME', 'STR', 'port_name', 1 ],
    [ 'MAC', 'STR', 'ml.mac', 1 ],
    [ 'IP', 'IP', 'ml.ip', 'INET_NTOA(ml.ip) AS ip' ],
    [ 'VLAN', 'INT', 'vlan', 1 ],
    [ 'DATETIME', 'STR', 'datetime', 1 ],
    [ 'REM_TIME', 'STR', 'rem_time', 1 ],
    [ 'UNIX_DATETIME', 'STR', 'datetime', 'unix_timestamp(datetime) AS unix_datetime' ],
    [ 'UNIX_REM_TIME', 'STR', 'rem_time', 'unix_timestamp(rem_time) AS unix_rem_time' ],
    [ 'NAME', 'INT', 'name', 1 ],
    [ 'NAS_ID', 'INT', 'nas_id', 1 ],
    [ 'MAC_COUNT', 'STR', '', 'COUNT(ml.mac) AS mac_count' ],
    [ 'MAC_UNIQ_COUNT', 'STR', '', 'COUNT(DISTINCT ml.mac) AS mac_uniq_count' ],
  ],
    { WHERE => 1,
    }
  );
  if ($attr->{MAC_COUNT}) {
    $WHERE .= ' and unix_timestamp(datetime) > unix_timestamp(rem_time)';
  }
  if ($attr->{USER_NAS}) {
    my @fields = @{$self->search_expr("$attr->{USER_NAS}", "STR", "CONCAT('--') AS user_nas", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }
  $self->query("SELECT 
    $self->{SEARCH_FIELDS} ml.id AS id
    FROM equipment_mac_log ml
    LEFT JOIN nas n ON (n.id=nas_id)
    $WHERE
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
    FROM equipment_mac_log ml
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 mac_log_add($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub mac_log_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{MULTI_QUERY}) {
    $self->query("INSERT INTO equipment_mac_log (
      mac, 
      nas_id, 
      vlan, 
      port, 
      port_name,
      datetime
    ) VALUES (?, ?, ?, ?, ?, NOW());",
      undef,
      { MULTI_QUERY => $attr->{MULTI_QUERY} });
  }
  else {
    $self->query("SELECT ip FROM equipment_mac_log  WHERE nas_id='$attr->{NAS_ID}'
       AND mac='$attr->{MAC}'
       AND vlan='$attr->{VLAN}'
       AND port='$attr->{PORT}'"
    );

    if ($self->{TOTAL}) {
      $self->query("UPDATE equipment_mac_log SET datetime=NOW()
        WHERE nas_id='$attr->{NAS_ID}'
          AND mac='$attr->{MAC}'
          AND vlan='$attr->{VLAN}'
          AND port='$attr->{PORT}'",
        'do'
      );
    }
    else {
      $self->query("INSERT INTO equipment_mac_log (mac, nas_id, vlan, port, port_name, datetime) VALUES
    			('$attr->{MAC}', '$attr->{NAS_ID}', '$attr->{VLAN}', '$attr->{PORT}', '$attr->{PORT_NAME}', NOW());", 'do'
      );
    }
  }

  return $self;
}
#**********************************************************
=head2 mac_log_change($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub mac_log_change {
  my $self = shift;
  my ($attr) = @_;
  my $time = ($attr->{REM_TIME}) ? "rem_time" : "datetime";
  if ($attr->{MULTI_QUERY}) {
    $self->query("UPDATE equipment_mac_log SET
      $time = NOW()
      WHERE id= ? ; ", undef,
      { MULTI_QUERY => $attr->{MULTI_QUERY} }
    );
  }
  return $self;
}
#**********************************************************
=head2 mac_notif_add($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub mac_notif_add {
  my $self = shift;
  my ($attr) = @_;

  my $time = ($attr->{DATETIME}) ? 'datetime' : 'rem_time';
  $self->query("INSERT INTO equipment_mac_log (mac, nas_id, vlan, port, port_name $time) VALUES
				('$attr->{MAC}', '$attr->{NAS_ID}', '$attr->{VLAN}', '$attr->{PORT}', '$attr->{PORT_NAME}', NOW())
				ON DUPLICATE KEY UPDATE $time=NOW();", 'do'
  );

  return $self;
}


#**********************************************************
=head2 mac_log_del($attr)

=cut
#**********************************************************
sub mac_log_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{DEL_PERIOD}) {
    $self->query("DELETE FROM equipment_mac_log WHERE datetime < curdate() - INTERVAL $attr->{DEL_PERIOD} DAY; ", "do");
  }
  else {
    $self->query_del('equipment_mac_log', $attr, (($attr->{NAS_ID}) ? $attr : undef), { CLEAR_TABLE => $attr->{ALL} });
  }

  return $self;
}

#**********************************************************
=head2 onu_list($attr)

=cut
#**********************************************************
sub onu_list {
  my $self = shift;
  my ($attr) = @_;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 5;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  #$PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  #$PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS} = '';
  $attr->{SKIP_DEL_CHECK}= 1;

  my $WHERE = $self->search_former($attr, [
    [ 'BRANCH',      'STR', 'p.branch',                      1 ],
    [ 'BRANCH_DESC', 'STR', 'p.branch_desc',                 1 ],
    [ 'VLAN_ID',     'STR', 'p.vlan_id',                     1 ],
    #    [ 'VLAN_ID', 'STR', 'onu.vlan', 1 ],
    [ 'ONU_ID',      'STR', 'onu.onu_id',                    1 ],
    [ 'ONU_VLAN',    'STR', 'onu.vlan',                      1 ],
    [ 'MAC_SERIAL',  'STR', 'onu.onu_mac_serial', 'onu.onu_mac_serial AS mac_serial' ],
    [ 'COMMENTS',    'STR', 'onu.onu_desc', 'onu.onu_desc AS comments' ],
    [ 'OLT_RX_POWER','STR', 'onu.olt_rx_power',              1 ],
    [ 'RX_POWER',    'STR', 'onu.onu_rx_power', 'onu.onu_rx_power AS rx_power' ],
    [ 'TX_POWER',    'STR', 'onu.onu_tx_power', 'onu.onu_tx_power AS tx_power' ],
    [ 'STATUS',      'STR', 'onu.onu_status', 'onu.onu_status AS status' ],
    [ 'ONU_DHCP_PORT','STR','onu.onu_dhcp_port',              1 ],
    [ 'ONU_GRAPH',   'STR', 'onu.onu_graph',                  1 ],
    [ 'NAS_ID',      'STR', 'p.nas_id',                       0 ],
    [ 'NAS_NAME',    'STR', 'n.name', 'n.name AS nas_name'      ],
    [ 'NAS_IP',      'STR', 'INET_NTOA(n.ip) AS nas_ip',      1 ],
    [ 'PON_TYPE',    'STR', 'p.pon_type',                     0 ],
    [ 'OLT_PORT',    'STR', 'p.id',                           0 ],
    [ 'ONU_SNMP_ID', 'INT', 'onu.onu_snmp_id',                1 ],
    [ 'DATETIME',    'DATE','onu.datetime',                   1 ],
    [ 'DELETED',     'STR', 'onu.deleted',                    1 ],
    [ 'SERVER_VLAN', 'STR', 'i.server_vlan',                  1 ],
  ],
    { WHERE        => 1,
      USERS_FIELDS => 1,
      USE_USER_PI  => 1,
      SKIP_USERS_FIELDS => [ ]
    });

  if ($attr->{TRAFFIC}) {
    my @fields = @{$self->search_expr($attr->{TRAFFIC}, "STR", "CONCAT(onu.onu_in_byte, ',', onu.onu_out_byte) AS traffic", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }
#  if ($attr->{LOGIN}) {
#    my @fields = @{$self->search_expr($attr->{LOGIN}, "STR", "CONCAT('--') AS login", { EXT_FIELD => 1 })};
#    $self->{SEARCH_FIELDS} .= join(', ', @fields);
#  }
  if ($attr->{USER_MAC}) {
    my @fields = @{$self->search_expr($attr->{USER_MAC}, "STR", "CONCAT('--') AS user_mac", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }

  # if ($attr->{FIO}) {
  #   my @fields = @{$self->search_expr($attr->{FIO}, "STR", "CONCAT('--') AS fio", { EXT_FIELD => 1 })};
  #   $self->{SEARCH_FIELDS} .= join(', ', @fields);
  # }
  # if ($attr->{ADDRESS_FULL}) {
  #   my @fields = @{$self->search_expr($attr->{ADDRESS_FULL}, "STR", "CONCAT('--') AS address_full", { EXT_FIELD => 1 })};
  #   $self->{SEARCH_FIELDS} .= join(', ', @fields);
  # }

  my $EXT_TABLES = q{};
  if($self->{EXT_TABLES} || $attr->{LOGIN}) {
    $EXT_TABLES = '
      LEFT JOIN internet_main internet ON (onu.onu_dhcp_port=internet.port AND p.nas_id=internet.nas_id)
      LEFT JOIN users u ON (u.uid=internet.uid) ';
    $EXT_TABLES .= $self->{EXT_TABLES};
  }

  $self->query("SELECT
      onu.id AS ID,
      $self->{SEARCH_FIELDS}
      onu.id,
      p.nas_id,
      p.pon_type,
      p.snmp_id,
      onu.onu_id,
      onu.onu_snmp_id,
      onu.vlan AS vlan,
      onu.onu_dhcp_port AS dhcp_port
    FROM equipment_pon_onu onu
    INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
    INNER JOIN nas n ON (n.id=p.nas_id)
    INNER JOIN equipment_infos i ON (i.nas_id = n.id)
    $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total
    FROM equipment_pon_onu onu
      INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 onu_list_vlan($attr)

=cut
#**********************************************************
#@deprecated
sub onu_list_vlan {
  my $self = shift;
  my ($attr) = @_;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 5;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  #$PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  #$PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS} = '';
$self->{debug}=1;
  my $WHERE = $self->search_former($attr, [
    [ 'BRANCH', 'STR', 'p.branch', 1 ],
    [ 'BRANCH_DESC', 'STR', 'p.branch_desc', 1 ],
    #    [ 'VLAN_ID', 'STR', 'p.vlan_id', 1 ],
    [ 'VLAN_ID', 'STR', 'onu.vlan', 'onu.vlan as vlan_id' ],
    [ 'ONU_ID', 'STR', 'onu.onu_id', 1 ],
    [ 'ONU_VLAN', 'STR', 'onu.vlan', 1 ],
    [ 'MAC_SERIAL', 'STR', 'onu.onu_mac_serial', 'onu.onu_mac_serial AS mac_serial' ],
    [ 'COMMENTS', 'STR', 'onu.onu_desc', 'onu.onu_desc AS comments' ],
    [ 'OLT_RX_POWER', 'STR', 'onu.olt_rx_power', 1 ],
    [ 'RX_POWER', 'STR', 'onu.onu_rx_power', 'onu.onu_rx_power AS rx_power' ],
    [ 'TX_POWER', 'STR', 'onu.onu_tx_power', 'onu.onu_tx_power AS tx_power' ],
    [ 'STATUS', 'STR', 'onu.onu_status', 'onu.onu_status AS status' ],
    [ 'ONU_DHCP_PORT', 'STR', 'onu.onu_dhcp_port', 1 ],
    [ 'ONU_GRAPH', 'STR', 'onu.onu_graph', 1 ],
    [ 'NAS_ID', 'STR', 'p.nas_id', 0 ],
    [ 'NAS_NAME', 'STR', 'n.name', 'n.name AS nas_name' ],
    [ 'PON_TYPE', 'STR', 'p.pon_type', 0 ],
    [ 'OLT_PORT', 'STR', 'p.id', 0 ],
    [ 'ONU_SNMP_ID', 'INT', 'onu.onu_snmp_id', 1 ],
    [ 'DATETIME', 'DATE', 'onu.datetime', 1 ],
    [ 'DELETED', 'STR', 'onu.deleted', 1 ]
  ],
    { WHERE => 1,
    });

  if ($attr->{TRAFFIC}) {
    my @fields = @{$self->search_expr("$attr->{TRAFFIC}", "STR", "CONCAT(onu.onu_in_byte, ',', onu.onu_out_byte) AS traffic", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }
  if ($attr->{LOGIN}) {
    my @fields = @{$self->search_expr("$attr->{LOGIN}", "STR", "CONCAT('--') AS login", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }
  if ($attr->{USER_MAC}) {
    my @fields = @{$self->search_expr("$attr->{USER_MAC}", "STR", "CONCAT('--') AS user_mac", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }
  if ($attr->{FIO}) {
    my @fields = @{$self->search_expr("$attr->{FIO}", "STR", "CONCAT('--') AS fio", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }
  if ($attr->{ADDRESS_FULL}) {
    my @fields = @{$self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT('--') AS address_full", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }

  $self->query("SELECT
      onu.id AS ID,
      $self->{SEARCH_FIELDS}
      onu.id,
      p.nas_id,
      p.pon_type,
      p.snmp_id,
      p.branch,
      onu.onu_id,
      onu.onu_snmp_id,
      onu.vlan AS vlan,
      onu.onu_dhcp_port AS dhcp_port
    FROM equipment_pon_onu onu
    INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
    INNER JOIN nas n ON (n.id=p.nas_id)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total
    FROM equipment_pon_onu onu
      INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 onu_add($attr)

=cut
#**********************************************************
sub onu_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{MULTI_QUERY}) {
    $self->query("INSERT INTO equipment_pon_onu (
      olt_rx_power,
      onu_rx_power,
      onu_tx_power,
      onu_status,
      onu_in_byte,
      onu_out_byte,
      onu_dhcp_port,
      port_id,
      onu_mac_serial,
      vlan,
      onu_desc,
      onu_id,
      onu_snmp_id,
      line_profile,
      srv_profile,
      datetime
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW());",
      undef,
      { MULTI_QUERY => $attr->{MULTI_QUERY} });
  }
  else {
    $self->query_add('equipment_pon_onu', $attr);
    $self->{admin}->{MODULE} = 'Equipment';
    $self->{admin}->system_action_add("NAS_ID: $attr->{NAS_ID} ONU: $attr->{ONU_MAC_SERIAL}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 onu_change($attr)

=cut
#**********************************************************
sub onu_change {
  my $self = shift;
  my ($attr) = @_;
  #MULTI_QUERY
  #`olt_rx_power`, `onu_rx_power`, `onu_tx_power`, `onu_status`, `onu_in_byte`, `onu_out_byte`, `onu_dhcp_port`

  if ($attr->{MULTI_QUERY}) {
    $self->query("UPDATE equipment_pon_onu SET
      olt_rx_power= ? ,
      onu_rx_power= ? ,
      onu_tx_power= ? ,
      onu_status= ? ,
      onu_in_byte= ? ,
      onu_out_byte= ? , 
      onu_dhcp_port= ? , 
      port_id= ? , 
      onu_mac_serial= ? ,
      vlan = ?,
      onu_desc= ? , 
      onu_id= ? ,
      line_profile= ?,
      srv_profile= ?,
      deleted= ?,
      datetime = NOW()
      WHERE id= ? ; ", undef,
      { MULTI_QUERY => $attr->{MULTI_QUERY} }
    );
  }
  else {
    $self->changes(
      {
        CHANGE_PARAM => 'ID',
        TABLE        => 'equipment_pon_onu',
        DATA         => $attr
      }
    );
  }

  return $self;
}

#**********************************************************
=head2 onu_del($id)

=cut
#**********************************************************
sub onu_del {
  my $self = shift;
  my ($id, $attr) = @_;

  my $del_info = '';
  if ($id) {
    my $onu_info = $self->onu_info($id);
    $del_info = "NAS_ID: $onu_info->{NAS_ID} ONU: $onu_info->{ONU_MAC_SERIAL}";
  }
  elsif ($attr->{PORT_ID}) {
    $del_info = "ONU DEL PORT ID: $attr->{PORT_ID}";
  }
  $del_info .= " COMMENTS: $attr->{COMMENTS}" if ($attr->{COMMENTS});

  $self->query_del('equipment_pon_onu', { ID => $id }, { port_id => $attr->{PORT_ID} });
  $admin->{MODULE} = 'Equipment';

  $admin->system_action_add($del_info, { TYPE => 10 });

  return $self;
}


#**********************************************************
=head2 onu_info($id, $attr)

=cut
#**********************************************************
sub onu_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM equipment_pon_onu onu
    INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
    WHERE onu.id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}


#**********************************************************
=head2 pon_port_list($attr)

=cut
#**********************************************************
sub pon_port_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'NAS_ID',    'STR', 'p.nas_id', 1 ],
    [ 'ONU_COUNT', 'STR', '', 'COUNT(onu.id) AS onu_count' ],
    [ 'BRANCH',    'STR', 'p.branch', 1 ],
    [ 'SNMP_ID',   'STR', 'p.snmp_id', 1 ]
  ],
    { WHERE => 1 }
  );

  my $EXT_TABLE = q{};
  my $GROUP_BY = '';
  if ($attr->{ONU_COUNT}) {
    $EXT_TABLE = "LEFT JOIN equipment_pon_onu onu ON (onu.port_id=p.id)";
    $GROUP_BY = " GROUP BY p.id";
  }

  $self->query("SELECT
    p.snmp_id,
    p.nas_id,
    p.pon_type,
    p.branch,
    p.branch_desc,
    p.vlan_id,
    $self->{SEARCH_FIELDS}
    p.id
    FROM equipment_pon_ports p
    $EXT_TABLE
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}
#**********************************************************
=head2 pon_port_add($attr)

=cut
#**********************************************************
sub pon_port_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_pon_ports', $attr);

  return $self;
}

#**********************************************************
=head2 pon_port_change($attr)

=cut
#**********************************************************
sub pon_port_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_pon_ports',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 pon_port_del($id)

=cut
#**********************************************************
sub pon_port_del {
  my $self = shift;
  my ($id) = @_;

  $self->onu_list({ OLT_PORT => $id });

  if ($self->{TOTAL}) {
    $self->{errno} = 1;
    $self->{ONU_TOTAL} = $self->{TOTAL};
  }
  else {
    $self->query_del('equipment_pon_ports', { ID => $id });
  }

  return $self;
}
#**********************************************************
=head2 type_info($id, $attr)

=cut
#**********************************************************
sub pon_port_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM equipment_pon_ports
    WHERE id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 trap_type_add($attr) -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub trap_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_trap_types', $attr);

  return $self;
}

#**********************************************************
=head2 trap_type_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub trap_type_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'OBJECT_ID', 'STR', 'object_id', 1 ],
    [ 'TYPE', 'INT', 'type', 1 ],
    [ 'EVENT', 'INT', 'event', 1 ],
    [ 'SKIP', 'INT', 'skip', 1 ],
    [ 'COLOR', 'INT', 'color', 1 ],
    [ 'VARBIND', 'STR', 'varbind', 1 ],
  ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT
    $self->{SEARCH_FIELDS}
    id
    FROM equipment_trap_types
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return [] if ($self->{errno});
  return $self->{list_hash} if ($attr->{LIST2HASH});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 trap_type_del() -

=cut
#**********************************************************
sub trap_type_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_trap_types', { ID => $id });

  return $self;
}

#**********************************************************
=head2 trap_type_change() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub trap_type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_trap_types',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 graphs_clean($attr)

=cut
#**********************************************************
sub graphs_clean {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM equipment_counter64_stats WHERE datetime < CURDATE() - INTERVAL $attr->{PERIOD} day;", 'do');

  return $self;
}

#**********************************************************
=head2 ping_log_add($attr)

=cut
#**********************************************************
sub ping_log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_ping_log', $attr);

  return $self;
}
#**********************************************************
=head2 tr_069_settings_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub tr_069_settings_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',          'INT', 'id', 1 ],
    [ 'ONU_ID',      'INT', 'tr.onu_id', 1 ],
    [ 'NAS_NAME',    'STR', 'n.name', 'n.name AS nas_name' ],
    [ 'UPDATETIME',  'STR', 'tr.updatetime', 1 ],
    [ 'CHANGETIME',  'STR', 'tr.changetime', 1 ],
    [ 'UNIX_UPDATETIME', 'STR', 'tr.updatetime', 'UNIX_TIMESTAMP(tr.updatetime) AS unix_updatetime' ],
    [ 'UNIX_CHANGETIME', 'STR', 'tr.changetime', 'UNIX_TIMESTAMP(tr.changetime) AS unix_changetime' ],
    [ 'SETTINGS',    'STR', 'tr.settings', 1 ],
    [ 'SERIAL',      'STR', 'o.onu_mac_serial', 1 ],
  ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT
    $self->{SEARCH_FIELDS}
    tr.id 
    FROM equipment_pon_onu o
    LEFT JOIN equipment_pon_ports p ON (p.id=o.port_id)
    LEFT JOIN nas n ON (n.id=p.nas_id)
    LEFT JOIN equipment_tr_069_settings tr ON (tr.onu_id=o.id)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return [] if ($self->{errno});
  return $self->{list_hash} if ($attr->{LIST2HASH});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 tr_069_settings_del() -

=cut
#**********************************************************
sub tr_069_settings_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('equipment_tr_069_settings', { ONU_ID => $id });

  return $self;
}

#**********************************************************
=head2 tr_069_settings_change() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub tr_069_settings_change {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query("SELECT id FROM equipment_tr_069_settings  WHERE onu_id='$id'");
  if ($self->{TOTAL}) {
    my $time = ($attr->{UPDATE}) ? 'updatetime' : 'changetime';
    my $settings = ($attr->{SETTINGS}) ? ", settings='$attr->{SETTINGS}'" : '';
    $self->query("UPDATE equipment_tr_069_settings SET $time=NOW() $settings
      WHERE onu_id='$id'",
      'do'
    );
  }
  else {
    $self->query("INSERT INTO equipment_tr_069_settings (onu_id, changetime, settings) VALUES
                      ('$id', NOW(), '$attr->{SETTINGS}');", 'do'
    );
  }

  return $self;
}
#**********************************************************
=head2 tr_069_settings_change() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub equipment_all_info {
  my $self = shift;

  $self->query("
    SELECT COUNT(name) as total_count FROM nas;");

  return $self->{list};
  # _bp('', $self);
}

1
