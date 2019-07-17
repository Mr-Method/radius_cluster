package Cams;

=name2

  Cams

=VERSION

  VERSION = 0.01

=cut

use strict;
use warnings FATAL => 'all';

use parent 'main';

use Abon;

my $Abon;

#**********************************************************

=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut

#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    MODULE => 'Cams'
  };

  $Abon = Abon->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************

=head2 users_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub users_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'cm.uid';
  my $DESC      = ($attr->{DESC})      ? ''                 : 'DESC';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'UID', 'INT', 'cm.uid', ],
    [ 'LOGIN',              'STR',  'u.id as login',                         1 ],
    [ 'CREATED',            'DATE', 'cm.created',                            1 ],
    [ 'TP_ID',              'INT',  'cm.tp_id',                              1 ],
    [ 'TP_NAME',            'STR',  'ctp.name as tp_name',                   1 ],
    [ 'TP_STREAMS_COUNT',   'INT',  'ctp.streams_count as tp_streams_count', 1 ],
    [ 'USER_STREAMS_COUNT', 'INT',  'COUNT(*) as user_streams_count',        1 ],
    [ 'ABON_NAME',          'STR',  'atp.name abon_name' ],
    [ 'ABON_ID',            'STR',  'atp.id abon_id' ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} cm.uid
   FROM cams_main cm
   LEFT JOIN users u           ON (cm.uid=u.uid)
   LEFT JOIN cams_streams cs   ON (cm.uid=cs.uid)
   LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.id)
   LEFT JOIN abon_tariffs atp  ON (ctp.id=atp.id)
   $WHERE GROUP BY cm.uid ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS ;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 user_info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut

#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid) = @_;

  my $list = $self->users_list({ COLS_NAME => 1, UID => $uid, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 user_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{CREATED}) { $attr->{CREATED} = 'NOW()' }

  $self->query_add('cams_main', $attr);

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 users_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub users_del {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || $attr->{del};

  $self->query_del( 'cams_main', $attr, { 'uid' => [ $uid ] } );

  return 1;
}

#**********************************************************

=head2 user_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'cams_main',
      DATA         => $attr,
    }
  );

  return 1;
}

#**********************************************************

=head2 tp_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'ctp.id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID',            'INT', 'ctp.id',                1 ],
    [ 'NAME',          'STR', 'ctp.name',              1 ],
    [ 'STREAMS_COUNT', 'INT', 'ctp.streams_count',     1 ],
    [ 'ABON_ID',       'INT', 'ctp.abon_id',           1 ],
    [ 'ABON_NAME',     'STR', 'atp.name as abon_name', 1 ],

    [ 'PAYMENT_TYPE',  'INT', 'atp.payment_type',      1 ],
    [ 'FEES_TYPE',     'INT', 'atp.fees_type',         1 ],
    [ 'PRICE',         'INT', 'atp.price',             1 ]

  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless exists $attr->{ $_->[0] } } @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} 1
   FROM cams_tp ctp LEFT JOIN abon_tariffs atp ON (ctp.abon_id=atp.id)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************

=head2 tp_info($id)

  Arguments:
    $id - id for tp

  Returns:
    hash_ref

=cut

#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->tp_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 tp_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;

  unless ($attr->{ABON_ID}) {
    $self->{errno} = 10;
    return 0;
  }

  $self->query_add('cams_tp', $attr);

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 tp_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_tp', $attr);

  return 1;
}

#**********************************************************

=head2 tp_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_tp',
      DATA         => $attr,
    }
  );

  return 1;
}

#**********************************************************

=head2 streams_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub streams_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'cs.id';
  my $DESC      = ($attr->{DESC})      ? ''                 : 'DESC';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID',            'INT', 'cs.id',                                                               1 ],
    [ 'UID',           'INT', 'cs.uid',                                                              1 ],
    [ 'USER_LOGIN',    'STR', 'u.id AS user_login',                                                  1 ],
    [ 'DISABLED',      'INT', 'cs.disabled',                                                         1 ],
    [ 'NAME',          'STR', 'cs.name',                                                             1 ],
    [ 'HOST',          'STR', 'cs.host',                                                             1 ],
    [ 'LOGIN',         'STR', 'cs.login',                                                            1 ],
    [ 'PASSWORD',      'STR', 'DECODE(cs.password, "' . $self->{conf}{secretkey} . '") as password', 1 ],
#    [ 'PASSWORD',      'STR', 'cs.password', 1 ],
    [ 'RTSP_PORT',     'INT', 'cs.rtsp_port',                                                        1 ],
    [ 'RTSP_PATH',     'STR', 'cs.rtsp_path',                                                        1 ],
    [ 'NAME_HASH',     'STR', qq{CONCAT (MD5( CONCAT (cs.host, cs.login, cs.password) ), '__', cs.id ) AS name_hash},          1 ],
    [ 'ZONEMINDER_ID', 'INT', 'cs.zoneminder_id',                                                    1 ],
    [ 'ORIENTATION', 'INT', 'cs.orientation',                                                    1 ],

  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} cs.id
   FROM cams_streams cs
   LEFT JOIN users u ON (cs.uid=u.uid)
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
    ,
    undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 stream_info($id)

  Arguments:
    $id - id for streams

  Returns:
    hash_ref

=cut

#**********************************************************
sub stream_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->streams_list(
    {
      COLS_NAME        => 1,
      ID               => $id,
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER       => 1
    }
  );

  return $list->[0] || {};
}

#**********************************************************

=head2 stream_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub stream_add {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add('cams_streams', {
      %{ $attr ? $attr : {}},
      PASSWORD => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
    });

  return undef if $self->{errno};
  return $self->{INSERT_ID};
}

#**********************************************************

=head2 stream_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub stream_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_streams', $attr);

  return 1;
}

#**********************************************************

=head2 stream_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub stream_change {
  my $self = shift;
  my ($attr) = @_;
  
  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_streams',
      DATA         => {
        %{ $attr ? $attr : {}},
        PASSWORD => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
      },
    }
  );
  
  return 1;
}

1;