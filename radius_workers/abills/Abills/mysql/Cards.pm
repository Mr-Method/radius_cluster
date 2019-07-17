package Cards;

=head1 NAME

  Cards system

=head1 VERSION

  VERSION: 7.35;
  REVISION: 20160811

=cut

use strict;
use parent 'main';
use Tariffs;
use Users;
use Fees;

our $VERSION = 7.35;
my $uid;
my $MODULE        = 'Cards';
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
  my $self = {};

  bless($self, $class);
  $self->{db}   =$db;
  $self->{admin}=$admin;
  $self->{conf} =$CONF;

  if ($CONF->{DELETE_USER}) {
    $self->{UID} = $CONF->{DELETE_USER};
    $self->cards_diller_del({ UID => $CONF->{DELETE_USER} });
  }

  $self->{CARDS_NUMBER_LENGTH} = (!$CONF->{CARDS_NUMBER_LENGTH}) ? 0 : $CONF->{CARDS_NUMBER_LENGTH};

  return $self;
}

#**********************************************************
=head2 cards_service_info($attr) - Cards service information

=cut
#**********************************************************
sub cards_service_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if ($admin->{DOMAIN_ID}) {
    $WHERE = "AND tp.domain_id='$admin->{DOMAIN_ID}'";
  }

  $self->query2("SELECT u.id AS login,
    DECODE(u.password, '$CONF->{secretkey}') AS password,
    tp.name AS tp_name,
    tp.age,
    tp.total_time_limit AS time_limit,
    tp.total_traf_limit AS traf_limit
    FROM users u
    INNER JOIN dv_main dv ON (dv.uid=u.uid)
    INNER JOIN tarif_plans tp ON (dv.tp_id=tp.id $WHERE)
    WHERE
      u.deleted=0 AND u.uid= ? ",
    undef,
    { INFO => 1,
      Bind => [ $attr->{UID} || 0 ]
    }
  );

  return $self;
}

#**********************************************************
=head2 cards_info() - Cards information

=cut
#**********************************************************
sub cards_info {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, "c.domain_id='$admin->{DOMAIN_ID}'";
  }

  my $WHERE = $self->search_former($attr, [
      ['ID',           'INT',  'c.id'             ],
      ['PIN',          'STR',  "DECODE(c.pin, '$CONF->{secretkey}')" ],
      ['SERIAL',       'STR',  "CONCAT(c.serial, if($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number))",  ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT
      c.serial,
      if($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number) AS number,
      c.sum,

      IF(c.status = 1 or c.status = 2 or c.status = 4  or c.status = 5, c.status,
              IF(c.uid > 0 && u.activate <> '0000-00-00', 2,
                IF(c.uid > 0 && u.activate IS NULL, 3, 0)
                 )
        ) AS status,
      c.datetime,
      c.expire,
      c.pin,
      if (c.expire<CURDATE() && c.expire != '0000-00-00', 1, 0) AS expire_status,
      c.uid,
      c.diller_id,
      c.id,
      c.commission
    FROM cards_users c
    LEFT JOIN users u ON (c.uid = u.uid)
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
    'SERIAL'         => '',
    'BEGIN'          => 0,
    'COUNT'          => 0,
    'LOGIN_BEGIN'    => 0,
    'LOGIN_COUNT'    => 0,
    'PASSWD_SYMBOLS' => '1234567890',
    'PASSWD_LENGTH'  => 8,
    'SUM'            => '0.00',
    'LOGIN_LENGTH'   => 5,
    'EXPIRE'         => '0000-00-00',
    DILLER_ID        => 0,
    UID              => 0,
    DOMAIN_ID        => 0,
    ID               => 0,
    COMMISSION       => '0.00'
  );

  while (my ($k, $v) = each %DATA) {
    $self->{$k} = $v;
  }

  return $self;
}

#**********************************************************
=head2 cards_add($attr)

=cut
#**********************************************************
sub cards_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{MULTI_ADD}) {
    $self->query2("INSERT INTO cards_users (
       serial, number, login, pin, status, expire,aid,
       diller_id, diller_date, sum, uid, domain_id, created, commission)
     VALUES (?,?,?,ENCODE(?, '$CONF->{secretkey}'),?,?,?,?,if (? > 0, now(), '0000-00-00'),
       ?,?,?,now(),?);",
     undef,
     { MULTI_QUERY =>  $attr->{MULTI_ADD} }
    );
  }
  else {
    $self->query2("INSERT INTO cards_users (
       serial, number, login, pin, status, expire,aid,
       diller_id, diller_date, sum, uid, domain_id, created, commission)
     VALUES (?,?,?,ENCODE(?, ?),?,?,?,?,if (? > 0, now(), '0000-00-00'),
       ?,?,?,now(),?);",
     'do',
     { Bind => [
        $attr->{SERIAL} || '',
        $attr->{NUMBER} || 0,
        $attr->{LOGIN} || '',
        $attr->{PIN} || '',
        $CONF->{secretkey},
        $attr->{STATUS} || 0,
        $attr->{EXPIRE} || '0000-00-00',
        $admin->{AID},
        $attr->{DILLER_ID} || 0,
        $attr->{DILLER_ID} || 0,
        $attr->{SUM} || 0,
        $attr->{UID} || 0,
        $admin->{DOMAIN_ID},
        $attr->{COMMISSION} || 0
       ]
     });
  }

  #$admin->action_add($uid, "DELETE $self->{SERIAL}");

  $self->{CARD_ID}     = $self->{INSERT_ID};
  $self->{CARD_NUMBER} = $self->{NUMBER};

  return $self;
}

#**********************************************************
=head2 cards_change()

=cut
#**********************************************************
sub cards_change {
  my $self = shift;
  my ($attr) = @_;

  my %IDS_HASH    = ();
  my $WHERE       = '';
  my $action_info = '';

  if ($attr->{IDS}) {
    if ($attr->{IDS} =~ /:/) {
      my @IDS = split(/, /, $attr->{IDS});

      foreach my $line (@IDS) {
        my ($k, $v) = split(/:/, $line, 2);
        push @{ $IDS_HASH{$k} }, $v;
      }

      my @where_arr = ();
      while (my ($k, $v) = each %IDS_HASH) {
        my $ids = "'" . join('\', \'', @$v) . "'";
        push @where_arr, "(serial='$k' and number in ($ids))";
        $ids =~ s/\'//g;
        $action_info .= "$k $ids;";
      }

      $WHERE = join(' AND ', @where_arr);
    }
    else {
      $WHERE = " id in ($attr->{IDS}) ";
    }
  }

  if ($attr->{SERIAL} && $attr->{NUMBER} && $attr->{STATUS}) {
    my $status_date = ($attr->{STATUS} == 2) ? ", datetime=now()" : '';

    $self->query2("UPDATE cards_users SET
      status=? $status_date
       WHERE serial=? and number= ? ; ", 'do',
      { Bind => [
          $attr->{STATUS} || 0,
          $attr->{SERIAL} || '',
          $attr->{NUMBER} || 0
        ]
      }
    );

    $admin->action_add($attr->{UID}, "USE $attr->{IDS}");
    return $self;
  }
  elsif ($attr->{IDS} && $attr->{SOLD}) {
    $self->query2("UPDATE cards_users SET
        diller_sold_date=now(),
        aid='$admin->{AID}'
       WHERE diller_id='$attr->{DILLER_ID}' AND $WHERE; ", 'do'
    );

    $admin->action_add($attr->{UID}, "SOLD $action_info");

    return $self;
  }
  elsif ($attr->{IDS} && (defined($attr->{STATUS}) && $attr->{STATUS} ne '')) {
    # Sattus 3 return cards USER ID
    if ($attr->{STATUS} == 3) {
      $self->{CARDS_INFO} = $self->cards_list(
        {
          %$attr,
          STATUS    => undef,
          PAGE_ROWS => 100000,
          DOMAIN_ID => $admin->{DOMAIN_ID}
        }
      );

      $self->query2("DELETE FROM cards_users
          WHERE domain_id='$admin->{DOMAIN_ID}' AND $WHERE; ", 'do'
      );
      $admin->action_add(0, "DELETE $action_info");
      return $self;
    }

    my $dillers = '';

    if ($attr->{DILLER_ID}) {
      $dillers = "diller_id='$attr->{DILLER_ID}',
                  diller_date=now(),";
    }

    my $status_date = ($attr->{STATUS} == 2) ? "datetime=now()," : '';
    $self->query2("UPDATE cards_users SET
        status='$attr->{STATUS}',
        $status_date
        aid='$admin->{AID}'
       WHERE domain_id='$admin->{DOMAIN_ID}' AND $WHERE; ", 'do'
    );

    $admin->action_add(0, "STATUS $attr->{STATUS} $action_info");

    return $self;
  }
  elsif ($attr->{IDS} && defined($attr->{DILLER_ID})) {
    $self->query2("UPDATE cards_users SET
      diller_id='$attr->{DILLER_ID}',
      diller_date=now(),
      aid='$admin->{AID}'
      WHERE domain_id='$admin->{DOMAIN_ID}' AND $WHERE; ", 'do'
    );

    $admin->action_add(0, "DILLER ADD $attr->{DILLER_ID} $action_info");

    return $self;
  }

  if (!$attr->{ID}) {
    $self->{error}  = 2;
    $self->{errno}  = 2;
    return $self;
  }

  my %FIELDS = (
    SERIAL => 'serial',
    NUMBER => 'number',

    #                 PIN       => 'pin',
    SUM              => 'sum',
    STATUS           => 'status',
    DATETIME         => 'datetime',
    DILLER_ID        => 'diller_id',
    DILLER_SOLD_DATE => 'diller_sold_date',
    ID               => 'id'
    #DOMAIN_ID => 'domain_id'
  );

  my $old_info = $self->cards_info({ ID => $attr->{ID} });
  $attr->{PIN}     = $old_info->{PIN};
  $admin->{MODULE} = $MODULE;

  $self->changes2(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'cards_users',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $old_info,
      DATA            => $attr,
      EXT_CHANGE_INFO => (($attr->{STATUS} == 2) ? $self->{ID} : "ID:$self->{ID} $attr->{SERIAL}$attr->{NUMBER}"),
      ACTION_ID       => (($attr->{STATUS} == 2) ? 31 : undef)
    }
  );

  if(! $self->{AFFECTED}) {
    $self->{error}  = 11;
    $self->{errno}  = 11;
    $self->{errstr} = 'ERROR_NOT_CHANGED';
  }

  return $self;
}

#**********************************************************
=head cards_del($attr) - Delete user info from all tables

=cut
#**********************************************************
sub cards_del {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ("domain_id='$admin->{DOMAIN_ID}'");

  my $WHERE = '';
  if ($attr->{ID}) {
    push @WHERE_RULES, " id='$attr->{ID}' ";
  }
  elsif (defined($attr->{SERIA})) {
    push @WHERE_RULES, "serial='$attr->{SERIA}'";
  }

  if ($attr->{IDS}) {
    push @WHERE_RULES, " id IN ($attr->{IDS}) ";
  }
  elsif ($attr->{NUMBER}) {
    push @WHERE_RULES, " number='$attr->{NUMBER}' ";
  }

  if (defined($attr->{DILLER_ID})) {
    push @WHERE_RULES, "diller_id='$attr->{DILLER_ID}'";
  }

  if ($#WHERE_RULES > -1) {
    $WHERE = join(' AND ', @WHERE_RULES);
    $self->query2("DELETE from cards_users WHERE $WHERE;", 'do');
  }

  $admin->action_add($uid, "DELETE $attr->{SERIA}/$attr->{NUMBER}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 cards_list($attr) - List of cards


=cut
#**********************************************************
sub cards_list {
  my $self   = shift;
  my ($attr) = @_;

  delete($self->{COL_NAMES_ARR});

  my $GROUP = "cu.serial";
  my $GROUP_BY = (defined($attr->{SERIAL}) && $attr->{SERIAL} ne '_SHOW') ? '' : "GROUP BY $GROUP";

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}           : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}           : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}             : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? int($attr->{PAGE_ROWS}) : 25;

  my @WHERE_RULES = ();

  if ($admin->{DOMAIN_ID} == 0) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DOMAIN_ID}", 'INT', 'cu.domain_id') } if ($attr->{DOMAIN_ID});
  }
  else {
    push @WHERE_RULES, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'cu.domain_id') };
  }

  if ($attr->{PAYMENTS}) {
    push @WHERE_RULES, @{ $self->search_expr(0, 'INT', 'cu.uid') };
  }

  if (defined($attr->{SERIAL}) && $attr->{SERIAL} ne '_SHOW') {
    if ($attr->{SERIAL} eq 'empty') {
      $attr->{SERIAL} = '';
    }
    push @WHERE_RULES, @{ $self->search_expr($attr->{SERIAL}, 'STR', 'cu.serial') };
    $GROUP_BY='';
  }

  my $WHERE = $self->search_former($attr, [
    #['SERIAL',           'STR',  'cu.serial',    1],
    ['NUMBER',           'INT',  'cu.number',    "IF($self->{CARDS_NUMBER_LENGTH}>0, MID(cu.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), cu.number) AS number"],
    ['CARDS_COUNT',      '',     '', 'COUNT(*) AS cards_count' ],
    ['CARDS_SUM',        '',     '', 'SUM(sum) AS cards_sum'  ],
    ['CARDS_ACTIVE',     '',     '', "SUM(IF(cu.status=0 && cu.uid=0, 1,
                                IF (cu.uid>0 && u.activate='0000-00-00', 1, 0))) AS cards_active" ],
    ['CARDS_DILLERS',    '',     '', 'SUM(IF (cu.diller_id>0, 1, 0)) AS cards_dillers' ],
    ['SUM',              'INT',  'cu.sum',         1],
    ['LOGIN',            'STR',  'u.id AS login',  1],
    ['EXPIRE',           'DATE', 'cu.expire',      1],
    #['CREATED',          'DATE', "DATE_FORMAT(cu.created, '%Y-%m-%d')",  "DATE_FORMAT(cu.created, '%Y-%m-%d') AS created" ],
    ['CREATED',          'DATE', "DATE_FORMAT(cu.created, '%Y-%m-%d')",  "DATE_FORMAT(cu.created, '%Y-%m-%d %H:%i:%s') AS created" ],
    ['LAST_CREATED',     'DATE', "DATE_FORMAT(MAX(cu.created), '%Y-%m-%d')",  "DATE_FORMAT(MAX(cu.created), '%Y-%m-%d') AS created" ],
    ['DILLER_NAME',      'STR',  "if(cd_users.fio<>'', cd_users.fio, cd.uid) AS diller_name", 1 ],
    ['DILLER_DATE',      'DATE', 'cu.diller_date', 1],
    ['DILLER_SOLD_DATE', 'DATE', "IF(cu.diller_sold_date='0000-00-00', '', cu.diller_sold_date) AS diller_sold_date", 1],
    ['DILLER_ID',        'INT',  'cu.diller_id',    ],
    ['AID',              'INT',  'cu.aid',         1],
    ['TP_ID',            'INT',  'tp.id',          1],
    ['ID',               'INT',  'cu.id'            ],
    ['IDS',              'INT',  'cu.id'            ],
    ['MONTH',            'INT',  'cu.datetime',    1],
    ['STATUS',           'INT',  'cu.status',      1],
    ['PIN',              'STR',  "DECODE(cu.pin, '$CONF->{secretkey}') AS pin",  1],

    ['DATE',             'DATE', "DATE_FORMAT(cu.datetime, '%Y-%m-%d')"  ],
    ['CREATED_MONTH',    'DATE', "DATE_FORMAT(cu.created, '%Y-%m')"      ],
    ['FROM_DATE|TO_DATE','DATE', "DATE_FORMAT(cu.created, '%Y-%m-%d')",  ],
    ['CREATED_FROM_DATE|CREATED_TO_DATE',  'DATE',  "DATE_FORMAT(cu.created, '%Y-%m-%d')",  ],
    ['USED_DATE',             'DATE', "", "IF (cu.status=2, cu.datetime, '') AS used_date"  ],
  ],
  {
    WHERE => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $list;

  if ($attr->{TYPE} && $attr->{TYPE} eq 'TP') {
    if ($attr->{TP_ID} && $attr->{TP_ID} ne '_SHOW' ) {
      $self->query2("SELECT CONCAT(cu.serial,if($self->{CARDS_NUMBER_LENGTH}>0, MID(cu.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), cu.number)) AS sn,
        u.id AS login,
        DECODE(cu.pin, '$CONF->{secretkey}') AS pin,
        tp.name AS tp_name,
        if(u.activate <> '0000-00-00', u.activate, '-') AS activate,
        cu.sum,
        tp.age,
        tp.total_time_limit
         FROM cards_users cu
      LEFT JOIN admins a ON (cu.aid = a.aid)
      LEFT JOIN groups g ON (cu.gid = g.gid)
      LEFT JOIN cards_dillers cd ON (cu.diller_id = cd.id)
      LEFT JOIN users u ON (cu.uid = u.uid)
      LEFT JOIN dv_main dv ON (u.uid = dv.uid)
      LEFT JOIN tarif_plans tp ON (tp.domain_id='$admin->{DOMAIN_ID}' and dv.tp_id = tp.id)
      $WHERE
      GROUP BY 1,2
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
      );

      return $self if ($self->{errno});
      $list = $self->{list};

      $self->query2("SELECT count(*) AS total, sum(cu.sum) AS total_sum FROM cards_users cu
      LEFT JOIN admins a ON (cu.aid = a.aid)
      LEFT JOIN groups g ON (cu.gid = g.gid)
      LEFT JOIN cards_dillers cd ON (cu.diller_id = cd.id)
      LEFT JOIN users u ON (cu.uid = u.uid)
      LEFT JOIN dv_main dv ON (u.uid = dv.uid)
      LEFT JOIN tarif_plans tp ON (tp.domain_id='$admin->{DOMAIN_ID}' and dv.tp_id = tp.id)
      $WHERE;",
      undef, { INFO => 1 }
      );
    }
    else {
      $self->query2("SELECT DATE_FORMAT(cu.created, '%Y-%m-%d') AS date,
         tp.name AS tp_name,
         COUNT(*) AS count,
         SUM(sum) AS sum,
         tp.id AS tp_id
         FROM cards_users cu
      LEFT JOIN admins a ON (cu.aid = a.aid)
      LEFT JOIN groups g ON (cu.gid = g.gid)
      LEFT JOIN cards_dillers cd ON (cu.diller_id = cd.id)
      LEFT JOIN users u ON (cu.uid = u.uid)
      LEFT JOIN dv_main dv ON (u.uid = dv.uid)
      LEFT JOIN tarif_plans tp ON (tp.domain_id='$admin->{DOMAIN_ID}' and dv.tp_id = tp.id)
      $WHERE
      GROUP BY 1,2
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
      );

      return $self if ($self->{errno});
      $list = $self->{list};
    }
  }
  else {
    my $EXT_TABLES = '';
    if ($attr->{TP_ID}) {
      $EXT_TABLES = "LEFT JOIN dv_main dv ON (u.uid = dv.uid)
        LEFT JOIN tarif_plans tp ON (tp.domain_id='$admin->{DOMAIN_ID}' and dv.tp_id = tp.id)";
    }

    $self->query2("SELECT cu.serial, $self->{SEARCH_FIELDS} cu.id, cu.uid, cu.diller_id, cd.uid AS diller_uid
         FROM cards_users cu
     LEFT JOIN admins a ON (cu.aid = a.aid)
     LEFT JOIN groups g ON (cu.gid = g.gid)
     LEFT JOIN cards_dillers cd ON (cu.diller_id = cd.id)
     LEFT JOIN users_pi cd_users ON (cd.uid = cd_users.uid)
     LEFT JOIN users u ON (cu.uid = u.uid)
     $EXT_TABLES
     $WHERE
     $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );

    return $self if ($self->{errno});
    $list = $self->{list};

    if ($attr->{SKIP_TOTALS}) {
      return $list;
    }

    $self->query2("SELECT
       count(*) AS total_cards,
       sum(if(cu.status=0, 1, 0)) AS enabled,
       sum(if(cu.status=1, 1, 0)) AS disabled,
       sum(if(u.activate <> '0000-00-00' or cu.status=2, 1, 0)) AS used,
       sum(if(u.activate IS NULL, 1, 0)) AS deleted,
       sum(if(cu.status=4, 1, 0)) AS returned,
       sum(if(cu.diller_sold_date<>'0000-00-00', 1, 0)) AS diller_sold,

       sum(cu.sum) AS total_sum,
       sum(if(cu.status=0, cu.sum, 0)) AS enabled_sum,
       sum(if(cu.status=1, cu.sum, 0)) AS disabled_sum,
       sum(if(u.activate <> '0000-00-00'  or cu.status=2 , cu.sum, 0)) AS used_sum,
       sum(if(u.activate IS NULL, cu.sum, 0)) AS deleted_sum,
       sum(if(cu.status=4, cu.sum, 0)) AS returned_sum,
       sum(if(cu.diller_sold_date<>'0000-00-00', cu.sum, 0)) AS diller_sold_sum,

       count(DISTINCT serial) AS serial

     FROM cards_users cu
     LEFT JOIN admins a ON (cu.aid = a.aid)
     LEFT JOIN groups g ON (cu.gid = g.gid)
     LEFT JOIN cards_dillers cd ON (cu.diller_id = cd.id)
     LEFT JOIN users u ON (cu.uid = u.uid)
     $WHERE;",
     undef,
     { INFO => 1 }
    );
  }

  if (defined($attr->{SERIAL}) && $attr->{SERIAL} ne '_SHOW') {
    $self->{TOTAL}=$self->{TOTAL_CARDS};
  }
  elsif($self->{SERIAL}) {
    $self->{TOTAL}=$self->{SERIAL} ;
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub cards_report_dillers {
  my $self = shift;
  my ($attr) = @_;

  my $active_date      = 'u.activate <> \'0000-00-00\'';
  my $diller_date      = 'c.diller_date <> \'0000-00-00\'';
  my $diller_sold_date = 'c.diller_sold_date <> \'0000-00-00\'';
  my @WHERE_RULES      = ();

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " (c.diller_sold_date='$attr->{DATE}' or DATE_FORMAT(c.datetime, '%Y-%m-%d')='$attr->{DATE}' or  DATE_FORMAT(c.diller_date, '%Y-%m-%d')='$attr->{DATE}')";

    $active_date = "u.activate = '$attr->{DATE}'";

    $diller_date      = "c.diller_date = '$attr->{DATE}'";
    $diller_sold_date = "c.diller_sold_date = '$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "((DATE_FORMAT(c.datetime, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.datetime, '%Y-%m-%d')<='$to') or
    (DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to'))";

    $active_date = "(DATE_FORMAT(u.activate, '%Y-%m-%d')>='$from' and DATE_FORMAT(u.activate, '%Y-%m-%d')<='$to')";
    $diller_date = "(DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to')";
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')='$attr->{MONTH}' or DATE_FORMAT(diller_date, '%Y-%m')='$attr->{MONTH}')";
    $active_date = 'DATE_FORMAT(u.activate, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
    $diller_date = 'DATE_FORMAT(c.diller_date, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
  }

  if (defined($attr->{SERIA})) {
    $attr->{SERIA} =~ s/\*/\%/ig;
    push @WHERE_RULES, "cu.serial='$attr->{SERIA}'";
  }

  my $GROUP    = 'if (pi.fio<>\'\', pi.fio, pi.uid)';
  my $GROUP_BY = 'cd.id';

  if ($attr->{GROUP}) {
    $GROUP_BY = $attr->{GROUP};
    $GROUP    = 1;
  }

  #By cards
  my $list;
  if ($attr->{GROUP}) {

    my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

    $self->query2("SELECT $GROUP,
       sum(if(c.status=0, 1, 0)),
        sum(if(c.status=0, c.sum, 0)),
       sum(if(c.status=1, 1, 0)),
        sum(if(c.status=1, c.sum, 0)),
       sum(if(c.status=2, 1, 0)),
        sum(if(c.status=2, c.sum, 0)),
       sum(if($active_date, 1, 0)),
        sum(if($active_date, c.sum, 0)),
       sum(if($diller_date, 1, 0)),
        sum(if($diller_date, c.sum, 0)),
       sum(if($diller_sold_date, 1, 0)),
        sum(if($diller_sold_date, c.sum, 0)),
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)),
       sum(if(c.status=4, 1, 0)),
        sum(if(c.status=4, c.sum, 0)),
       count(*),
        sum(c.sum)

    FROM cards_users c
    LEFT join cards_dillers cd ON (c.diller_id = cd.id)
    LEFT JOIN users u ON (c.uid = u.uid)
    LEFT JOIN users_pi pi ON (cd.uid = pi.uid)
     $WHERE
     GROUP BY $GROUP_BY
     ORDER BY 1;",
     undef, $attr
    );

    return $self if ($self->{errno});
    $list = $self->{list};

    $self->query2("SELECT
       sum(if(c.status=0, 1, 0)) as enable_total,
        sum(if(c.status=0, c.sum, 0)) as enable_total_sum,
       sum(if(c.status=1, 1, 0)) as disable_total,
        sum(if(c.status=1, c.sum, 0)) as disable_total_sum,
       sum(if(c.status=2, 1, 0)) as payment_total,
        sum(if(c.status=2, c.sum, 0)) as payment_total_sum,
       sum(if($active_date, 1, 0)) as login_total,
        sum(if($active_date, c.sum, 0)) as login_total_sum,
       sum(if($diller_date, 1, 0)) as take_total,
        sum(if($diller_date, c.sum, 0)) as take_total_sum,
       sum(if($diller_sold_date, 1, 0)) as sold_total,
        sum(if($diller_sold_date, c.sum, 0)) as sold_total_sum,
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)) as sold_total_percentage,
       sum(if(c.status=4, 1, 0)) as return_total,
        sum(if(c.status=4, c.sum, 0)) as return_total_sum,
       count(*) as count_total,
        sum(c.sum) as count_total_sum

    FROM (cards_users c)
    LEFT join cards_dillers cd ON (c.diller_id = cd.id)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
     undef, { INFO => 1 }
    );
  }

  # By dillers
  else {
    my $WHERE = "WHERE c.diller_id = cd.id ";
    $WHERE .= ($#WHERE_RULES > -1) ? " and " . join(' and ', @WHERE_RULES) : '';

    $self->query2("SELECT $GROUP,
       sum(if(c.status=0, 1, 0)),
        sum(if(c.status=0, c.sum, 0)),
       sum(if(c.status=1, 1, 0)),
        sum(if(c.status=1, c.sum, 0)),
       sum(if(c.status=2, 1, 0)),
        sum(if(c.status=2, c.sum, 0)),
       sum(if($active_date, 1, 0)),
        sum(if($active_date, c.sum, 0)),
       sum(if($diller_date, 1, 0)),
        sum(if($diller_date, c.sum, 0)),
       sum(if($diller_sold_date, 1, 0)),
        sum(if($diller_sold_date, c.sum, 0)),
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)),
       sum(if(c.status=4, 1, 0)),
        sum(if(c.status=4, c.sum, 0)),
       count(*),
        sum(c.sum),
       c.diller_id, cd.uid
    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
    LEFT JOIN users_pi pi ON (cd.uid = pi.uid)
     $WHERE
     GROUP BY $GROUP_BY
     ORDER BY 1;",
     undef, $attr
    );

    return $self if ($self->{errno});
    $list = $self->{list};

    $self->query2("SELECT
       sum(if(c.status=0, 1, 0)) AS ENABLE_TOTAL,
        sum(if(c.status=0, c.sum, 0)) AS ENABLE_TOTAL_SUM,
       sum(if(c.status=1, 1, 0)) AS DISABLE_TOTAL,
        sum(if(c.status=1, c.sum, 0)) AS DISABLE_TOTAL_SUM,
       sum(if(c.status=2, 1, 0)) AS PAYMENT_TOTAL,
        sum(if(c.status=2, c.sum, 0)) AS PAYMENT_TOTAL_SUM,
       sum(if($active_date, 1, 0)) AS LOGIN_TOTAL,
        sum(if($active_date, c.sum, 0)) AS LOGIN_TOTAL_SUM,
       sum(if($diller_date, 1, 0)) AS TAKE_TOTAL,
        sum(if($diller_date, c.sum, 0)) AS TAKE_TOTAL_SUM,
       sum(if($diller_sold_date, 1, 0)) AS SOLD_TOTAL,
        sum(if($diller_sold_date, c.sum, 0)) SOLD_TOTAL_SUM,
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)) AS  SOLD_TOTAL_PERCENTAGE,
       sum(if(c.status=4, 1, 0)) AS RETURN_TOTAL,
        sum(if(c.status=4, c.sum, 0)) AS RETURN_TOTAL_SUM,
       count(*) AS COUNT_TOTAL,
        sum(c.sum) AS COUNT_TOTAL_SUM

    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
     undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub cards_report_days {
  my $self = shift;
  my ($attr) = @_;

  my %RESULT                  = ();
  my @WHERE_RULES             = ("c.domain_id='$admin->{DOMAIN_ID}'");
  my @WHERE_RULES_DILLERS     = ("c.domain_id='$admin->{DOMAIN_ID}'");
  my @WHERE_RULES_USERS       = ("c.domain_id='$admin->{DOMAIN_ID}'");
  my @WHERE_RULES_DILLER_SOLD = ("c.domain_id='$admin->{DOMAIN_ID}'");

  #Short reports for dillers
  if ($attr->{CREATED_MONTH} || $attr->{CREATED_FROM_DATE} || $attr->{CREATED_MONTH}) {

    if ($attr->{DILLER_ID}) {
      push @WHERE_RULES, "c.diller_id='$attr->{DILLER_ID}'";
    }

    if ($attr->{STATUS}) {
      $attr->{STATUS}--;
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATUS}, 'INT', 'c.status') };
    }

    if ($attr->{CREATED_DATE}) {
      push @WHERE_RULES, "DATE_FORMAT(c.created, '%Y-%m-%d')='$attr->{CREATED_DATE}'";
    }
    elsif ($attr->{CREATED_MONTH}) {
      push @WHERE_RULES, "DATE_FORMAT(c.created, '%Y-%m')='$attr->{CREATED_MONTH}'";
    }
    elsif ($attr->{CREATED_FROM_DATE}) {
      push @WHERE_RULES, "(DATE_FORMAT(c.created, '%Y-%m-%d')>='$attr->{CREATED_FROM_DATE}' and DATE_FORMAT(c.created, '%Y-%m-%d')<='$attr->{CREATED_TO_DATE}')";
    }

    my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

    $self->query2("SELECT
    DATE_FORMAT(c.created, '%Y-%m-%d') AS date,
    COUNT(*) AS count,
    SUM(c.sum) AS sum
   FROM cards_users c
    $WHERE
   GROUP BY 1;", undef, $attr
    );

    return $self->{list};
  }

  if ($attr->{DILLER_ID}) {
    push @WHERE_RULES,             "c.diller_id='$attr->{DILLER_ID}'";
    push @WHERE_RULES_DILLERS,     "c.diller_id='$attr->{DILLER_ID}'";
    push @WHERE_RULES_USERS,       "c.diller_id='$attr->{DILLER_ID}'";
    push @WHERE_RULES_DILLER_SOLD, "c.diller_id='$attr->{DILLER_ID}'";
  }

  if (defined($attr->{DATE})) {
    push @WHERE_RULES,             " DATE_FORMAT(c.datetime, '%Y-%m-%d')='$attr->{DATE}'";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m-%d')='$attr->{DATE}'";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m-%d')='$attr->{DATE}'";
    push @WHERE_RULES_DILLER_SOLD, "c.diller_sold_date='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES,             "DATE_FORMAT(c.datetime, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.datetime, '%Y-%m-%d')<='$to'";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to'";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m-%d')>='$from' and DATE_FORMAT(u.activate, '%Y-%m-%d')<='$to'";
    push @WHERE_RULES_DILLER_SOLD, "c.diller_sold_date>='$from' and c.diller_sold_date<='$to'";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES,             "DATE_FORMAT(c.datetime, '%Y-%m')='$attr->{MONTH}'";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m')='$attr->{MONTH}'";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m')='$attr->{MONTH}'";
    push @WHERE_RULES_DILLER_SOLD, "DATE_FORMAT(c.diller_sold_date, '%Y-%m')='$attr->{MONTH}'";
  }
  else {
    push @WHERE_RULES,             "DATE_FORMAT(c.datetime, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
    push @WHERE_RULES_DILLER_SOLD, "DATE_FORMAT(c.diller_sold_date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
  }

  my $WHERE              = ($#WHERE_RULES > -1)             ? "WHERE " . join(' and ', @WHERE_RULES)             : '';
  my $WHERE_DILLERS      = ($#WHERE_RULES_DILLERS > -1)     ? "WHERE " . join(' and ', @WHERE_RULES_DILLERS)     : '';
  my $WHERE_DILLERS_SOLD = ($#WHERE_RULES_DILLER_SOLD > -1) ? "WHERE " . join(' and ', @WHERE_RULES_DILLER_SOLD) : '';

  # TO Diller
  #ENABLE, _DISABLE, _USED/logined, _DELETED, _RETURNED

  $self->query2("select
 DATE_FORMAT(c.created, '%Y-%m-%d'),
 sum(if(c.status=0, 1, 0)),
  sum(if(c.status=0, c.sum, 0)),
 sum(if(c.status=1, 1, 0)),
  sum(if(c.status=1, c.sum, 0)),
 sum(if(c.status=2, 1, 0)),
  sum(if(c.status=2, c.sum, 0)),
 sum(if(c.status=4, 1, 0)),
  sum(if(c.status=4, c.sum, 0))
from cards_users c
 $WHERE
GROUP BY 1;"
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{ENABLE}     = $line->[1];
    $RESULT{ $line->[0] }{ENABLE_SUM} = $line->[2];

    $RESULT{ $line->[0] }{DISABLE}     = $line->[3];
    $RESULT{ $line->[0] }{DISABLE_SUM} = $line->[4];

    $RESULT{ $line->[0] }{USED}     = $line->[5];
    $RESULT{ $line->[0] }{USED_SUM} = $line->[6];

    $RESULT{ $line->[0] }{RETURNED}     = $line->[7];
    $RESULT{ $line->[0] }{RETURNED_SUM} = $line->[8];
  }

  #TOtals
  $self->query2("select
 sum(if(c.status=0, 1, 0)) as enable_total,
  sum(if(c.status=0, c.sum, 0)) as enable_total_sum,
 sum(if(c.status=1, 1, 0)) as disable_total,
  sum(if(c.status=1, c.sum, 0)) as disable_total_sum,
 sum(if(c.status=2, 1, 0)) as used_total,
  sum(if(c.status=2, c.sum, 0)) as used_total_sum,
 sum(if(c.status=3, 1, 0)) as returned_total,
  sum(if(c.status=3, c.sum, 0)) as returned_total_sum
from cards_users c
 $WHERE ;",
 undef,
 { INFO => 1 }
  );

##Dillers
  $self->query2("select c.diller_date, count(*) AS count, sum(c.sum) AS sum
from cards_users c
 $WHERE_DILLERS
GROUP BY 1;"
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{DILLERS}     = $line->[1];
    $RESULT{ $line->[0] }{DILLERS_SUM} = $line->[2];
  }

  #TOtals
  $self->query2("SELECT count(*) AS dillers_total, sum(c.sum) AS dillers_total_sum from cards_users c
 $WHERE_DILLERS;",
   undef,
    {INFO => 1 }
  );

##Dillers sold
  $self->query2("SELECT c.diller_sold_date, count(*), sum(c.sum)
from cards_users c
 $WHERE_DILLERS_SOLD
GROUP BY 1;"
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{DILLERS_SOLD}     = $line->[1];
    $RESULT{ $line->[0] }{DILLERS_SOLD_SUM} = $line->[2];
  }

  #TOtals
  $self->query2("SELECT count(*) AS dillers_sold_total, sum(c.sum) AS dillers_sold_total_sum from cards_users c
 $WHERE_DILLERS_SOLD;",
 undef, { INFO => 1 }
  );

##Login
  my $WHERE_USERS = "WHERE c.uid = u.uid and " . join(' and ', @WHERE_RULES_USERS);

  $self->query2("SELECT
    u.activate,
    sum(if(u.activate <> '0000-00-00', 1, 0)),
    sum(if(u.activate <> '0000-00-00', c.sum, 0))
    FROM (cards_users c, users u)
    $WHERE_USERS
  GROUP BY 1;",
  undef,
  $attr
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{LOGIN}     = $line->[1];
    $RESULT{ $line->[0] }{LOGIN_SUM} = $line->[2];
  }

  #TOtals
  $self->query2("SELECT
     sum(if(u.activate <> '0000-00-00', 1, 0)) As login_total,
     sum(if(u.activate <> '0000-00-00', c.sum, 0)) AS login_total_sum
    FROM (cards_users c, users u )
   $WHERE_USERS
    ;",
    undef, { INFO=>1 }
  );

  return \%RESULT;
}

#**********************************************************
=head2 cards_report_payments()

=cut
#**********************************************************
sub cards_report_payments {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "(DATE_FORMAT(p.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and DATE_FORMAT(p.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m')='$attr->{MONTH}'";
  }
  else {
    push @WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
  }

  my $WHERE .= ($#WHERE_RULES > -1) ? join(' AND ', @WHERE_RULES) : '';

  $self->query2("SELECT p.date, u.id AS login, p.sum, pi.fio,
    concat(c.serial,if($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number)) AS cards_count,
    pi_d.fio AS diller, u.uid
  FROM payments p
  INNER JOIN users u ON (u.uid=p.uid)
  INNER JOIN cards_users c ON (p.ext_id=concat(c.serial,if($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number)))
  LEFT JOIN users_pi pi ON (pi.uid=u.uid)
  LEFT JOIN cards_dillers cd ON (c.diller_id=cd.id)
  LEFT JOIN users_pi pi_d ON (pi_d.uid=cd.uid)
  WHERE $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  return $self if ($self->{errno});
  my $list = $self->{list};

  $self->query2("SELECT count(p.id) AS total, sum(p.sum) AS TOTAL_SUM
  FROM payments p
  INNER JOIN cards_users c ON (p.ext_id=concat(c.serial,if($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number)))
  WHERE $WHERE;",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
#
#**********************************************************
sub cards_report_seria {
  my $self = shift;
  my ($attr) = @_;

  my $active_date = 'u.activate <> \'0000-00-00\'';
  my $diller_date = 'c.diller_date <> \'0000-00-00\'';
  my @WHERE_RULES = ();

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " (DATE_FORMAT(c.datetime, '%Y-%m-%d')='$attr->{DATE}' or  DATE_FORMAT(c.diller_date, '%Y-%m-%d')='$attr->{DATE}')";
    $active_date = "u.activate = '$attr->{DATE}'";
    $diller_date = "c.diller_date = '$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "((DATE_FORMAT(c.datetime, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.datetime, '%Y-%m-%d')<='$to') or
    (DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to'))";

    $active_date = "(DATE_FORMAT(u.activate, '%Y-%m-%d')>='$from' and DATE_FORMAT(u.activate, '%Y-%m-%d')<='$to')";
    $diller_date = "(DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to')";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')='$attr->{MONTH}' or DATE_FORMAT(diller_date, '%Y-%m')='$attr->{MONTH}')";
    $active_date = 'DATE_FORMAT(u.activate, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
    $diller_date = 'DATE_FORMAT(c.diller_date, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
  }
  else {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m') or DATE_FORMAT(diller_date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m') )";
    $active_date = 'DATE_FORMAT(u.activate, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
    $diller_date = 'DATE_FORMAT(c.diller_date, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
  }

  if (defined($attr->{SERIA})) {
    $attr->{SERIA} =~ s/\*/\%/ig;
    push @WHERE_RULES, "cu.serial='$attr->{SERIA}'";
  }

  my $WHERE = "WHERE c.diller_id = cd.id AND cu.domain_id='$admin->{DOMAIN_ID}' ";

  $WHERE .= ($#WHERE_RULES > -1) ? " and " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT cd.name,
       sum(if(c.status=0, 1, 0)),
        sum(if(c.status=0, c.sum, 0)),
       sum(if(c.status=1, 1, 0)),
        sum(if(c.status=1, c.sum, 0)),
       sum(if(c.status=2, 1, 0)),
        sum(if(c.status=2, c.sum, 0)),
       sum(if($active_date, 1, 0)),
        sum(if($active_date, c.sum, 0)),
       sum(if($diller_date, 1, 0)),
        sum(if($diller_date, c.sum, 0)),
       sum(if(c.status=4, 1, 0)),
        sum(if(c.status=4, c.sum, 0)),
       count(*),
        sum(c.sum)

    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     GROUP BY cd.id
     ORDER BY 1;",
     undef,
     $attr
  );

  return $self if ($self->{errno});
  my $list = $self->{list};

  $self->query2("SELECT
       sum(if(c.status=0, 1, 0)) AS ENABLE_TOTAL,
        sum(if(c.status=0, c.sum, 0)) AS ENABLE_TOTAL_SUM,
       sum(if(c.status=1, 1, 0)) AS DISABLE_TOTAL,
        sum(if(c.status=1, c.sum, 0)) AS DISABLE_TOTAL_SUM,
       sum(if(c.status=2, 1, 0)) AS PAYMENT_TOTAL,
        sum(if(c.status=2, c.sum, 0)) AS PAYMENT_TOTAL,
       sum(if($active_date, 1, 0)) AS PAYMENT_TOTAL,
        sum(if($active_date, c.sum, 0)) AS PAYMENT_TOTAL_SUM,
       sum(if($diller_date, 1, 0)) AS TAKE_TOTAL,
        sum(if($diller_date, c.sum, 0)) AS TAKE_TOTAL_SUM,
       sum(if(c.status=4, 1, 0)) AS LOGIN_TOTAL,
        sum(if(c.status=4, c.sum, 0)) AS LOGIN_TOTAL_SUM,
       count(*) AS RETURN_TOTAL,
        sum(c.sum) AS RETURN_TOTAL_SUM

    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bruteforce_list($attr)

=cut
#**********************************************************
sub bruteforce_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $fields = "u.id,
               SUM(IF(DATE_FORMAT(cb.datetime, '%Y-%m-%d')=CURDATE(), 1, 0)),
               COUNT(*),
               MAX(datetime),
               cb.uid
               ";
  my $GROUP = "GROUP BY cb.uid";

  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, " cb.uid='$attr->{UID}'";

    $fields = "u.id,
               cb.pin,
               datetime";
    $GROUP = "";
  }
  elsif ($attr->{LOGIN}) {
    $attr->{LOGIN} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN}'";
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DATE}", 'DATE', "DATE_FORMAT(cb.datetime, '%Y-%m-%d')") };
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, "cb.domain_id='$admin->{DOMAIN_ID}'";
  }

  if ($attr->{MONTH}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{MONTH}", 'DATE', "DATE_FORMAT(cb.datetime, '%Y-%m')") };
  }

  # Date intervals
  elsif ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(DATE_FORMAT(cb.datetime, '%Y-%m-%d')>='$attr->{FROM_DATE}' and DATE_FORMAT(cb.datetime, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

  if (defined($attr->{SERIA})) {
    $attr->{SERIA} =~ s/\*/\%/ig;
    push @WHERE_RULES, "cp.serial='$attr->{SERIA}'";

    $fields = "
    cp.serial,
              IF($self->{CARDS_NUMBER_LENGTH}>0, MID(cp.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), cp.number),
              cp.sum,
              cp.status,
              cp.datetime,
              a.id";
    $GROUP = "cp.serial, cp.number";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT $fields
         FROM cards_bruteforce cb
     LEFT JOIN users u ON (cb.uid = u.uid)
     $WHERE
     $GROUP
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef, $attr
  );

  return [] if ($self->{errno});
  my $list = $self->{list};
  $self->{BRUTE_COUNT} = $self->{TOTAL} || 0;

  $self->query2("SELECT COUNT(*) AS total FROM cards_bruteforce cb
      LEFT JOIN users u ON (cb.uid = u.uid)
      $WHERE",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bruteforce_add($attr)

=cut
#**********************************************************
sub bruteforce_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cards_bruteforce', {
    %$attr,
    DATETIME => 'NOW()'
  });

  return $self;
}

#**********************************************************
=head2 bruteforce_del($attr)

=cut
#**********************************************************
sub bruteforce_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{UID}) {
    $WHERE = "WHERE UID='$attr->{UID}'";
  }
  elsif ($attr->{PERIOD}) {
    $WHERE = "WHERE datetime <  now() - INTERVAL $attr->{PERIOD} day ";
  }
  else {
    $WHERE = '';
  }

  $self->query2("DELETE FROM cards_bruteforce $WHERE;", 'do');
  return $self;
}

#**********************************************************
# Periodic
#**********************************************************
#sub periodic {
#  my $self = shift;
#  my ($period) = @_;
#
#  if ($period eq 'daily') {
#    $self->daily_fees();
#  }
#
#  return $self;
#}

#**********************************************************
=head2 cards_diller_add($attr)

=cut
#**********************************************************
sub cards_diller_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cards_dillers', { REGISTRATION => 'NOW()',
                                      %$attr,
                                      DISABLE => $attr->{DISABLE} || 0
                                     });

  return $self;
}

#**********************************************************
=head2 cards_diller_info($attr) - User information

=cut
#**********************************************************
sub cards_diller_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{UID}) {
    $WHERE = "cd.uid='$attr->{UID}'";
  }
  else {
    $WHERE = "cd.id='$attr->{ID}'";
  }

  $self->query2("SELECT
             cd.id,
             cd.disable,
             cd.registration,
             cd.comments,
             cd.percentage,
             cd.tp_id,
             tp.name as tp_name,
             cd.uid,
             pi.fio,
   CONCAT(pi.address_street, ', ', pi.address_build, '/', pi.address_flat) as address,
    pi.phone,
    tp.payment_type,
    tp.operation_payment,
    if (cd.percentage>0,  cd.percentage, tp.percentage) AS diller_percentage

    FROM cards_dillers cd
    LEFT JOIN users_pi pi ON (cd.uid=pi.uid)
    LEFT JOIN dillers_tps tp ON (tp.id=cd.tp_id)
    WHERE  $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 cards_diller_change($attr)

=cut
#**********************************************************
sub cards_diller_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ID} = $attr->{chg} if ($attr->{chg});
  $attr->{DISABLE} = 0 if (! defined($attr->{DISABLE}));

  $admin->{MODULE} = $MODULE;
  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cards_dillers',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2  cards_dillers_list($attr)

=cut
#**********************************************************
sub cards_dillers_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG})   ? $attr->{PG}   : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.domain_id='$admin->{DOMAIN_ID}'");

  my $WHERE = $self->search_former($attr, [
      ['ADDRESS',      'STR',  'cd.address'      ],
      ['EMAIL',        'STR',  'cd.email'        ],
      ['UID',          'INT',  'cd.uid'          ],
      ['DISABLE',      'INT',  'cd.disable',     ],
      ['NAME',         'STR',  'cd.name',        ],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT cd.id, u.id AS login, pi.fio,
      CONCAT(pi.address_street, ', ', pi.address_build, '/', pi.address_flat) AS address,
      pi.email, cd.registration,
      cd.percentage,
      cd.disable,
      count(cu.serial),
      sum(if(cu.status=0, 1, 0)),
      cd.uid
    FROM cards_dillers cd
    INNER JOIN users u ON (cd.uid = u.uid)
    LEFT JOIN users_pi pi ON (pi.uid = u.uid)
    LEFT JOIN cards_users cu ON (cd.id = cu.diller_id)
     $WHERE
     GROUP BY cd.id
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  return [] if ($self->{errno});
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(DISTINCT cd.id) AS total FROM cards_dillers cd
       INNER JOIN users u ON (cd.uid = u.uid)
       LEFT JOIN cards_users cu ON (cd.id = cu.diller_id)
      $WHERE ",
      undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 cards_diller_del($attr) Delete cards_diller_del

=cut
#**********************************************************
sub cards_diller_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cards_dillers', $attr, { uid => $attr->{UID} });

  $admin->action_add($attr->{UID}, $attr->{UID}, { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 dillers_tp_add($attr)

=cut
#**********************************************************
sub dillers_tp_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('dillers_tps', $attr);

  $self->{TP_ID} = $self->{INSERT_ID};
  $admin->system_action_add("DILLERS_TP:$self->{TP_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub dillers_tp_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS_TP} = (defined($attr->{NAS_TP})) ? int($attr->{NAS_TP}) : 0;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'dillers_tps',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
#
# dillers_tp_del(attr);
#**********************************************************
sub dillers_tp_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('dillers_tps',$attr);

  $admin->system_action_add("DILLERS_TP:$self->{TP_ID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub dillers_tp_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
      ['ID',      'INT',  'id'      ],
      ['NAME',    'STR',  'name'    ],
      ['NAS_TP',  'INT',  'NAS_TP'  ],
    ],
    { WHERE => 1,
    }
    );

  $self->query2("SELECT
             name,
             percentage,
             operation_payment,
             payment_type,
             id,
             comments,
             bonus_cards
     FROM dillers_tps tp
     $WHERE;",
  undef,
  $attr
  );

  return $self->{list};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub dillers_tp_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT
             id,
             name,
             payment_type,
             percentage,
             operation_payment,
             payment_expr,
             activate_price,
             change_price,
             credit,
             min_use,
             nas_tp,
             gid,
             comments,
             bonus_cards
    FROM dillers_tps
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
# diller_permissions_set()
#**********************************************************
sub diller_permissions_set {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('dillers_permits', undef, { diller_id => $attr->{DILLER_ID} });

  my @permits = split(/, /, $attr->{PERMITS});
   my @MULTI_QUERY = ();

  foreach my $section (@permits) {
    push @MULTI_QUERY, [ $attr->{DILLER_ID}, $section ];
  }

  $self->query2("INSERT INTO dillers_permits (diller_id, section)
        VALUES (?, ?);",
        undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });


  return $self;
}

#**********************************************************
# get_permissions()
#**********************************************************
sub diller_permissions_list {
  my $self        = shift;
  my ($attr)      = @_;
  my %permissions = ();

  $self->query2("SELECT section, actions FROM dillers_permits WHERE diller_id= ? ;", undef, { Bind => [ $attr->{DILLER_ID} ] });

  foreach my $line (@{ $self->{list} }) {
    $permissions{ $line->[0] } = 1;
  }

  $self->{permissions} = \%permissions;

  return $self->{permissions};
}


#**********************************************************
# get_permissions()
#**********************************************************
sub cards_chg_status {
  my $self        = shift;

  $self->query2("UPDATE cards_users cu, errors_log l SET
      cu.status=2,
      cu.datetime=now()
    WHERE cu.login<>'' AND cu.status=0 AND cu.login=l.user;",
    'do',
  );

  return $self;
}

1
