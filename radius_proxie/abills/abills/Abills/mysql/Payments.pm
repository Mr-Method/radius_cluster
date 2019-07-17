package Payments;

=head2  NAME

  Payments Finance module

=cut

use strict;
use Finance;
use parent qw(dbcore Finance);
use Abills::Base qw(date_diff);
use Bills;
my $Bill;

my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
  };

  bless($self, $class);

  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 add($user, $attr) - Add user payments

  Attributes:
    $user   - User object
    $attr   - Aextra attributes
      CHECK_EXT_ID - Check ext id
      ID
    	BILL_ID
    	DATE
    	DSC
    	IP
    	LAST_DEPOSIT
    	AID
    	REG_DATE
    	SUM

  Return
    Object

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($user, $attr) = @_;

  if (!$attr->{SUM} || $attr->{SUM} <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }

  my DBI $db_ = $self->{db}{db};

  if ($self->{db}->{TRANSACTION}) {
    $db_->{AutoCommit} = 0;
  }

  if ($attr->{CHECK_EXT_ID}) {
    $self->{db}{db}->{AutoCommit} = 0;
    $self->query("SELECT id, date, sum, uid FROM payments WHERE ext_id=? LIMIT 1 LOCK IN SHARE MODE;",
     undef,
     { INFO => 1,
       Bind => [ $attr->{CHECK_EXT_ID} ]
     });

    if ($self->{error}) {
      $db_->{AutoCommit} = 1 if(! $db_->{AutoCommit});
      return $self;
    }
    elsif ($self->{TOTAL} > 0) {
      $self->{db}{db}->{AutoCommit} = 1 if(! $self->{db}{db}->{AutoCommit});
      $self->{errno}  = 7;
      $self->{errstr} = 'ERROR_DUBLICATE '.$attr->{CHECK_EXT_ID};
      return $self;
    }
  }

  $user->{BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});
  $attr->{AMOUNT} = $attr->{SUM};

  if ($user->{BILL_ID} > 0) {
    if ($attr->{ER} && $attr->{ER} != 1 && $attr->{ER} > 0) {
      $attr->{SUM} = sprintf("%.2f", $attr->{SUM} / $attr->{ER});
    }

    $Bill->info({ BILL_ID => $user->{BILL_ID} });
    $Bill->action('add', $user->{BILL_ID}, $attr->{SUM});
    if ($Bill->{errno}) {
      $db_->rollback();
      return $self;
    }

    $self->query_add('payments', {
    	%$attr,
    	UID     => $user->{UID},
    	BILL_ID => $user->{BILL_ID},
    	DATE    => ($attr->{DATE}) ? "$attr->{DATE}" : 'NOW()',
    	DSC     => $attr->{DESCRIBE},
    	IP      => $admin->{SESSION_IP},
    	LAST_DEPOSIT => $Bill->{DEPOSIT},
    	AID     => $admin->{AID},
    	REG_DATE=> 'NOW()'
    });

    if (!$self->{errno}) {
      if ($CONF->{payment_chg_activate} && $user->{ACTIVATE} ne '0000-00-00') {
        if ($CONF->{payment_chg_activate} ne 2
           || date_diff($user->{ACTIVATE}, $admin->{DATE}) > 30) {
          #Skip if no user object
          if (ref $user eq 'Users') {
            $user->change(
              $user->{UID},
              {
                UID      => $user->{UID},
                ACTIVATE => $admin->{DATE},
                EXPIRE   => '0000-00-00'
              }
            );
          }
          else {
            print "Error: not user object\n";
          }
        }
      }
      $self->{SUM} = $attr->{SUM};

      if (! $self->{db}->{TRANSACTION} && !$attr->{TRANSACTION}) {
        $db_->commit() if(! $db_->{AutoCommit});
      }
    }
    else {
      $db_->rollback();
    }

    $self->{PAYMENT_ID} = $self->{INSERT_ID};
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  if (! $self->{db}->{TRANSACTION} && !$attr->{NO_AUTOCOMMIT} && !$attr->{TRANSACTION}) {
    $db_->{AutoCommit} = 1 ;
  }

  return $self;
}

#**********************************************************
=head2 del($user, $id, $attr) - Delete payments

  Attributes:
    $user  - User object
    $id    - Payments ID
    $attr  - Extra attributes

  Returns:
    Object

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id, $attr) = @_;

  $self->query("SELECT sum, bill_id from payments WHERE id= ? ;", undef, { Bind => [ $id ]  });

  $self->{db}{db}->{AutoCommit} = 0;
  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id) = @{ $self->{list}->[0] };

  $Bill->action('take', $bill_id, $sum);
  if (! $Bill->{errno}) {
    $self->query_del('docs_invoice2payments', undef, { payment_id => $id });
    $self->query("DELETE FROM docs_receipt_orders WHERE receipt_id=(SELECT id FROM docs_receipts WHERE payment_id='$id');", 'do');
    $self->query_del('docs_receipts', undef, { payment_id => $id });
    $self->query_del('payments', undef, { id => $id });

    if (! $self->{errno}) {
    	my $comments = ($attr->{COMMENTS}) ? $attr->{COMMENTS} : '';
      $admin->{MODULE}=q{};
      $admin->action_add($user->{UID}, "$id $sum $comments", { TYPE => 16 });
      $self->{db}{db}->commit();
    }
    else {
      $self->{db}{db}->rollback();
    }
  }

  $self->{db}{db}->{AutoCommit} = 1;
  return $self;
}

#**********************************************************
=head2 list($attr) - List of payments

  Attributes:
    $attr   - Extra attributes

  Returns:
    Arrya_refs

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if (! $attr->{PAYMENT_DAYS}) {
  	$attr->{PAYMENT_DAYS}=0;
  }
  elsif ($attr->{PAYMENT_DAYS}) {
    my $expr = '=';
    if ($attr->{PAYMENT_DAYS} =~ s/^(<|>)//) {
      $expr = $1;
    }
    push @WHERE_RULES, "p.date $expr CURDATE() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATETIME',       'DATE','p.date',                       ], #'p.date AS datetime'],
      ['SUM',            'INT', 'p.sum',                        ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                     ],
      ['A_LOGIN',        'STR', 'a.id'                          ],
      ['ADMIN_NAME',     'STR', 'a.id'                          ],
      ['DESCRIBE',       'STR', 'p.dsc'                         ],
      ['INNER_DESCRIBE', 'STR', 'p.inner_describe'              ],
      ['AMOUNT',         'INT', 'p.amount',                    1],
      ['CURRENCY',       'INT', 'p.currency',                  1],
      ['METHOD',         'INT', 'p.method'                      ],
      ['BILL_ID',        'INT', 'p.bill_id',                   1],
      ['AID',            'INT', 'p.aid',                        ],
      ['IP',             'INT', 'INET_NTOA(p.ip)',  'INET_NTOA(p.ip) AS ip'],
      ['EXT_ID',         'STR', 'p.ext_id',                                ],
      ['ADMIN_NAME',     'STR', '', "IF(a.name is null, 'Unknown', a.name) AS admin_name" ],
      ['INVOICE_NUM',    'INT', 'd.invoice_num',                          1],
      ['DATE',           'DATE','DATE_FORMAT(p.date, \'%Y-%m-%d\')'        ],
      ['REG_DATE',       'DATE','p.reg_date',                             1],
      ['MONTH',          'DATE','DATE_FORMAT(p.date, \'%Y-%m\')'           ],
      ['ID',             'INT', 'p.id'                                     ],
      ['FROM_DATE_TIME|TO_DATE_TIME','DATE', "p.date"                      ],
      ['FROM_DATE|TO_DATE', 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')'    ],
      ['UID',            'INT', 'p.uid',                                  1],
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1,
    	SKIP_USERS_FIELDS => [ 'BILL_ID', 'UID', 'LOGIN' ],
    	USE_USER_PI => 1
    }
    );

  my $EXT_TABLES  = '';
  $EXT_TABLES  = $self->{EXT_TABLES} if($self->{EXT_TABLES});

  if ($attr->{INVOICE_NUM}) {
    $EXT_TABLES  .= '  LEFT JOIN (SELECT payment_id, invoice_id FROM docs_invoice2payments GROUP BY payment_id) i2p ON (p.id=i2p.payment_id)
  LEFT JOIN (SELECT id, invoice_num FROM docs_invoices GROUP BY id) d ON (d.id=i2p.invoice_id)
';
  }

  my $list;
  if (!$attr->{TOTAL_ONLY}) {
    $self->query("SELECT p.id,
      u.id AS login,
      p.date AS datetime,
      p.dsc,
      p.sum,
      p.last_deposit,
      p.method,
      p.ext_id,
      $self->{SEARCH_FIELDS}
      p.inner_describe,
      p.uid
    FROM payments p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY p.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
    );
    $self->{SUM} = '0.00';

    return $self->{list} if ($self->{TOTAL} < 1);
    $list = $self->{list};
  }

  $self->query("SELECT COUNT(p.id) AS total, SUM(p.sum) AS sum, COUNT(DISTINCT p.uid) AS total_users
    FROM payments p
  LEFT JOIN users u ON (u.uid=p.uid)
  LEFT JOIN admins a ON (a.aid=p.aid)
  $EXT_TABLES
  $WHERE",
  undef,
  { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 report($attr) - Payments reports

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $date         = '';
  my $GROUP        = 1;
  my %EXT_TABLE_JOINS_HASH = ();

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  $attr->{SKIP_DEL_CHECK}=1;
  my $WHERE =  $self->search_former($attr, [
      ['METHOD',            'INT',  'p.method'                          ],
      ['MONTH',             'DATE', "DATE_FORMAT(p.date, '%Y-%m')"     ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(p.date, '%Y-%m-%d')"  ],
      ['DATE',              'DATE', "DATE_FORMAT(p.date, '%Y-%m-%d')"  ],
    ],
    {
      WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
    }
  );

  if ($attr->{INTERVAL}) {
    if ($attr->{TYPE} eq 'HOURS') {
      $date = "DATE_FORMAT(p.date, '%H') AS hour";
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "DATE_FORMAT(p.date, '%Y-%m-%d') AS date";
    }
    elsif ($attr->{TYPE} eq 'PAYMENT_METHOD') {
      $date = "p.method";
    }
    elsif ($attr->{TYPE} eq 'FIO') {
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $date       = "pi.fio";
      $GROUP      = 5;
    }
    elsif ($attr->{TYPE} eq 'PER_MONTH') {
      $date = "DATE_FORMAT(p.date, '%Y-%m') AS month";
      $self->{SEARCH_FIELDS}="ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
                              ROUND(SUM(p.sum) / (SELECT COUNT(*) FROM users WHERE DATE_FORMAT(registration, '%Y-%m') <= DATE_FORMAT(p.date, '%Y-%m')), 2) AS arpu,";
    }
    elsif ($attr->{TYPE} eq 'GID') {
      $date = "u.gid";
      $EXT_TABLE_JOINS_HASH{users}=1;
    }
    elsif ($attr->{TYPE} eq 'ADMINS') {
      $date = "a.id AS admin_name";
      $EXT_TABLE_JOINS_HASH{admins}=1;
      $self->{SEARCH_FIELDS} = 'p.aid,';
    }
    elsif ($attr->{TYPE} eq 'COMPANIES') {
      $date       = "company.name AS company_name";
      $self->{SEARCH_FIELDS} = 'u.company_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{companies}=1;
    }
    elsif ($attr->{TYPE} eq 'DISTRICT') {
      $date = "districts.name AS district_name";
      $self->{SEARCH_FIELDS} = 'districts.id AS district_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
      $EXT_TABLE_JOINS_HASH{districts}=1;
    }
    elsif ($attr->{TYPE} eq 'STREET') {
      $date = "streets.name AS street_name";
      $self->{SEARCH_FIELDS} = 'streets.id AS street_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    elsif ($attr->{TYPE} eq 'BUILD') {
      $date = "CONCAT(streets.name, '$CONF->{BUILD_DELIMITER}', builds.number) AS build";
      $self->{SEARCH_FIELDS} = 'builds.id AS location_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    else {
      $date = "u.id AS login";
      $EXT_TABLE_JOINS_HASH{users}=1;
    }
  }
  elsif ($attr->{MONTH}) {
    $date = "DATE_FORMAT(p.date, '%Y-%m-%d') AS date";
  }
  elsif ($attr->{PAYMENT_DAYS}) {
    my $expr = '=';
    if ($attr->{PAYMENT_DAYS} =~ /(<|>)/) {
      $expr = $1;
    }
    #push @WHERE_RULES, "p.date $expr CURDATE() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  }
  else {
    $date = "DATE_FORMAT(p.date, '%Y-%m') AS month";
    $self->{SEARCH_FIELDS}="ROUND(SUM(p.sum) / count(DISTINCT p.uid), 2) AS arppu,
                            ROUND(SUM(p.sum) / (SELECT count(*) FROM users WHERE DATE_FORMAT(registration, '%Y-%m') <= DATE_FORMAT(p.date, '%Y-%m')), 2) AS arpu,";
  }

  if ($attr->{ADMINS}) {
    #push @WHERE_RULES, @{ $self->search_expr($attr->{ADMINS}, 'STR', 'p.aid') };
    #$date = 'a.id AS admin_login';
    $EXT_TABLE_JOINS_HASH{admins}=1;
  }

  if ($admin->{DOMAIN_ID} || $attr->{GID} || $attr->{TAGS} || $self->{SEARCH_FIELDS} =~ /gid/ || $WHERE =~ /u.gid/) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  $EXT_TABLE_JOINS_HASH{users}=1 if ($self->{EXT_TABLES});
  my $EXT_TABLES = $self->mk_ext_tables({ JOIN_TABLES     => \%EXT_TABLE_JOINS_HASH,
                                          EXTRA_PRE_JOIN  => [ 'users:INNER JOIN users u ON (u.uid=p.uid)',
                                                               'admins:LEFT JOIN admins a ON (a.aid=p.aid)'
                                                              ]
                                      });

  $self->query("SELECT $date, count(DISTINCT p.uid) AS login_count, COUNT(*) AS count, SUM(p.sum) AS sum,
    $self->{SEARCH_FIELDS} p.uid
    FROM payments p
      $EXT_TABLES
      $WHERE
      GROUP BY 1
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $total= $self->{TOTAL};
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(DISTINCT p.uid) AS total_users,
      COUNT(*) AS total_operation,
      SUM(p.sum) AS total_sum
    FROM payments p
      $EXT_TABLES
      $WHERE;",
      undef,
      { INFO => 1 }
    );
  }
  else {
    $self->{TOTAL_USERS} = 0;
    $self->{TOTAL_OPERATION} = 0;
    $self->{TOTAL_SUM}   = 0.00;
  }

  $self->{TOTAL}=$total;

  return $list;
}

#**********************************************************
=head2 reports_period_summary($attr) - Payments reports fot periods

=cut
#**********************************************************
sub reports_period_summary {
  my $self = shift;

  my @WHERE_RULES = ();
  my $EXT_TABLE = '';
  if ($admin->{GID}) {
    $admin->{GID}=~s/,/;/g;
    push @WHERE_RULES,  @{ $self->search_expr($admin->{GID}, 'INT', 'u.gid') };
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES,  @{ $self->search_expr($admin->{DOMAIN_ID}, 'INT', 'u.domain_id') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  if($WHERE =~ /u\./) {
    $EXT_TABLE .= "INNER JOIN users u ON (p.uid=u.uid)";
  }

  $self->query("SET default_week_format=1", 'do');

  $self->query("SELECT
       SUM(IF(DATE_FORMAT(date, '%Y-%m-%d')=CURDATE(), 1, 0)) AS day_count,
       SUM(IF(YEAR(CURDATE())=YEAR(p.date) AND WEEK(CURDATE()) = WEEK(p.date), 1, 0)) AS week_count,
       SUM(IF(DATE_FORMAT(p.date, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m'), 1, 0))  AS month_count,

       SUM(IF(DATE_FORMAT(date, '%Y-%m-%d')=CURDATE(), p.sum, 0)) AS day_sum,
       SUM(IF(YEAR(CURDATE())=YEAR(p.date) AND WEEK(CURDATE()) = WEEK(p.date), p.sum, 0)) AS week_sum,
       SUM(IF(DATE_FORMAT(p.date, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m'), p.sum, 0))  AS month_sum
      FROM payments p
      $EXT_TABLE
      $WHERE",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 add_payment_type($attr)

=cut
#**********************************************************
sub payment_type_add {
  my $self = shift;
  my ($attr) = @_;

 $self->query_add('payments_type',$attr);

 return $self;
}

#**********************************************************
=head2 del_payment_type($attr)

=cut
#**********************************************************
sub payment_type_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('payments_type', $attr);

  return $self;
}

#**********************************************************
=head2 payment_type_list($attr)

=cut
#**********************************************************
sub payment_type_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['ID',           'INT',  'pt.id'    ],
      ['NAME',         'STR',  'pt.name'  ],
      ['COLOR',        'STR',  'pt.color' ]
    ],
    { WHERE => 1 });

  $self->query("SELECT pt.id, pt.name, pt.color
    FROM payments_type pt
    $WHERE
    GROUP BY pt.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 payment_type_info($attr)

=cut
#**********************************************************
sub payment_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM payments_type pt WHERE pt.id= ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID}] }
  );

  return $self;
}

#**********************************************************
=head2 payment_type_change($attr)

=cut
#**********************************************************
sub payment_type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'payments_type',
      DATA         => $attr
    }
  );

  return $self;
}

1
