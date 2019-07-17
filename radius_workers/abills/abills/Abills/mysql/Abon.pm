package Abon;

=head1 NAME

  Periodic fess managment functions

=cut

use strict;
our $VERSION = 2.00;
use parent qw( dbcore );
my $MODULE = 'Abon';
my ($admin, $CONF);
my ($SORT, $DESC, $PG, $PAGE_ROWS);

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $admin->{MODULE} = $MODULE;

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head1 del(attr)

=cut
#**********************************************************
sub del{
  my $self = shift;

  $self->query_del( 'abon_user_list', undef, { uid => $self->{UID} } );

  $admin->action_add( $self->{UID}, "$self->{UID}", { TYPE => 10 } );
  return $self->{result};
}

#**********************************************************
=head2 tariff_info($id)

=cut
#**********************************************************
sub tariff_info{
  my $self = shift;
  my ($id) = @_;

  my @WHERE_RULES = ("id='$id'");
  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  $self->query( "SELECT * FROM abon_tariffs
   $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 tariff_add($attr)

=cut
#**********************************************************
sub tariff_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'abon_tariffs', { %{$attr},
      DOMAIN_ID => $admin->{DOMAIN_ID} || 0
    } );

  return [ ] if ($self->{errno});
  $admin->system_action_add( "ABON_ID:$attr->{ID}", { TYPE => 1 } );
  return $self;
}

#**********************************************************
=head2 tariff_change($attr)

=cut
#**********************************************************
sub tariff_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{CREATE_ACCOUNT} = 0 if (!$attr->{CREATE_ACCOUNT});
  $attr->{FEES_TYPE} = 0 if (!$attr->{FEES_TYPE});
  $attr->{NOTIFICATION_ACCOUNT} = 0 if (!$attr->{NOTIFICATION_ACCOUNT});
  $attr->{ALERT} = 0 if (!$attr->{ALERT});
  $attr->{ALERT_ACCOUNT} = 0 if (!$attr->{ALERT_ACCOUNT});
  $attr->{PERIOD_ALIGNMENT} = 0 if (!$attr->{PERIOD_ALIGNMENT});
  $attr->{ACTIVATE_NOTIFICATION} = 0 if (!$attr->{ACTIVATE_NOTIFICATION});
  $attr->{VAT} = 0 if (!$attr->{VAT});
  $attr->{NONFIX_PERIOD} = 0 if (!$attr->{NONFIX_PERIOD});
  $attr->{DISCOUNT} = 0 if (!$attr->{DISCOUNT});
  $attr->{EXT_BILL_ACCOUNT} = 0 if (!$attr->{EXT_BILL_ACCOUNT});
  $attr->{USER_PORTAL} = 0 if (!$attr->{USER_PORTAL});
  $attr->{MANUAL_ACTIVATE} = 0 if (!$attr->{MANUAL_ACTIVATE});

  $attr->{ID} = $attr->{ABON_ID};

  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'abon_tariffs',
      DATA            => $attr,
      EXT_CHANGE_INFO => "ABON_ID:$attr->{ABON_ID}"
    }
  );

  $self->tariff_info( $attr->{ABON_ID} );
  return $self->{result};
}

#**********************************************************
=head2 tariff_del($id)

=cut
#**********************************************************
sub tariff_del{
  my $self = shift;
  my ($id) = @_;

  $self->query_del( 'abon_tariffs', { ID => $id } );

  $admin->system_action_add( "ABON_ID:$id", { TYPE => 10 } );
  return $self->{result};
}

#**********************************************************
=head2 tariff_list($attr)

=cut
#**********************************************************
sub tariff_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? int( $attr->{PAGE_ROWS} ) : 25;

  my $WHERE = $self->search_former( $attr, [
      [ 'IDS',              'INT', 'abon_tariffs.id'          ],
      [ 'EXT_BILL_ACCOUNT', 'INT', 'ext_bill_account',      1 ],
      [ 'DOMAIN_ID',        'INT', 'abon_tariffs.domain_id',  ],
    ],
    { WHERE => 1,
    }
  );

  $self->query( "SELECT name, price, period, payment_type,
     priority,
     period_alignment,
     COUNT(ul.uid) AS user_count,
     abon_tariffs.id AS tp_id,
     fees_type,
     create_account,
     ext_cmd,
     activate_notification,
     vat,
     description,
     abon_tariffs.discount,
     manual_activate,
     user_portal,
     $self->{SEARCH_FIELDS}
     \@nextfees_date := if (nonfix_period = 1,
      if (period = 0, curdate() + INTERVAL 2 DAY,
       if (period = 1, curdate() + INTERVAL 2 MONTH,
         if (period = 2, curdate() + INTERVAL 6 MONTH,
           if (period = 3, curdate() + INTERVAL 12 MONTH,
             if (period = 4, curdate() + INTERVAL 2 YEAR,
               '-'
              )
            )
          )
        )
       ),
      if (period = 0, CURDATE()+ INTERVAL 1 DAY,
       if (period = 1, DATE_FORMAT(curdate() + INTERVAL 2 MONTH, '%Y-%m-01'),
         if (period = 2, CONCAT(YEAR(curdate() + INTERVAL 6 MONTH), '-' ,(QUARTER((curdate() + INTERVAL 6 MONTH))*6-2), '-01'),
           if (period = 3, CONCAT(YEAR(curdate() + INTERVAL 12 MONTH), '-', if(MONTH(curdate() + INTERVAL 12 MONTH) > 12, '06', '01'), '-01'),
             if (period = 4, DATE_FORMAT(curdate() + INTERVAL 2 YEAR, '%Y-01-01'),
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon_date
     FROM abon_tariffs
     LEFT JOIN abon_user_list ul ON (abon_tariffs.id=ul.tp_id)
     $WHERE
     GROUP BY abon_tariffs.id
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.uid=ul.uid", "at.id=ul.tp_id");
  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former( $attr, [
      [ 'FIO',        'STR', 'pi.fio',         ],
      [ 'ABON_ID',    'INT', 'at.id',          ],
      [ 'TP_ID',      'INT', 'ul.tp_id',       ],
      [ 'COMMENTS',   'STR', 'ul.comments',    ],
      [ 'LAST_ABON',  'INT', 'ul.date',        ],
      [ 'FEES_PERIOD','INT', 'ul.fees_period', ],
      [ 'MANUAL_FEE', 'INT', 'ul.manual_fee',  ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'FIO' , 'COMMENTS']
    }
  );

  #my $EXT_TABLE = ($self->{EXT_TABLES}) ? $self->{EXT_TABLES} : q{};

  $self->query( "SELECT u.id AS login, pi.fio, at.name AS tp_name, ul.comments, at.price,
     ul.service_count,
     at.period,
     ul.date,
     if (at.nonfix_period = 1,
      if (at.period = 0, ul.date+ INTERVAL 1 DAY,
       if (at.period = 1, ul.date + INTERVAL 1 MONTH,
         if (at.period = 2, ul.date + INTERVAL 3 MONTH,
           if (at.period = 3, ul.date + INTERVAL 6 MONTH,
             if (at.period = 4, ul.date + INTERVAL 1 YEAR,
               '-'
              )
            )
          )
        )
       )
      ,

      if (at.period = 0, ul.date+ INTERVAL 1 DAY,
       if (at.period = 1, DATE_FORMAT(ul.date + INTERVAL 1 MONTH, '%Y-%m-01'),
         if (at.period = 2, CONCAT(YEAR(ul.date + INTERVAL 3 MONTH), '-' ,(QUARTER((ul.date + INTERVAL 3 MONTH))*3-2), '-01'),
           if (at.period = 3, CONCAT(YEAR(ul.date + INTERVAL 6 MONTH), '-', if(MONTH(ul.date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'),
             if (at.period = 4, DATE_FORMAT(ul.date + INTERVAL 1 YEAR, '%Y-01-01'),
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon,
     ul.manual_fee,
     u.uid,
     at.id AS tp_id
     FROM (users u, abon_user_list ul, abon_tariffs at)
     LEFT JOIN users_pi pi ON u.uid = pi.uid
     $WHERE
     GROUP BY ul.uid, ul.tp_id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );
  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 ){
    $self->query( "SELECT COUNT(u.uid) AS total
     FROM (users u, abon_user_list ul, abon_tariffs at)
     $WHERE", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2  user_tariff_list($uid, $attr)

=cut
#**********************************************************
sub user_tariff_list{
  my $self = shift;
  my ($uid, $attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, "at.domain_id='$admin->{DOMAIN_ID}'";
  }

  if ( $attr->{ACTIVE_ONLY} ){
    push @WHERE_RULES, "ul.uid>0";
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'USER_PORTAL',  'INT', 'at.user_portal',  1 ],
      [ 'PAYMENT_TYPE', 'INT', 'at.payment_type', 1 ],
      [ 'SERVICE_LINK', 'STR', 'at.service_link', 1 ],
      [ 'FEES_PERIOD',  'INT', 'at.fees_period',  1 ],
      [ 'UID',          'INT', 'ul.uid',          1 ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query( "SELECT at.id,
      at.name,
      IF(ul.comments <> '', ul.comments, '') AS comments,
      at.price,
      at.period,
      at.description,
      SUM(ul.service_count) AS service_count,
      ul.fees_period,
      MAX(ul.date) AS date,
      IF (at.nonfix_period = 1,
      IF (at.period = 0, ul.date+ INTERVAL 1 DAY,
       IF (at.period = 1, ul.date + INTERVAL 1 MONTH,
         IF (at.period = 2, ul.date + INTERVAL 3 MONTH,
           IF (at.period = 3, ul.date + INTERVAL 6 MONTH,
             IF (at.period = 4, ul.date + INTERVAL 1 YEAR,
               '-'
              )
            )
          )
        )
       ),
      \@next_abon := if (at.period = 0, ul.date+ INTERVAL 1 DAY,
       IF (at.period = 1, DATE_FORMAT(ul.date + INTERVAL 1 MONTH, '%Y-%m-01'),
         IF (at.period = 2, CONCAT(YEAR(ul.date + INTERVAL 3 MONTH), '-' ,(QUARTER((ul.date + INTERVAL 3 MONTH))*3-2), '-01'),
           IF (at.period = 3, CONCAT(YEAR(ul.date + INTERVAL 6 MONTH), '-', if(MONTH(ul.date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'),
             IF (at.period = 4, DATE_FORMAT(ul.date + INTERVAL 1 YEAR, '%Y-01-01'),
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon,
   ul.manual_fee,
   MAX(ul.discount) AS discount,
   COUNT(ul.uid) AS active_service,
   ul.notification1,
   ul.notification1_account_id,
   ul.notification2,
   ul.create_docs,
   ul.send_docs,
   at.manual_activate,
   $self->{SEARCH_FIELDS}
   IF (\@next_abon < CURDATE(), 1, 0) AS missing
     FROM abon_tariffs at
     LEFT JOIN abon_user_list ul ON (at.id=ul.tp_id AND ul.uid='$uid')
     $WHERE
     GROUP BY at.id
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 user_tariff_change($attr)

=cut
#**********************************************************
sub user_tariff_summary{
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former( $attr, [
      [ 'UID', 'INT', 'uid', 1 ],
    ],
    { WHERE => 1
    }
  );

  $self->query( "SELECT COUNT(*) AS total_active FROM abon_user_list $WHERE;",
    undef,
    { INFO => 1 } );

  return $self;
}

#**********************************************************
=head1 user_tariff_change()

  Attributes:
    $attr
       CHANGE_INFO
       ACTIVATE
       DEL         - Del service

=cut
#**********************************************************
sub user_tariff_change{
  my $self = shift;
  my ($attr) = @_;

  my $abon_add = '';
  my $abon_del = '';

  $admin->{MODULE} = $MODULE;


  if ( $attr->{CHANGE_INFO} ){
    $self->query( "UPDATE abon_user_list SET
      comments= ? ,
      discount= ? ,
      create_docs= ? ,
      send_docs= ? ,
      service_count= ? ,
      manual_fee= ? ,
      fees_period= ?
      WHERE uid= ? AND tp_id= ? ;
      ", 'do',
      { Bind => [
          ($attr->{COMMENTS} || ''),
          $attr->{DISCOUNT},
          $attr->{CREATE_DOCS},
          $attr->{SEND_DOCS},
          $attr->{SERVICE_COUNT},
          $attr->{MANUAL_FEE},
          $attr->{FEES_PERIOD},
          $attr->{UID},
          $attr->{TP_ID}
        ] } );

    $admin->action_add( $attr->{UID}, "",
      { TYPE => 3,
        INFO    => ['COMMENTS', 'DISCOUNT', 'CREATE_DOCS', 'SEND_DOCS', 'SERVICE_COUNT', 'MANUAL_FEE', 'TP_ID', 'FEES_PERIOD'],
        REQUEST => $attr
      });

    return $self;
  }
  elsif ( $attr->{ACTIVATE} ){
    $self->query( "UPDATE abon_user_list SET
      date= ?
      WHERE uid= ? AND tp_id= ? ;",
      'do',
      { Bind => [
        $attr->{ABON_DATE},
        $attr->{UID},
        $attr->{ACTIVATE} ]
      } );
    return 0;
  }
  elsif ( $attr->{DEL} ){
    $self->query( "DELETE FROM abon_user_list WHERE uid= ? AND tp_id IN ( $attr->{DEL} );",
      'do',
      { Bind => [ $attr->{UID} ] } );
    $abon_del = $attr->{DEL};
  }

  my @tp_array = split( /, /, $attr->{IDS} );

  foreach my $tp_id ( @tp_array ){
    my $date = '';

    if ( $attr->{ 'DATE_' . $tp_id } && $attr->{ 'DATE_' . $tp_id } ne '0000-00-00' && $attr->{ 'PERIOD_' . $tp_id } ){
      $date = "
      if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 0, '" . $attr->{ 'DATE_' . $tp_id } . "' -  INTERVAL 1 DAY,
       if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 1, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 1 MONTH,
         if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 2, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 3 MONTH,
           if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 3, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 6 MONTH,
             if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 4, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 1 YEAR,
               CURDATE()
              )
            )
          )
        )
       )";
    }
    elsif ( $attr->{ 'DATE_' . $tp_id } && $attr->{ 'DATE_' . $tp_id } ne '0000-00-00' ){
      $date = $attr->{ 'DATE_' . $tp_id };
    }
    else{
      $date = 'CURDATE()';
    }

    $self->query( "INSERT INTO abon_user_list SET
       uid = ?,
       tp_id = ?,
       comments = ?,
       date = $date,
       discount = ?,
       create_docs = ?,
       send_docs = ?,
       service_count = ?,
       fees_period = ?,
       manual_fee = ?;",
       'do',
      { Bind => [
          $attr->{UID},
          $tp_id,
          ($attr->{ 'COMMENTS_' . $tp_id } || ''),
          $attr->{'DISCOUNT_' . $tp_id } || 0,
          $attr->{'CREATE_DOCS_' . $tp_id } || 0,
          $attr->{'SEND_DOCS_' . $tp_id } || 0,
          $attr->{'SERVICE_COUNT_' . $tp_id} || 1,
          $attr->{'FEES_PERIOD_' . $tp_id} || 0,
          $attr->{'MANUAL_FEE_' . $tp_id } || 0
        ]
      }
    );
    $abon_add .= "$tp_id, ";
  }

  $admin->{MODULE} = $MODULE;
  my $action_info = q{};

  if($abon_add) {
    $action_info .= "ADD:$abon_add";
  }
  if($abon_del) {
    $action_info .= "DEL:$abon_del";
  }

  if($action_info) {
    $admin->action_add($attr->{UID}, $action_info, { TYPE => 3 });
  }
  return $self;
}

#**********************************************************
=head2 user_tariffs()

=cut
#**********************************************************
sub user_tariff_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'abon_user_list', undef, {
    uid   => $attr->{UID},
    tp_id => ($attr->{TP_IDS}) ? $attr->{TP_IDS} : $attr->{TP_ID}
  } );

  $admin->action_add( $attr->{UID}, "$attr->{TP_IDS}", { TYPE => 10 } );
  return $self;
}

#**********************************************************
=head2 user_tariff_update($attr)

=cut
#**********************************************************
sub user_tariff_update{
  my $self = shift;
  my ($attr) = @_;

  $attr->{DATE} = "NOW()" if (! $attr->{DATE});

#  $self->query( "UPDATE abon_user_list SET
#      date= ? ,
#      notification1= ?,
#      notification1_account_id= ?,
#      notification2= ?
#      WHERE uid= ? and tp_id= ? ;",
#    'do',
#    { Bind => [
#        $DATE,
#          ($attr->{NOTIFICATION} && $attr->{NOTIFICATION} == 1) ? $DATE : '0000-00-00',
#          ($attr->{NOTIFICATION} && $attr->{NOTIFICATION} == 1) ? $attr->{NOTIFICATION_ACCOUNT_ID} : 0,
#          ($attr->{NOTIFICATION} && $attr->{NOTIFICATION} == 2) ? $DATE : '0000-00-00',
#        $attr->{UID},
#        $attr->{TP_ID}
#      ] }
#  );

  if ($attr->{NOTIFICATION} && $attr->{NOTIFICATION} == 1)  {
    $attr->{NOTIFICATION1} = $attr->{DATE};
    $attr->{NOTIFICATION_ACCOUNT_ID} = 1;
    delete $attr->{DATE};
  }

  if ($attr->{NOTIFICATION} && $attr->{NOTIFICATION} == 2) {
    $attr->{NOTIFICATION2} = $attr->{DATE};
    delete $attr->{DATE};
  }

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'UID,TP_ID',
      TABLE        => 'abon_user_list',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 periodic_list($attr)

=cut
#**********************************************************
sub periodic_list{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLES = '';

  my $WHERE = $self->search_former( $attr, [
      [ 'LOGIN',        'STR', 'u.id  ',           ],
      [ 'TP_ID',        'INT', 'ul.tp_id',         ],
      [ 'DELETED',      'INT', 'u.deleted',      1 ],
      [ 'LOGIN_STATUS', 'INT', 'u.disable',      1 ],
      [ 'MANUAL_FEE',   'INT', 'ul.manual_fee',  1 ],
      [ 'LAST_DEPOSIT', 'INT', 'f.last_deposit', 1 ],
      [ 'FEES_PERIOD',  'INT', 'ul.fees_period', 1 ],
      [ 'UID',          'INT', 'u.uid',          1 ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $EXT_TABLES .= $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  if ( $CONF->{EXT_BILL_ACCOUNT} ){
    $EXT_TABLES = " LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
     LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id)";
    $self->{SEARCH_FIELDS} .= 'IF(company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS ext_deposit,';
  }

  $self->query( "SELECT at.period, at.price, u.uid,
  if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
  u.id AS login,
  at.id AS tp_id,
  at.name AS tp_name,
  IF(company.name IS NULL, b.deposit, cb.deposit) AS deposit,
  IF(u.credit, u.credit,
    IF (company.credit <> 0, company.credit, 0) ) AS credit,
  u.disable,
  at.payment_type,
  ul.comments,
  \@last_fees_date := IF(ul.date='0000-00-00', CURDATE(), ul.date),
  \@fees_date := if (at.nonfix_period = 1,
      IF (at.period = 0, \@last_fees_date+ INTERVAL 1 DAY,
       IF (at.period = 1, \@last_fees_date + INTERVAL 1 MONTH,
         if (at.period = 2, \@last_fees_date + INTERVAL 3 MONTH,
           IF (at.period = 3, \@last_fees_date + INTERVAL 6 MONTH,
             IF (at.period = 4, \@last_fees_date + INTERVAL 1 YEAR,
               '-'
              )
            )
          )
        )
       ),
      IF (at.period = 0, \@last_fees_date + INTERVAL 1 DAY,
       IF (at.period = 1, DATE_FORMAT(\@last_fees_date + INTERVAL 1 MONTH, '%Y-%m-01'),
         IF (at.period = 2, CONCAT(YEAR(\@last_fees_date + INTERVAL 3 MONTH), '-' ,(QUARTER((\@last_fees_date + INTERVAL 3 MONTH))*3-2), '-01'),
           IF (at.period = 3, CONCAT(YEAR(\@last_fees_date + INTERVAL 6 MONTH), '-', if(MONTH(\@last_fees_date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'),
             IF (at.period = 4, DATE_FORMAT(\@last_fees_date + INTERVAL 1 YEAR, '%Y-01-01'),
               '-'
              )
            )
          )
        )
       )
      ) AS abon_date,
   at.ext_bill_account,
   IF(u.company_id > 0, company.ext_bill_id, u.ext_bill_id) AS ext_bill_id,
   at.priority,

   fees_type,
   create_account,
   IF (at.notification1>0, \@fees_date - interval at.notification1 day, '0000-00-00') AS notification1,
   IF (at.notification2>0, \@fees_date - interval at.notification2 day, '0000-00-00') AS notification2,
   at.notification_account,
   IF (at.alert > 0, \@fees_date, '0000-00-00'),
   at.alert_account,
   pi.email,
   ul.notification1_account_id,
   at.ext_cmd,
   at.activate_notification,
   at.vat,
   \@nextfees_date := if (at.nonfix_period = 1,
      IF (at.period = 0, \@last_fees_date+ INTERVAL 2 DAY,
       IF (at.period = 1, \@last_fees_date + INTERVAL 2 MONTH,
         if (at.period = 2, \@last_fees_date + INTERVAL 6 MONTH,
           IF (at.period = 3, \@last_fees_date + INTERVAL 12 MONTH,
             IF (at.period = 4, \@last_fees_date + INTERVAL 2 YEAR,
               '-'
              )
            )
          )
        )
       ),
      IF (at.period = 0, \@last_fees_date+ INTERVAL 1 DAY,
       IF (at.period = 1, DATE_FORMAT(\@last_fees_date + INTERVAL 2 MONTH, '%Y-%m-01'),
         IF (at.period = 2, CONCAT(YEAR(\@last_fees_date + INTERVAL 6 MONTH), '-' ,(QUARTER((\@last_fees_date + INTERVAL 6 MONTH))*6-2), '-01'),
           IF (at.period = 3, CONCAT(YEAR(\@last_fees_date + INTERVAL 12 MONTH), '-', if(MONTH(\@last_fees_date + INTERVAL 12 MONTH) > 12, '06', '01'), '-01'),
             IF (at.period = 4, DATE_FORMAT(\@last_fees_date + INTERVAL 2 YEAR, '%Y-01-01'),
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon_date,
    IF(ul.discount>0, ul.discount,
    IF(at.discount=1, u.reduction, 0)) AS discount,
    ul.create_docs,
    ul.send_docs,
    ul.service_count,
    $self->{SEARCH_FIELDS}
    ul.manual_fee
  FROM abon_tariffs at
     INNER JOIN abon_user_list ul ON (at.id=ul.tp_id)
     INNER JOIN users u ON (ul.uid=u.uid)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN companies company ON (u.company_id=company.id)
     LEFT JOIN bills cb ON (company.bill_id=cb.id)
     LEFT JOIN users_pi pi ON (pi.uid=u.uid)
     $EXT_TABLES
$WHERE
ORDER BY at.priority;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 subscribe_add($uid, $abon_tp_id) - TODO

  Arguments:
     $uid        - user ID
     $abon_tp_id - subscription identifier

  Returns:
    1 - if successfuly added subscription for user

=cut
#**********************************************************
sub subscribe_add {
  my $self = shift;
  my ($uid, $abon_tp_id) = @_;
  return 0 unless ($uid && $abon_tp_id);

  # TODO: add subscription

  return 1;
}

#**********************************************************
=head2 subscribe_del($uid, $abon_tp_id)() - TODO

  Arguments:
     $uid        - user ID
     $abon_tp_id - subscription identifier

  Returns:
    1 - if successfuly deleted user subscribe

=cut
#**********************************************************
sub subscribe_del {
  my $self = shift;
  my ($uid, $abon_tp_id ) =  @_;
  return 0 unless ($uid && $abon_tp_id);

  # TODO: delete subscription

  return 1;
}

1
