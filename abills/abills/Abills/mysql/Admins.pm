package Admins;

=head1 NAME

  Administrators manage functions

=cut

use strict;
use parent qw(dbcore);

my $IP;
my $SORT      = 1;
my $DESC      = '';
my $PG        = 0;
my $PAGE_ROWS = 25;

#**********************************************************
#
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  my ($CONF)   = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}  = $db;
  $self->{conf}= $CONF;
  $self->{admin}=$self;

  return $self;
}

#**********************************************************
=head2 admins_groups_list() - Admin groups list

=cut
#**********************************************************
sub admins_groups_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{ALL}) {

  }
  else {
    $WHERE = ($attr->{AID}) ? "AND ag.aid='$attr->{AID}'" : "AND ag.aid='$self->{AID}'";
  }

  $self->query("SELECT ag.gid, ag.aid, g.name
    FROM admins_groups ag, groups g
    WHERE g.gid=ag.gid $WHERE;",
  undef,
  $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 admins_groups_list()

=cut
#**********************************************************
sub admin_groups_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('admins_groups', undef, { aid => $self->{AID} });
  my @groups = split(/,/, $attr->{GID});
   my @MULTI_QUERY = ();

  foreach my $gid (@groups) {
    push @MULTI_QUERY, [ $attr->{AID}, $gid ];
  }

  $self->query("INSERT INTO admins_groups (aid, gid) VALUES (?, ?);",
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  $self->system_action_add("AID:$attr->{AID} GID: " . (join(',', @groups)), { TYPE => 2 });
  return $self;
}

#**********************************************************
=head2 get_permissions()

=cut
#**********************************************************
sub get_permissions {
  my $self        = shift;
  my %permissions = ();

  $self->query("SELECT section, actions, module FROM admin_permits WHERE aid=?;", undef, { Bind => [ $self->{AID} ]});

  foreach my $line (@{ $self->{list} }) {
    my ($section, $action, $module) = @$line;
    $permissions{$section}{$action} = 1;
    if ($module) {
      $self->{MODULES}{$module} = 1;
    }
  }

  $self->{permissions} = \%permissions;
  return $self->{permissions};
}

#**********************************************************
=head2 set_permissions($permissions) - Set admin permissions

  Arguments:
    $permissions - hash of permits

=cut
#**********************************************************
sub set_permissions {
  my $self = shift;
  my ($permissions) = @_;

  $self->query("DELETE FROM admin_permits WHERE aid= ? ;", 'do', { Bind => [ $self->{AID} ] });
  my @MULTI_QUERY = ();
  my @log = ();
  while (my ($section, $actions_hash) = each %$permissions) {
    while (my ($action, undef) = each %$actions_hash) {
      my ($perms, $module) = split(/_/, $action);
      next if ($section ne  int($section));
      push @MULTI_QUERY, [ $self->{AID}, $section, ($perms || 0), "$module" ];
      push @log, "$section:". ($perms || 0). ":$module";
    }
  }

  $self->query("INSERT INTO admin_permits (aid, section, actions, module)
      VALUES (?, ?, ?, ?);",
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  if ($self->{errno}) {
    return $self;
  }

  $self->{CHANGED_AID} = $self->{AID};
  $self->{AID}         = $self->{MAIN_AID};
  $IP                  = $self->{MAIN_SESSION_IP};

  $self->system_action_add("AID:$self->{CHANGED_AID} PERMISION:". join(';', @log), { TYPE => 65 });
  $self->{AID} = $self->{CHANGED_AID};

  return $self->{permissions};
}

#**********************************************************
=head2  info($aid, $attr) - Administrator information and auth function

  Arguments:
    LOGIN          - Login for auth
    PASSWORD       - Password for auth
    SECRETKEY      - Secret key for password decode (default: $CONF->{secretkey})
    API_KEY        - API key for auth
    EXTERNAL_AUTH  - Use external auth
    DOMAIN_ID      - Admin domian ID
    IP             - Session IP

  Returns:
    admin object

=cut
#**********************************************************
sub info {
  my ($self) = shift;
  my ($aid, $attr) = @_;

  my $PASSWORD = '0,';
  my $WHERE    = '';
  my @values   = ();

  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    if(! $attr->{LOGIN} || ! $attr->{PASSWORD} ) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    my $SECRETKEY = ($attr->{SECRETKEY}) ? $attr->{SECRETKEY} : $self->{conf}->{secretkey};
    $PASSWORD = "if(DECODE(a.password, '$SECRETKEY')= ? , 0, 1) AS password_match,";
    push @values, $attr->{PASSWORD};
    $WHERE    = "WHERE a.id= ? ";
    push @values, $attr->{LOGIN};
  }
  elsif($attr->{API_KEY}) {
    $WHERE = "WHERE a.api_key= ? ";
    push @values, $attr->{API_KEY};
  }
  elsif ($attr->{EXTERNAL_AUTH}) {
    $WHERE = "WHERE a.id= ? ";
    push @values, $attr->{LOGIN};
  }
  elsif ($attr->{DOMAIN_ID}) {
    $WHERE = "WHERE a.domain_id= ? ";
    push @values, $attr->{DOMAIN_ID};
  }
  elsif($attr->{TELEGRAM_ID}){
    $WHERE = "WHERE a.telegram_id= ? ";
    push @values, $attr->{TELEGRAM_ID};
  }
  elsif($attr->{SIP_NUMBER}){
    $WHERE = "WHERE a.sip_number= ? ";
    push @values, $attr->{SIP_NUMBER};
  }
  else {
    $WHERE = "WHERE a.aid= ? ";
    push @values, $aid;
  }

  $IP = ($attr->{IP}) ? $attr->{IP} : '0.0.0.0';
  my $fields = '';

  if (! $attr->{SHORT}) {
     $fields = "
     a.name AS a_fio,
     a.regdate,
     a.phone,
     a.position,
     a.email,
     a.comments,
     d.name AS domain_name,
     a.min_search_chars,
     a.address,
     a.cell_phone,
     a.pasport_num,
     a.pasport_date,
     a.pasport_grant,
     a.inn,
     a.birthday,
     a.api_key,
     a.sip_number,
     a.gps_imei,
     a.telegram_id,
     ";
  }

  $self->query("SELECT $fields
      $PASSWORD
      a.full_log,
      a.id AS a_login,
      a.disable,
      a.web_options,
      a.gid,
      a.position,
      a.domain_id,
      a.max_credit,
      a.max_rows,
      a.credit_days,
      COUNT(ag.aid) AS gids_,
      COUNT(aa.aid) AS admin_access,
      a.aid,
      a.name AS a_fio
     FROM
      admins a
     LEFT JOIN admins_groups ag ON (a.aid=ag.aid)
     LEFT JOIN domains d ON (a.domain_id=d.id)
     LEFT JOIN admins_access aa ON (aa.aid=a.aid)
     $WHERE
     GROUP BY a.aid
     ORDER BY a.aid DESC
     LIMIT 1;",
     undef,
     { INFO => 1,
       Bind => [ @values ] }
  );

  if ($self->{PASSWORD_MATCH} && $self->{PASSWORD_MATCH} ==  1) {
    $self->{errno}  = 4;
    $self->{errstr} = 'ERROR_WRONG_PASSWORD';
    return $self;
  }
  elsif($self->{errno}) {
    return $self;
  }

  if ($self->{GIDS_}) {
    $self->query("SELECT gid FROM admins_groups WHERE aid= ? ;", undef, {
      Bind => [ $self->{AID} ]
    });

    my @gid_arr = ();
    if($self->{GID}) {
      push @gid_arr, $self->{GID};
    }
    foreach my $line (@{ $self->{list} }) {
      push @gid_arr, $line->[0];
    }
    $self->{GID} = join(',', @gid_arr);
  }

  $self->{SESSION_IP} = $IP;

  return $self;
}

#**********************************************************
=head1 list($attr) - List admins

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLES  = '';

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $GROUP_BY = '';

  if ($attr->{GIDS}) {
    push @WHERE_RULES, "a.gid IN ($attr->{GIDS})";
  }

  if ($self->{DOMAIN_ID} || $attr->{DOMAIN_NAME}) {
    $attr->{DOMAIN_ID} = $self->{DOMAIN_ID};
    $EXT_TABLES = 'LEFT JOIN domains d ON (d.id=a.domain_id) ';
  }

  if($attr->{WITH_SIP_NUMBER}){
    push @WHERE_RULES, "a.sip_number!=''";
  }

  if ($attr->{WITH_POSITION}) {
    push @WHERE_RULES, "a.position != 0";
  }

  if ($attr->{POSITION} && $attr->{POSITION} ne '_SHOW') {
    push @WHERE_RULES, "a.position = '$attr->{POSITION}'";
  }

  if ($attr->{GID}) {
    $EXT_TABLES .= 'LEFT JOIN admins_groups ag ON (a.aid=ag.aid) ';
    $GROUP_BY = 'GROUP BY a.aid';
    push @WHERE_RULES, "(a.gid IN ($attr->{GID}) OR ag.gid IN ($attr->{GID}))";
  }


  my $WHERE = $self->search_former($attr, [
      ['ADMIN_NAME',   'STR',  'a.name',  'a.name AS admin_name' ],
      # ['POSITION',     'STR',  'ep.position',      1 ],
      ['REGDATE',      'DATE', "a.regdate",       1 ],
      ['START_WORK',   'DATE', "a.start_work",    1 ],
      #['GID',          'INT',  'ag.gid',          1 ],
      #['GID',          'INT',  'a.gid',           1 ],
      ['GPS_IMEI',     'STR',  'a.gps_imei',      1 ],
      ['DISABLE',      'INT',  "a.disable",       1 ],
      ['BIRTHDAY',     'DATE', 'a.birthday',      1 ],
      ['API_KEY',      'STR',  'a.api_key',       1 ],
      ['DOMAIN_NAME',  'STR',  'a.name', 'd.name AS domain_name' ],
      ['DOMAIN_ID',    'INT',  'a.domain_id',     1 ],
      ['AID',          'INT',  'a.aid'              ],
      ['SIP_NUMBER',   'INT',  'a.sip_number',    1 ],
      ['TELEGRAM_ID',  'STR',  'a.telegram_id',   1 ],
      ['EMAIL',        'STR',  'a.email',         1 ],
    ],
    {
      WHERE_RULES => \@WHERE_RULES,
      WHERE       => 1
    }
  );

  my $EMPLOYEE_JOIN = '';
  my $EMPLOYEE_COLS = '';
  #use Abills::Base;
  #FIXME: CHECK MODULE
  if ($self->{SHOW_EMPLOYEES} && $self->{SHOW_EMPLOYEES} == 1) {
    $EMPLOYEE_JOIN = " LEFT JOIN employees_positions ep ON (ep.id=a.position) ";
    $EMPLOYEE_COLS = ' ep.position as position, ';
  }

  $self->query("SELECT a.aid, a.id AS login,
    a.name,
    $EMPLOYEE_COLS
    $self->{SEARCH_FIELDS}
    g.name AS g_name
    FROM admins a
    LEFT JOIN groups g ON (a.gid=g.gid)
    $EMPLOYEE_JOIN
    $EXT_TABLES
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",

  undef,
  $attr
  );

  if($self->{errno}) {
    return [];
  }

  my $list = $self->{list};
  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT COUNT(DISTINCT a.aid) AS total
      FROM admins a
      LEFT JOIN groups g ON (a.gid=g.gid)
      $EXT_TABLES
      $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list || [];
}

#**********************************************************
=head1 change($attr) - Change admin info

=cut
#**********************************************************
sub change {
  my $self   = shift;
  my ($attr) = @_;

  if ($attr->{A_LOGIN}) {
    $attr->{ID} = $attr->{A_LOGIN};
  }

  $self->{MODULE}  = '';
  $IP              = $self->{SESSION_IP};
  $attr->{DISABLE} = 0 if (!$attr->{DISABLE} && $attr->{A_LOGIN});
  $attr->{FULL_LOG}= 0 if (!$attr->{FULL_LOG} && $attr->{A_LOGIN});
  $attr->{NAME}    = $attr->{A_FIO};

  $self->changes(
    {
      CHANGE_PARAM    => 'AID',
      TABLE           => 'admins',
      DATA            => $attr,
      EXT_CHANGE_INFO => "AID:$self->{AID}"
    }
  );

  $self->info($self->{AID});
  return $self;
}

#**********************************************************
=head1 add() - Add admin

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('admins', {
    ID       => $attr->{A_LOGIN},
    NAME     => $attr->{A_FIO},
    REGDATE  => 'NOW()',
    %$attr
  });

  if($self->{errno}) {
    return $self;
  }

  $self->{AID} = $self->{INSERT_ID};

  $self->system_action_add("AID:$self->{INSERT_ID} LOGIN:$attr->{A_LOGIN}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 del() - Delete admin

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('admins', undef, { aid =>  $id });
  $self->query_del('admin_permits', undef, { aid => $id });

  $self->system_action_add("AID:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 action_add($uid, $actions, $attr)

  Arguments:
    $uid,
    $actions,
    $attr
      ID
      INFO     - info fields. Show if assign
      REQUEST  - request params
      ACTION_COMMENTS
      IP

  Returns:

=cut
#**********************************************************
sub action_add {
  my $self = shift;
  my ($uid, $actions, $attr) = @_;

  if ($attr->{ACTION_COMMENTS}) {
    $actions .= ":$attr->{ACTION_COMMENTS}";
  }

  if($attr->{INFO} && $attr->{REQUEST}) {
    my @actions_history = ();
    my $request = $attr->{REQUEST};
    foreach my $param (@{ $attr->{INFO} }) {
      if(defined($request->{$param})) {
        push @actions_history, $param.":".$request->{$param};
      }
    }

    $actions .= join(', ', @actions_history);
  }

  $IP = $attr->{IP} if ($attr->{IP});

  $self->query_add('admin_actions', {
    AID         => $self->{AID},
    IP          => $IP || '0.0.0.0',
    DATETIME    => 'NOW()',
    ACTIONS     => $actions,
    UID         => $uid,
    MODULE      => ($self->{MODULE}) ? $self->{MODULE} : '',
    ACTION_TYPE => ($attr->{TYPE})   ? $attr->{TYPE}   : ''
  });

  return $self;
}

#**********************************************************
=head2 action_info($id)

=cut
#**********************************************************
sub action_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT aid, INET_NTOA(ip) AS ip, datetime, actions, uid, module AS modules, action_type
    FROM admin_actions WHERE id= ? ;",
    undef,
    { INFO => 1, Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 action_del($id)

=cut
#**********************************************************
sub action_del {
  my $self = shift;
  my ($id) = @_;

  $self->action_info($id);

  if ($self->{TOTAL} > 0) {
    $self->query_del('admin_actions', { ID => $id });
    $self->system_action_add("ACTION:$id DATETIME:$self->{DATETIME} UID:$self->{UID} CHANGED:$self->{ACTION}", { TYPE => 10 });
  }
}

#**********************************************************
=head2 action_summary($attr)

=cut
#**********************************************************
sub action_summary {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['TYPE',         'INT',  'aa.action_type',  ],
      ['DATE',         'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m-%d')"      ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m-%d')" ],
      ['MONTH',        'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m')"         ],
      ['UID',          'INT',  'aa.uid'           ],
      ['AID',          'INT',  'aa.aid'           ],
      ['ADMIN',        'INT',  'a.id', 'a.id'     ],
    ],
    {
      WHERE => 1
    }
  );

  $self->query("SELECT action_type, COUNT(*) AS total
    FROM admin_actions aa
    $WHERE
    GROUP BY action_type;",
    undef,
    $attr
  );

  return $self->{list};
}
#**********************************************************
=head2 action_list($attr) - Show admin users actions

=cut
#**********************************************************
sub action_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ( $attr->{GID} || $attr->{GIDS} ){
    $attr->{GIDS} = $attr->{GID} if (!$attr->{GIDS});
    if ( $attr->{GIDS} !~ /_SHOW/ ){
      my @system_admins = ();
      push @system_admins, $self->{conf}->{USERS_WEB_ADMIN_ID} if ($self->{conf}->{USERS_WEB_ADMIN_ID});
      push @system_admins, $self->{conf}->{SYSTEM_ADMIN_ID} if ($self->{conf}->{SYSTEM_ADMIN_ID});
      my $system_admins = '';
      my $users_gid = '';
      if(! $attr->{UID}) {
        if (!$attr->{ADMIN} && !$attr->{AID}) {
          $system_admins = "OR a.aid IN (" . join(',', @system_admins) . ")";
          $users_gid = "u.gid IN ( $attr->{GIDS} ) AND";
        }
        push @WHERE_RULES, "($users_gid (a.gid IN ($attr->{GIDS}) $system_admins))";
      }
    }
  }

  my $WHERE = $self->search_former($attr, [
      ['UID',          'INT',  'aa.uid',          ],
      ['LOGIN',        'STR',  'u.id',            ],
      ['DATETIME',     'DATE', 'aa.datetime'      ],
      ['RESPOSIBLE',   'INT',  'm.resposible',    ],
      ['ACTION',       'INT',  'aa.actions',      ],
      ['TYPE',         'INT',  'aa.action_type',  ],
      ['MODULE',       'STR',  'aa.module',       ],
      ['IP',           'IP',   'aa.ip',         "INET_NTOA(aa.ip) AS ip" ],
      ['DATE',         'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m-%d')"     ],
      ['MONTH',        'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m')" ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m-%d')" ],
      ['AID',          'INT',  'aa.aid'           ],
      ['ADMIN',        'STR',  'a.id', 'a.id as admin_login'],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
      USERS_FIELDS=> 1,
      USE_USER_PI => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    }
    );

  my $EXT_TABLES = $self->{EXT_TABLES} || '';
  $self->query("SELECT aa.id,
      u.id AS login,
      aa.datetime,
      aa.actions,
      a.id AS admin_login,
      aa.module,
      aa.action_type,
      $self->{SEARCH_FIELDS}
      aa.uid,
      aa.aid
   FROM admin_actions aa
      LEFT JOIN admins a ON (aa.aid=a.aid)
      LEFT JOIN users u ON (aa.uid=u.uid)
      $EXT_TABLES
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM admin_actions aa
    LEFT JOIN users u ON (aa.uid=u.uid)
    LEFT JOIN admins a ON (aa.aid=a.aid)
    $EXT_TABLES
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 system_action_add($actions, $attr)

=cut
#**********************************************************
sub system_action_add {
  my $self = shift;
  my ($actions, $attr) = @_;

  $self->query_add('admin_system_actions', {
    AID         => $self->{AID},
    IP          => "$IP",
    DATETIME    => 'NOW()',
    ACTIONS     => $actions,
    MODULE      => ($self->{MODULE}) ? $self->{MODULE} : '',
    ACTION_TYPE => ($attr->{TYPE}) ? $attr->{TYPE}   : ''
  });

  return $self;
}

#**********************************************************
=head2 system_action_del($action_id)

=cut
#**********************************************************
sub system_action_del {
  my $self = shift;
  my ($action_id) = @_;

  $self->query_del('admin_system_actions', { ID => $action_id });

  return $self;
}

#**********************************************************
=head2 system_action_list($attr)

=cut
#**********************************************************
sub system_action_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
      ['RESPOSIBLE',   'INT',  'm.resposible',    ],
      ['ACTION',       'INT',  'aa.actions',      ],
      ['TYPE',         'INT',  'aa.action_type',  ],
      ['MODULE',       'STR',  'aa.module',       ],
      ['IP',           'IP',   'aa.ip'            ],
      ['DATE',         'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m-%d')"     ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(aa.datetime, '%Y-%m-%d')" ],
      ['AID',          'INT',  'aa.aid'           ],
      ['ADMIN',        'STR',  'a.id', 'a.id'     ],
    ],
    { WHERE       => 1,
    }
    );

  $self->query(
     "SELECT aa.id, aa.datetime, aa.actions, a.id, INET_NTOA(aa.ip) AS ip, aa.module,
      aa.action_type,
      aa.aid
   FROM admin_system_actions aa
      LEFT JOIN admins a ON (aa.aid=a.aid)
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM admin_system_actions aa
    LEFT JOIN admins a ON (aa.aid=a.aid)
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 password($password, $attr)

=cut
#**********************************************************
sub password {
  my $self = shift;
  my ($password, $attr) = @_;

  my $secretkey = (defined($attr->{secretkey})) ? $attr->{secretkey} : '';
  my $aid = $self->{AID};
  $self->query("UPDATE admins SET password=ENCODE('$password', '$secretkey') WHERE aid='$aid';", 'do');

  $self->system_action_add("AID:$self->{INSERT_ID} PASSWORD:****", { TYPE => 2 });

  return $self;
}

#**********************************************************
=head2 online($attr) - Online Administrators

  Arguments:
    $attr
      TIMEOUT
      ACTIVE

  Returns:
    $online_users, $online_count

=cut
#**********************************************************
sub online {
  my $self         = shift;
  my ($attr)       = @_;
  my $time_out     = $attr->{TIMEOUT} || 3000;
  my $online_users = '';
  my $curuser      = '';

  my $WHERE = ($self->{SID1}) ?  "WHERE sid='$self->{SID}'" : '';

  if($attr->{ACTIVE}) {
    $WHERE = " WHERE UNIX_TIMESTAMP() - logtime < 6000";
  }

  $self->query("DELETE FROM web_online WHERE UNIX_TIMESTAMP()-logtime>$time_out;", 'do');
  $self->query("SELECT admin, ip, UNIX_TIMESTAMP() - logtime, sid  FROM web_online $WHERE;");

  my $online_count = $self->{TOTAL} + 0;
  my $insert = 1;

  foreach my $row (@{ $self->{list} }) {
    $curuser = ($row->[3] eq $self->{SID}) ? '+' : '';
    $online_users .= "$row->[0] - $row->[1] ($row->[2]$curuser) ". (($self->{conf}->{WEB_DEBUG}) ? $row->[3] : '') ."\n";
    if ($row->[3] eq $self->{SID}) {
      $insert = 0;
    }
  }

  if ($insert) {
    $self->query("REPLACE INTO web_online (admin, ip, logtime, aid, sid) VALUES (?, ?, UNIX_TIMESTAMP(), ?, ?);",
    'do',
    { Bind => [
     $self->{A_LOGIN},
     $self->{SESSION_IP},
     $self->{AID},
     $self->{SID}
     ]} );

    $online_users .= "$self->{A_LOGIN} - $self->{SESSION_IP} (+) ". (($self->{conf}->{WEB_DEBUG}) ? $self->{SID} : '') ."\n";
    $online_count++;
  }
  else {
    $self->query("UPDATE web_online SET logtime=UNIX_TIMESTAMP() WHERE aid= ? AND sid = ? AND ip = ?",
     'do',
     { Bind => [ $self->{AID}, $self->{SID}, $self->{SESSION_IP} ] });
  }

  return ($online_users, $online_count);
}

#**********************************************************
=head2 online_info($attr) -  Online Administrators

=cut
#**********************************************************
sub online_info {
  my $self         = shift;
  my ($attr) = @_;

  $self->query("SELECT aid, ip, admin FROM web_online WHERE sid=?;",
   undef,
   { INFO => 1, Bind => [ $attr->{SID} ] });

  return $self;
}

#**********************************************************
=head2 online_list($attr) - list of online admin sessions

  Arguments:
    $attr - hash_ref - query params

  Returns:
    array_ref - hashes for admin sessions

=cut
#**********************************************************
sub online_list {
  my ($self, $attr) = @_;

  $self->query("SELECT aid, admin, ip, UNIX_TIMESTAMP() - logtime AS loggeed_time, sid  FROM web_online;", undef, {
      COLS_NAME => 1,
      %{ $attr // { } }
    });
  return ($self->{errno} || !$self->{list}) ? [ ] : $self->{list};
}


#**********************************************************
=head2 online_del($attr) - Delete session with sid

  Arguments:
    $attr - hash_ref
      SID

  Returns:
    $self

=cut
#**********************************************************
sub online_del {
  my $self         = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM web_online WHERE sid=?;", 'do', { Bind => [ $attr->{SID} ] });

  return $self;
}

##**********************************************************
#=head2 online_find($sid) - find session by $sid
#
#  Arguments:
#    $sid -
#
#  Returns:
#    aid
#
#=cut
##**********************************************************
#sub online_find {
#  my ($self, $sid) = @_;
#
#  return 0 unless ( $sid );
#
#  $self->query("SELECT aid FROM web_online WHERE sid= ?;", undef, {
#      Bind      => [ $sid ]
#    });
#
#  return ($self->{list} && $self->{list}->[0]) ? $self->{list}->[0][0] : 0;
#}

#**********************************************************
=head2 settings_info($id)

=cut
#**********************************************************
sub settings_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM admin_settings
    WHERE object=? AND aid=?;",
  undef,
  { INFO => 1, Bind => [ $id, $self->{AID} ] });

  return $self;
}

#**********************************************************
=head2 settings_add($attr)

=cut
#**********************************************************
sub settings_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('admin_settings', { %$attr, AID => $self->{AID} }, { REPLACE => 1 });

  return $self;
}

#**********************************************************
=head2 group_add($id)

=cut
#**********************************************************
sub settings_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('admin_settings', undef,
    { aid    => $self->{AID},
      object => $id });

  return $self;
}

#**********************************************************
=head2 access_list($attr)

=cut
#**********************************************************
sub access_list {
  my $self = shift;
  my ($attr) = @_;

  delete($self->{COL_NAMES_ARR});

  my $WHERE = $self->search_former($attr, [
      ['ID',      'INT', 'a.id',     ],
      ['AID',     'INT', 'a.aid'     ],
      ['IP',      'IP',  'a.ip'      ],
      ['DISABLE', 'INT', 'a.disable' ]
    ],
    { WHERE       => 1,
    }
  );

 $self->query("SELECT a.day, a.begin, a.end, INET_NTOA(a.ip) AS ip, a.bit_mask, a.disable, a.id
   FROM admins_access a
 $WHERE
 ORDER BY $SORT $DESC;", undef, $attr);

 return $self->{list};
}

#**********************************************************
=head2 access_add($attr)

=cut
#**********************************************************
sub access_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('admins_access', $attr);

  if ($self->{errno}) {
    return $self;
  }

  $self->system_action_add("ACCESS IP: $attr->{DAY}: $attr->{BEGIN}-$attr->{END} $attr->{IP}", { TYPE => 1 });
  return $self;
}


#**********************************************************
=head2 access_del($attr)

=cut
#**********************************************************
sub access_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('admins_access', $attr);

  $self->system_action_add("ALLOW IP: $attr->{ID}", { TYPE => 10 });
  return $self;
}

#**********************************************************
# access_info
#**********************************************************
sub access_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *,
     INET_NTOA(ip) AS ip
    FROM admins_access
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# access_change
#**********************************************************
sub access_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'admins_access',
      DATA         => $attr
    }
  );

  return $self;
}


#**********************************************************
=head2 full_log_list($attr)

=cut
#**********************************************************
sub full_log_list {
  my $self = shift;
  my ($attr) = @_;

  delete($self->{COL_NAMES_ARR});

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
      ['ID',      'INT', 'a.id',          ],
      ['DATETIME','DATE', 'a.datetime', 1 ],
      ['FUNCTION_NAME', 'STR', 'a.function_name', 1 ],
      ['PARAMS',  'STR', 'a.params',    1 ],
      ['IP',      'IP',  'a.ip', "INET_NTOA(a.ip) AS ip" ],
      ['SID',     'STR', 'a.sid',       1 ],
      ['FUNCTION_INDEX', 'STR', 'a.function_index', 1 ],
      ['AID',     'INT', 'a.aid'          ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(a.datetime, '%Y-%m-%d')" ],
    ],
    { WHERE => 1 }
  );

 $self->query("SELECT $self->{SEARCH_FIELDS} a.aid
   FROM admins_full_log a
 $WHERE
 ORDER BY $SORT $DESC
 LIMIT $PG, $PAGE_ROWS;", undef, $attr);

 my $list = $self->{list} || [];

 $self->query("SELECT COUNT(*) AS total
   FROM admins_full_log a
 $WHERE",
    undef,
    { INFO => 1 }
  );

 return $list;
}

#**********************************************************
=head2 full_log_add($attr)

=cut
#**********************************************************
sub full_log_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{PARAMS} =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  $attr->{PARAMS} =~ tr/+/ /;

  my @pairs = split(/&/, $attr->{PARAMS});
  $attr->{PARAMS} = join("\n", @pairs);

  $self->query_add('admins_full_log', $attr);

  return $self;
}


#**********************************************************
=head2 full_log_del($attr)

=cut
#**********************************************************
sub full_log_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('admins_full_log', $attr);

  return $self;
}

#**********************************************************
=head2 full_log_info($id)

=cut
#**********************************************************
sub full_log_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *,
     INET_NTOA(ip) AS ip
    FROM admins_full_log
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 full_log_analyze($aid, $datefrom, $dateto)

=cut
#**********************************************************
sub full_log_analyze {
  my $self = shift;
  my ($attr) = @_;

  delete($self->{COL_NAMES_ARR});

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP = 'GROUP BY a.function_name';
  my @fields = [
      ['FUNCTION_NAME', 'STR', 'a.function_name', 1],
      ['COUNT',         'INT', 'COUNT(*) as count', 1],
      ['AID',           'INT', 'a.aid'],
	  ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(a.datetime, '%Y-%m-%d')" ],
  ];

  if ($attr->{FUNCTION_NAME} ne "!msgs_admin") {
    push @{ $fields[0] }, ['PARAMS', 'STR', 'a.params', 1];
    $GROUP = 'GROUP BY a.params';
  };

  my $WHERE = $self->search_former($attr, @fields, { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} a.aid
   FROM admins_full_log a
  $WHERE
  $GROUP
  ORDER BY count DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef, $attr);

  my $list = $self->{list} || [];

#  $self->query("SELECT COUNT(*) AS total
#    FROM admins_full_log a
#    $WHERE",
#    undef,
#    { INFO => 1 }
#  );

 return $list;
}
#**********************************************************
=head2 full_log_change($attr)

=cut
#**********************************************************
sub full_log_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'admins_full_log',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 admins_contacts_list($attr)

=cut
#**********************************************************
sub admins_contacts_list {
  my $self = shift;
  my ($attr) = @_;

  $self->{errno} = 0;
  $self->{errstr} = '';

  return [] if (!$attr->{AID});

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $WHERE = '';

   $WHERE = $self->search_former($attr, [
      ['ID',        'INT',  'ac.id',          1],
      ['AID',       'INT',  'ac.aid',         1],
      ['TYPE',      'INT',  'ac.type_id',     1],
      ['VALUE',     'STR',  'ac.value',       1],
      ['PRIORITY',  'INT',  'ac.priority',    1],
      ['DEFAULT',   'INT',  'uct.is_default', 1],
      ['TYPE_NAME', 'STR',  'uct.name',       1],
      ['HIDDEN',    'INT',  'uct.hidden'       ]
    ],
    { WHERE       => 1 }
  );

  if ($attr->{SHOW_ALL_COLUMNS}){
    $self->{SEARCH_FIELDS} = '* , '
  }

 $self->query("SELECT $self->{SEARCH_FIELDS} ac.id
    FROM admins_contacts ac
   LEFT JOIN users_contact_types uct ON(ac.type_id=uct.id)
 $WHERE ORDER BY ac.priority;"
 ,undef, {COLS_NAME => 1,  %{ $attr // {} }});

 return $self->{list};
}

#**********************************************************
=head2 admins_contacts_info($id)

=cut
#**********************************************************
sub admins_contacts_info {
  my $self = shift;
  my ($aid) = @_;

  $self->query("SELECT ac.id,
  ac.aid,
  ac.type_id,
  ac.value,
  ac.priority
   FROM admins_contacts ac
   WHERE ac.aid= ?
   GROUP BY ac.id;",
    undef,
    { INFO => 1, Bind => [ $aid ] }
  );

  return $self;
}

#**********************************************************
=head1 admin_contacts_add() - Add contact  to admin

=cut
# #**********************************************************
sub admin_contacts_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('admins_contacts', $attr, { REPLACE => 1 });

  return 1;
}
#**********************************************************
=head2 admin_contacts_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub admin_contacts_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('admins_contacts', undef, $attr);

  return 1;
}

#**********************************************************
=head2 admins_groups_list($attr) - Admin type permits list

=cut
#**********************************************************
sub admin_type_permits_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former( $attr, [
      [ 'TYPE', 'STR', 'type', 1],
      [ 'SECTION', 'INT', 'section', 1 ],
      [ 'ACTIONS', 'INT', 'actions', 1 ],
      [ 'MODULE', 'STR', 'module', 1 ],
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT type, section, actions, module
    FROM admin_type_permits
    $WHERE;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 set_type_permits($permissions) - Set admin type permits

  Arguments:
    $permissions - hash of permits
    $permissions - name of template

=cut
#**********************************************************
sub set_type_permits {
  my $self = shift;
  my ($permissions, $type) = @_;

  $self->query("DELETE FROM admin_type_permits WHERE type= ? ;", 'do', { Bind => [ $type ] });
  my @MULTI_QUERY = ();

  while (my ($section, $actions_hash) = each %$permissions) {
    while (my ($action, undef) = each %$actions_hash) {
      my ($perms, $module) = split(/_/, $action);
      next if ($section ne  int($section));
      push @MULTI_QUERY, [ $type, $section, ($perms || 0), "$module" ];
    }
  }

  $self->query("INSERT INTO admin_type_permits (type, section, actions, module)
      VALUES (?, ?, ?, ?);",
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  if ($self->{errno}) {
    return $self;
  }

  return $self->{permissions};
}
#**********************************************************
=head2 del_type_permits($type) - del type(template)

  Arguments:
    $type - name of template

=cut
#**********************************************************
sub del_type_permits {
  my $self = shift;
  my ($type) = @_;
  $self->query("DELETE FROM admin_type_permits WHERE type= ? ;", 'do', { Bind => [ $type ] });

  return $self->{result};
}

1
