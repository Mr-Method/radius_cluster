package Voip;

=head1 NAME

 Voip  managment functions

=cut

=head1 SYNOPSIS

  use Voip;
  $Voip->new($db, $admin, \%conf);

=cut

use strict;
use parent qw(main);
use Tariffs;

my $tariffs;
my $MODULE = 'Voip';
my ($admin, $CONF);
my $SORT = 1;
my $DESC = '';
my $PG   = 1;
my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;

  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;

  my $self = {
    db   => $db,
    admin=> $admin,
    conf => $CONF
  };
  bless($self, $class);

  $tariffs = Tariffs->new($db, $CONF, $admin);

  return $self;
}

#**********************************************************
=head2 user_info($uid, $attr) -  User information

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my @WHERE_RULES = ();

  if (defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($self->{db}, $admin, $CONF);
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid = $users->{UID};
    $self->{DEPOSIT} = $users->{DEPOSIT};
    push @WHERE_RULES, "voip.uid='$uid'";
  }
  elsif ($uid > 0) {
    push @WHERE_RULES, "voip.uid='$uid'";
  }

  if (defined($attr->{NUMBER})) {
    push @WHERE_RULES, "voip.number='$attr->{NUMBER}'";
  }

  if (defined($attr->{IP})) {
    push @WHERE_RULES, "voip.ip=INET_ATON('$attr->{IP}')";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT 
   voip.uid, 
   voip.number,
   voip.tp_id, 
   tarif_plans.name as tp_name, 
   INET_NTOA(voip.ip) AS ip,
   voip.disable,
   voip.allow_answer,
   voip.allow_calls,
   voip.cid,
   voip.logins AS simultaneously,
   voip.registration,
   voip.filter_id,
   voip.expire AS voip_expire,
   tarif_plans.id as tp_num,
   voip.provision_nas_id,
   voip.provision_port,
   tarif_plans.month_fee AS month_abon,
   tarif_plans.day_fee AS day_abon,
   tarif_plans.credit AS tp_credit
     FROM voip_main voip
     LEFT JOIN voip_tps tp ON (voip.tp_id=tp.id)
     LEFT JOIN tarif_plans ON (tarif_plans.tp_id=voip.tp_id)
   $WHERE;",
  undef,
  { INFO => 1 } 
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP_ID            => 0,
    NUMBER           => 0,
    DISABLE          => 0,
    IP               => '0.0.0.0',
    CID              => '',
    PROVISION_NAS_ID => 0,
    PROVISION_PORT   => 0,
  );

  $self = \%DATA;
  return $self;
}


#**********************************************************
=head2 log_add($attr)

=cut
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('voip_ivr_log', { %$attr, 
  	                                 DATETIME => 'now()'
  	                                });

  return $self;
}


#**********************************************************
=head2 log_change($attr)

=cut
#**********************************************************
sub log_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'voip_ivr_log',
      DATA         => $attr,
      SKIP_LOG     => 1
    }
  );

  return $self;
}

#**********************************************************
=head2 log_list($attr)

=cut
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ID',           'INT',  'l.id'           ],
      ['DATETIME',     'DATE', 'l.datetime'     ],
      ['DURATION',     'INT',  'l.duration',  1 ],
      ['CALL_PHONE',   'STR',  'l.phone',  'l.phone AS call_phone'       ],
      ['CALL_COMMENT', 'STR',  'l.comment',  'l.comment AS call_comment' ],
      ['STATUS',       'INT',  'l.status',    1 ],
      ['IP',           'IP',   'l.ip',    "INET_NTOA(ip) AS ip" ],
      ['UID',          'INT',  'l.uid'          ]
    ],
    { WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1
    }
    );
  my $EXT_TABLES = ($self->{EXT_TABLES}) ? $self->{EXT_TABLES} : '';

  $self->query2("SELECT l.id, l.datetime, $self->{SEARCH_FIELDS} l.uid
    FROM voip_ivr_log l
    LEFT JOIN users u ON (u.uid=l.uid)
    $EXT_TABLES
    $WHERE
    GROUP BY l.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(l.id) AS total FROM voip_ivr_log l
    LEFT JOIN users u ON (u.uid=l.uid)
     $WHERE",
    undef, { INFO => 1 });
  }

  return $list;
}


#**********************************************************
=head2 user_add($attr) - Add voip service

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{CID} = lc("$attr->{CID}");
  $self->query_add('voip_main', $attr);

  $self->{TP_INFO} = $tariffs->info($attr->{TP_ID});
  return [ ] if ($self->{errno});

  $admin->action_add($attr->{UID}, "ADDED", { TYPE => 1 });

  return $self;
}

#**********************************************************
# user_change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{TP_ID}) {
    $attr->{ALLOW_ANSWER} = ($attr->{ALLOW_ANSWER}) ? 1 : 0;
    $attr->{ALLOW_CALLS}  = ($attr->{ALLOW_CALLS})  ? 1 : 0;
  }
  else {
    $self->{TP_INFO} = $tariffs->info($attr->{TP_ID});
  }

  $attr->{EXPIRE}= $attr->{VOIP_EXPIRE};
  $attr->{LOGINS}= $attr->{SIMULTANEOUSLY};

  $self->changes2(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'voip_main',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub user_del {
  my $self = shift;

  $self->query2("DELETE from voip_main WHERE uid='$self->{UID}';", 'do');
  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });

  return $self->{result};
}

#**********************************************************
=head2 user_list($attr) - Voip users list

=cut
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ( "u.uid = service.uid" );
  my $EXT_TABLES = '';
  $self->{EXT_TABLES}='';

  if ($attr->{USERS_WARNINGS}) {
    $self->query2(" SELECT u.id, pi.email, dv.tp_id, u.credit, b.deposit, tp.name, tp.uplimit
         FROM (users u, voip_main dv, bills b)
         LEFT JOIN tarif_plans tp ON dv.tp_id = tp.id
         LEFT JOIN users_pi pi ON u.uid = dv.uid
         WHERE u.bill_id=b.id
           and b.deposit<tp.uplimit AND tp.uplimit > 0 AND b.deposit+u.credit>0
         ORDER BY u.id;"
    );

    my $list = $self->{list};
    return $list;
  }
  elsif ($attr->{CLOSED}) {
    $self->query2("SELECT u.id AS login, pi.fio, if(company.id IS NULL, b.deposit, b.deposit), 
      u.credit, tp.name, u.disable, 
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM (users u, bills b)
     LEFT JOIN users_pi pi ON u.uid = dv.uid
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN voip_log l ON  (l.uid=u.uid) 
     WHERE
        u.bill_id=b.id
        and (b.deposit+u.credit-tp.credit_tresshold<=0)
        or (
        (u.expire<>'0000-00-00' and u.expire < CURDATE())
        AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
        )
        or u.disable=1
     GROUP BY u.uid
     ORDER BY $SORT $DESC;"
    );

    my $list = $self->{list};
    return $list;
  }


  if ($attr->{TP_FREE_TIME}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{CID}, 'INT', 'tp.free_time AS tp_free_time', { EXT_FIELD => 1 }) };
    $EXT_TABLES .= "LEFT JOIN voip_tps voip_tp ON (voip_tp.id=tp.tp_id) ";
  }
  if ($attr->{ONLINE}) {
  	push @WHERE_RULES, "service.location!=''";
  }

  my $WHERE =  $self->search_former($attr, [
      ['NUMBER',         'INT', 'service.number',                   1 ],
      ['TP_NAME',        'STR', 'tp.name AS tp_name',               1 ],
      ['IP',             'IP',  'service.ip',                 'INET_NTOA(service.ip) AS ip' ],
      ['CID',            'STR', 'service.cid',                      1 ],
      ['SERVICE_STATUS', 'INT', 'service.disable AS voip_status',   1 ],
      ['SIMULTANEONSLY', 'INT', 'service.logins',                   1 ],
      ['FILTER_ID',      'STR', 'service.filter_id',                1 ],
      ['TP_ID',          'INT', 'service.tp_id',                    1 ],
      ['TP_CREDIT',      'INT', 'tp.credit',                       'tp.credit AS tp_credit' ],
      ['VOIP_EXPIRE',    'DATE','service.expire AS voip_expire',    1 ],
      ['PROVISION_PORT', 'INT', 'service.provision_port',           1 ],
      ['PROVISION_NAS_ID','INT','service.provision_nas_id',         1 ],
      ['LOCATIONS',       'STR','service.location',                 1 ],
      ['EXPIRES',         'DATE','service.expires',                 1 ],
    ],
    { WHERE            => 1,
    	WHERE_RULES      => \@WHERE_RULES,
    	USERS_FIELDS_PRE => 1,
    	USE_USER_PI      => 1
    }
    );

  $EXT_TABLES = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  my $sql = "SELECT $self->{SEARCH_FIELDS}
      u.uid, 
      service.tp_id
     FROM (users u, voip_main service)
     LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id) 
     $EXT_TABLES
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;";

  $self->query2($sql,
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(u.id) AS total FROM (users u, voip_main service)
    $EXT_TABLES
     $WHERE",
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# Periodic
#**********************************************************
sub periodic {
  my $self = shift;
  #my ($period) = @_;
  #if ($period eq 'daily') {
  #  $self->daily_fees();
  #}

  return $self;
}

#**********************************************************
=head2 route_add($attr) - Add voip route

  Arguments:
    $attr
      REPLACE  - Chnage insert statment to replace

  Returns:
    $self

=cut
#**********************************************************
sub route_add {
  my $self = shift;
  my ($attr) = @_;

  my $action = 'INSERT';
  if ($attr->{REPLACE}) {
    $action = 'REPLACE';
  }

  $self->query2("$action INTO voip_routes (prefix, parent, name, disable, date,
        descr) 
        VALUES (?, ?, ?, ?, now(), ?);", 'do',
    { Bind => 
       [ $attr->{ROUTE_PREFIX} || '', 
         $attr->{PARENT_ID} || 0,
         $attr->{ROUTE_NAME} || '',
         $attr->{DISABLE} || 0,
         $attr->{DESCRIBE} || ''
       ] 
    }
  );

  return [ ] if ($self->{errno});

  $admin->system_action_add("ROUTES: $attr->{ROUTE_PREFIX}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 route_info($id, $attr) - Route information

=cut
#**********************************************************
sub route_info {
  my $self = shift;
  my ($id) = @_;

  $self->query2("SELECT 
   id AS route_id,
   prefix AS route_prefix,
   parent AS parent_id,
   name AS route_name,
   date,
   disable,
   descr AS `describe`
     FROM voip_routes
   WHERE id= ? ;",
   undef,
   { INFO => 1,
     Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 route_del($id, $attr) - Delete route

=cut
#**********************************************************
sub route_del {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = '';

  if ($id > 0) {
    $WHERE = "id='$id'";
    $self->query_del('voip_route_prices', { ID => $id });
  }
  elsif ($attr->{ALL}) {
    $WHERE = "id > '0'";
    $id    = 'ALL';
  }

  $self->query2("DELETE FROM voip_routes WHERE $WHERE;", 'do');
  return [ ] if ($self->{errno});

  $admin->system_action_add("ROUTES: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 route_change($attr) - Route change

=cut
#**********************************************************
sub route_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ROUTE_ID     => 'id',
    PARENT_ID    => 'parent',
    DISABLE      => 'disable',
    ROUTE_PREFIX => 'prefix',
    ROUTE_NAME   => 'name',
    DESCRIBE     => 'descr',
  );

  $attr->{DISABLE}=(! defined($attr->{DISABLE})) ? 0 : 1;

  $self->changes2(
    {
      CHANGE_PARAM => 'ROUTE_ID',
      TABLE        => 'voip_routes',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->route_info($attr->{ROUTE_ID}),
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# route_list()
#**********************************************************
sub routes_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ROUTE_NAME',     'STR', 'r.name',     ],
      ['DESCRIBE',       'STR', 'r.descr',    ],
      ['ROUTE_PREFIX',   'STR', 'r.prefix'    ],
    ],
    { WHERE => 1,
    }
    );

  $self->query2("SELECT r.prefix, r.name, r.disable, r.date, r.id, r.parent
     FROM voip_routes r
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(r.id) AS total FROM voip_routes r $WHERE",
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 rp_list($attr)

=cut
#**********************************************************
sub rp_add {
  my $self = shift;
  my ($attr) = @_;

  my $value = '';
  while (my ($k, $v) = each %$attr) {
    if ($k =~ /^p_/) {
      my (undef, $route, $interval) = split(/_/, $k, 3);

      my $trunk       = $attr->{ "t_" . $route . "_" . $interval }  || 0;
      my $extra_tarif = $attr->{ "et_" . $route . "_" . $interval } || 0;
      my $unit_price  = 0;
      if ($CONF->{VOIP_UNIT_TARIFICATION}) {
        $unit_price = $v;
        $v = $v * $attr->{EXCHANGE_RATE} if ($attr->{EXCHANGE_RATE} && $attr->{EXCHANGE_RATE} > 0);
      }
      $value .= "('$route', '$interval', '$v', now(), '$trunk', '$extra_tarif', '$unit_price'),";
    }
  }

  chop($value);

  $self->query2("REPLACE INTO voip_route_prices (route_id, interval_id, price, date, trunk, extra_tarification, unit_price) VALUES
  $value;", 'do'
  );
  return [ ] if ($self->{errno});

  return $self;
}

#**********************************************************
# route price change exchange rate
# rp_change_exhange_rate()
#**********************************************************
sub rp_change_exhange_rate {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{EXCHANGE_RATE} > 0) {
    $self->query2("UPDATE voip_route_prices SET price = unit_price * $attr->{EXCHANGE_RATE};", 'do');
    return [ ] if ($self->{errno});
  }

  return $self;
}

#**********************************************************
=head2 rp_list($attr) - route price list

=cut
#**********************************************************
sub rp_list {
  my $self   = shift;
  my ($attr) = @_;

  my @WHERE_RULES   = ();

  if ($attr->{PRICE}) {
    my $value = $self->search_expr($attr->{PRICE}, 'INT');
    push @WHERE_RULES, "rp.price$value";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT rp.interval_id, rp.route_id, rp.date, rp.price, rp.trunk, rp.extra_tarification, rp.unit_price
     FROM voip_route_prices rp 
     $WHERE 
     ORDER BY $SORT $DESC;"
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(route_id) AS total FROM voip_route_prices rp $WHERE", 
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# list
#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ('tp.tp_id=voip.id');
  $SORT = (defined($attr->{SORT})) ? $attr->{SORT} : 1;
  $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
      ['FREE_TIME',     'INT', 'voip.free_time',    1 ],
      ['TIME_DIVISION', 'STR', 'voip.time_division',1 ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT tp.id, tp.name, 
    if(sum(i.tarif) is NULL or sum(i.tarif)=0, 0, 1) AS time_tarifs, 
    tp.payment_type,
    tp.day_fee, 
    tp.month_fee, 
    tp.logins, 
    tp.age,
    tp.tp_id,
    $self->{SEARCH_FIELDS}
    ''

    FROM (tarif_plans tp, voip_tps voip)
    LEFT JOIN intervals i ON (i.tp_id=tp.tp_id)
    $WHERE
    GROUP BY tp.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# Default values
#**********************************************************
sub tp_defaults {
  my $self = shift;

  my %DATA = (
    TP_ID                => 0,
    NAME                 => '',
    TIME_TARIF           => '0.00000',
    DAY_FEE              => '0,00',
    MONTH_FEE            => '0.00',
    SIMULTANEOUSLY       => 0,
    AGE                  => 0,
    DAY_TIME_LIMIT       => 0,
    WEEK_TIME_LIMIT      => 0,
    MONTH_TIME_LIMIT     => 0,
    ACTIV_PRICE          => '0.00',
    CHANGE_PRICE         => '0.00',
    CREDIT_TRESSHOLD     => '0.00',
    ALERT                => 0,
    MAX_SESSION_DURATION => 0,
    PAYMENT_TYPE         => 0,
    MIN_SESSION_COST     => '0.00000',
    RAD_PAIRS            => '',
    FIRST_PERIOD         => 0,
    FIRST_PERIOD_STEP    => 0,
    NEXT_PERIOD          => 0,
    NEXT_PERIOD_STEP     => 0,
    FREE_TIME            => 0
  );

  $self->{DATA} = \%DATA;

  return \%DATA;
}

#**********************************************************
=head2 tp_add($attr)

=cut
#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{MODULE} = 'Voip';
#  $tariffs->{debug}=1;
  $tariffs->add($attr);

  $tariffs->{TP_ID} = $tariffs->{INSERT_ID};
  $self->{TP_ID}=$tariffs->{INSERT_ID};

  if ($tariffs->{errno}) {
    $self->{errno} = $tariffs->{errno};
    return $self;
  }

  $self->query_add('voip_tps', {
    %$attr,
    ID => $tariffs->{TP_ID},
  });

  return $self;
}

#**********************************************************
=head2 tp_change($tp_id, $attr) - Tarif plans change

=cut
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($tp_id, $attr) = @_;

  #$attr->{MODULE}='Voip';
  $tariffs->change($tp_id, { %$attr, MODULE => 'Voip' });
  if (defined($tariffs->{errno})) {
    $self->{errno} = $tariffs->{errno};
    return $self;
  }

  my %FIELDS = (
    TP_ID                => 'id',
    DAY_TIME_LIMIT       => 'day_time_limit',
    WEEK_TIME_LIMIT      => 'week_time_limit',
    MONTH_TIME_LIMIT     => 'month_time_limit',
    MAX_SESSION_DURATION => 'max_session_duration',
    MIN_SESSION_COST     => 'min_session_cost',
    RAD_PAIRS            => 'rad_pairs',
    FIRST_PERIOD         => 'first_period',
    FIRST_PERIOD_STEP    => 'first_period_step',
    NEXT_PERIOD          => 'next_period',
    NEXT_PERIOD_STEP     => 'next_period_step',
    FREE_TIME            => 'free_time',
    TIME_DIVISION        => 'time_division',
  );

  $self->changes2(
    {
      CHANGE_PARAM => 'TP_ID',
      TABLE        => 'voip_tps',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->tp_info($tp_id, $attr),
      DATA         => $attr
    }
  );

  $self->tp_info($tp_id);

  return $self;
}

#**********************************************************
=head2 tp_del($id) - Tarif plans delete

=cut
#**********************************************************
sub tp_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('voip_tps', { ID => $id });

  $tariffs->del($id);

  return $self;
}

#**********************************************************
=head2 tp_info($id, $attr)

=cut
#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self = $tariffs->info($attr->{TP_ID});

  if ($attr->{CHG_TP_ID}) {
    $self = $tariffs->info($attr->{CHG_TP_ID});
  }
  else {
    $self = $tariffs->info($id);
  }

  if (defined($self->{errno})) {
    return $self;
  }

  $self->query2("SELECT 
      voip.*,
     tp.id 
    FROM (voip_tps voip, tarif_plans tp)
    WHERE 
    voip.id=tp.tp_id AND
    voip.id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] 
    }
  );

  return $self;
}

#**********************************************************
=head2 route_add($attr) - trunk add

=cut
#**********************************************************
sub trunk_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('voip_trunks', $attr);

  return [ ] if ($self->{errno});

  #  $admin->action_add($attr->{UID}, "ADDED", { MODULE => 'voip'});
  return $self;
}

#**********************************************************
=head2 trunk_info($id, $attr) - Trunk information

=cut
#**********************************************************
sub trunk_info {
  my $self = shift;
  my ($id) = @_;

  $self->query2("SELECT * FROM voip_trunks
   WHERE id= ? ;",
  undef,
  { INFO => 1,
    Bind => [ $id ]
  }
  );

  return $self;
}

#**********************************************************
=head2 trunk_del($id) - Trunk del

=cut
#**********************************************************
sub trunk_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('voip_trunks', { ID => $id });

  return $self;
}

#**********************************************************
=head2 trunk_change($attr) - Trunk change

=cut
#**********************************************************
sub trunk_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'voip_trunks',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 trunk_list() - Trunk list

=cut
#**********************************************************
sub trunk_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ID',        'STR', 'id',             1 ],
      ['NAME',      'STR', 'name',           1 ],
      ['PROTOCOL',  'STR', 'protocol',       1 ],
      ['PROVNAME',  'STR', 'provider_name',  1 ],
      ['FAILTRUNK', 'STR', 'failover_trunk', 1 ],
      ['STATUS',    'STR', 'status as state',1 ],
    ],
    { WHERE => 1,
    }
  );

  $self->query2("SELECT $self->{SEARCH_FIELDS} id
  	FROM voip_trunks
  	$WHERE
  	ORDER BY $SORT $DESC
  	LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list} || [];

  if ($self->{TOTAL}) {
    $self->query2("SELECT COUNT(id) AS total FROM voip_trunks $WHERE",
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 extra_tarification_info($attr) - Extra tarification

=cut
#**********************************************************
sub extra_tarification_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT id, name, prepaid_time
     FROM voip_route_extra_tarification
  WHERE id='$attr->{ID}';",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# extra_tarification_add()
#**********************************************************
sub extra_tarification_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('voip_route_extra_tarification', { %$attr, DATE => 'now()' });

  return $self;
}

#**********************************************************
# extra_tarification_change()
#**********************************************************
sub extra_tarification_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'voip_route_extra_tarification',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
#
# extra_tarification_del(attr);
#**********************************************************
sub extra_tarification_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('voip_route_extra_tarification', $attr);

  return $self->{result};
}

#**********************************************************
=head2 extra_tarification_list($attr)

=cut
#**********************************************************
sub extra_tarification_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ID',   'INT', 'et.id',    1 ],
      ['NAME', 'STR', 'et.name',  1 ],
    ],
    { WHERE => 1 }
    );

  $self->query2("SELECT id, name, prepaid_time
     FROM voip_route_extra_tarification
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});
  my $list = $self->{list} || [];

  if ($self->{TOTAL}) {
    $self->query2("SELECT COUNT(id) AS total FROM voip_route_extra_tarification $WHERE",
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 ivr_menu_info($attr)

=cut
#**********************************************************
sub ivr_menu_info {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query2("SELECT * FROM voip_ivr_menu WHERE id= ? ", 
   $attr,
   { INFO => 1,
     Bind => [ $attr->{ID} ] 
    });

  return $self;
}

#**********************************************************
=head2 ivr_menu_add($attr)

=cut
#**********************************************************
sub ivr_menu_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('voip_ivr_menu', $attr);

  return $self;
}

#**********************************************************
=head2 ivr_menu_change($attr)

=cut
#**********************************************************
sub ivr_menu_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DISABLE}=0 if(! $attr->{DISABLE});

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'voip_ivr_menu',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 ivr_menu_del($attr)

=cut
#**********************************************************
sub ivr_menu_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('voip_ivr_menu', $attr);

  return $self->{result};
}

#**********************************************************
=head2 ivr_menu_list($attr) - IVR menu list item

=cut
#**********************************************************
sub ivr_menu_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['MAIN_ID',    'INT', 'main_id',        1 ],
      ['NUMBER',     'INT', 'number',         1 ],
      ['NAME',       'STR', 'name',           1 ],
      ['DISABLE',    'INT', 'disable',        1 ],
      ['COMMENTS',   'STR', 'comments',       1 ],
      ['FUNCTION',   'STR', 'function',       1 ],
      ['AUDIO_FILE', 'STR', 'audio_file',     1 ],
      ['ID',         'INT', 'id',               ],
    ],
    { WHERE            => 1,
    }
  );

  $self->query2("SELECT $self->{SEARCH_FIELDS} id
     FROM voip_ivr_menu
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(id) AS total FROM voip_ivr_menu
     $WHERE",
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 voip_yate_cdr($attr) - Yate CDR

=cut
#**********************************************************
sub voip_yate_cdr {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  if ($attr->{NOW}) {
  	push @WHERE_RULES, "ended!=1";
  }
  my $WHERE =  $self->search_former($attr, [
      ['DATETIME',   'DATA', 'datetime',       1 ],
      ['CALLER',     'STR', 'caller',          1 ],
      ['CALLED',     'STR', 'called',          1 ],
      ['BILLTIME',   'STR', 'billtime',        1 ],
      ['RINGTIME',   'STR', 'ringtime',        1 ],
      ['DURATION',   'STR', 'duration',        1 ],
      ['DIRECTION',  'STR', 'direction',       1 ],
      ['STATUS',     'STR', 'status as state', 1 ],
      ['REASON',     'STR', 'reason',          1 ],
      ['ID',         'INT', 'id',                ],
    ],
    { 
    	WHERE            => 1,
    	WHERE_RULES      => \@WHERE_RULES,
    }
  );

  $self->query2("SELECT $self->{SEARCH_FIELDS} id
     FROM voip_cdr
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(id) AS total FROM voip_cdr
     $WHERE",
    undef, { INFO => 1 });
  }

  return $list;
}

1
