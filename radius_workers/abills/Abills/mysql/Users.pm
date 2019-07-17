package Users;

=head1 NAME

  Users manage functions

=cut

use strict;
use parent 'main';
use Conf;
use Attach;

my $admin;
my $CONF;
my $SORT = 1;
my $DESC = '';
my $PG   = 1;
my $PAGE_ROWS = 25;

my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$";    # configurable;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db)  = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = '';
  $CONF->{MAX_USERNAME_LENGTH} = 10 if (!defined($CONF->{MAX_USERNAME_LENGTH}));
  $CONF->{BUILD_DELIMITER} = ',' if (! defined($CONF->{BUILD_DELIMITER})) ;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  if (defined($CONF->{USERNAMEREGEXP})) {
    $usernameregexp = $CONF->{USERNAMEREGEXP};
  }

  return $self;
}

#**********************************************************
=head2 info($uid, $attr) - Account general information

  Argumenst:
    $uid
    $attr

  Returns:
    Object

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  if (!$attr->{USERS_AUTH} && ! $self->check_params()) {
    return $self;
  }

  my $WHERE='';

  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}' and DECODE(u.password, '$self->{conf}->{secretkey}')='$attr->{PASSWORD}'";
    if (defined($attr->{ACTIVATE})) {
      my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
      $WHERE .= " and u.activate$value";
    }

    if (defined($attr->{EXPIRE})) {
      my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
      $WHERE .= " and u.expire$value";
    }

    if (defined($attr->{DISABLE})) {
      $WHERE .= " and u.disable='$attr->{DISABLE}'";
    }
  }
  elsif ($attr->{LOGIN}) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}'";
  }
  else {
    $WHERE = "WHERE u.uid='$uid'";
  }

  if ($attr->{DOMAIN_ID}) {
    $WHERE .= "AND u.domain_id='$attr->{DOMAIN_ID}'";
  }

  my $password = "''";
  if ($attr->{SHOW_PASSWORD}) {
    $password = "DECODE(u.password, '$self->{conf}->{secretkey}') AS password";
  }

  $self->query2("SELECT u.uid,
   u.gid,
   g.name AS g_name,
   u.id AS login,
   u.activate,
   u.expire,
   u.credit,
   u.reduction,
   u.registration,
   u.disable,
   if(u.company_id > 0, cb.id, b.id) AS bill_id,
   if(c.name IS NULL, b.deposit, cb.deposit) AS deposit,
   u.company_id,
   if(c.name IS NULL, '', c.name) AS company_name,
   if(c.name IS NULL, 0, c.vat) AS company_vat,
   if(c.name IS NULL, b.uid, cb.uid) AS bill_owner,
   if(u.company_id > 0, c.ext_bill_id, u.ext_bill_id) AS ext_bill_id,
   u.credit_date,
   u.reduction_date,
   if(c.name IS NULL, 0, c.credit) AS company_credit,
   u.domain_id,
   u.deleted,
   $password
     FROM users u
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     $WHERE;",
   undef,
   { INFO => 1 }
  );

  if ((!$admin->{permissions}->{0} || !$admin->{permissions}->{0}->{8}) && ($self->{DELETED})) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ($self->{conf}->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} && $self->{EXT_BILL_ID} > 0) {
    $self->query2("SELECT b.deposit AS ext_bill_deposit, b.uid AS ext_bill_owner
     FROM bills b WHERE id= ? ;",
     undef,
     { INFO => 1,
       Bind => [ $self->{EXT_BILL_ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 pi_add($attr)

=cut
#**********************************************************
sub pi_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{EMAIL} && $attr->{EMAIL} ne '') {
    if ($attr->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno}  = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  $self->info_field_attach_add($attr);
  $attr->{CONTRACT_SUFIX} = $attr->{CONTRACT_TYPE};
  if ($attr->{CONTRACT_TYPE}) {
    my (undef, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX}=$sufix || $attr->{CONTRACT_TYPE};
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && ! $attr->{LOCATION_ID}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $admin, $self->{conf});

    $Address->build_add($attr);
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  $self->query_add('users_pi', { %$attr });

  return [ ] if ($self->{errno});

  $admin->action_add("$attr->{UID}", "PI", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 pi($attr) Personal inforamtion

  Arguments:
    $attr
      UID

  Returns:
    $self

=cut
#**********************************************************
sub pi {
  my $self = shift;
  my ($attr) = @_;

  my $uid = ($attr->{UID}) ? $attr->{UID} : $self->{UID};

  $self->query2("SELECT pi.*
    FROM users_pi pi
    WHERE pi.uid= ? ;",
  undef,
  { INFO => 1,
  	Bind => [ $uid ] }
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if (! $self->{errno} && $self->{LOCATION_ID}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $admin, $self->{conf});

    $Address->address_info($self->{LOCATION_ID});

    $self->{DISTRICT_ID}      = $Address->{DISTRICT_ID};
    $self->{CITY}             = $Address->{CITY};
    $self->{ADDRESS_DISTRICT} = $Address->{ADDRESS_DISTRICT};
    $self->{STREET_ID}        = $Address->{STREET_ID};
    $self->{ZIP}              = $Address->{ZIP};
    $self->{COORDX}           = $Address->{COORDX};

    $self->{ADDRESS_STREET}   = $Address->{ADDRESS_STREET};
    $self->{ADDRESS_STREET2}  = $Address->{ADDRESS_STREET2};
    $self->{ADDRESS_BUILD}    = $Address->{ADDRESS_BUILD};
  }
  
  if (! $self->{errno} && $self->{conf}{CONTACTS_NEW} ){
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($self->{db}, $admin, $self->{conf});
        
    my $phone_type_id = $Contacts->contact_type_id_for_name('PHONE');
    my $email_type_id = $Contacts->contact_type_id_for_name('EMAIL');
    my $contacts = $Contacts->contacts_list({
      UID       => $uid,
      VALUE     => '_SHOW',
      TYPE      => $phone_type_id . ';' . $email_type_id,
      COLS_NAME => 1
    });
    
    if (!$Contacts->{errno} && $contacts && ref $contacts){
      my @phones = grep { $_->{type_id} == $phone_type_id } @{$contacts};
      my @emails = grep { $_->{type_id} == $email_type_id } @{$contacts};
      
      $self->{PHONE} = join(', ', map {$_->{value} } @phones);
      $self->{EMAIL} = join(', ', map {$_->{value} } @emails);
      
      $self->{CONTACTS_NEW_APPENDED} = 1;
    }
  }

  $self->{ADDRESS_FULL}="$self->{ADDRESS_STREET} $self->{ADDRESS_BUILD}$self->{conf}->{BUILD_DELIMITER} $self->{ADDRESS_FLAT}";
  $self->{TOTAL}=1;

  return $self;
}


#**********************************************************
=head2 pi_change($attr) - Personal Info change

  Arguments:
    $attr
      UID   - Main id

  Resturns:
    $self

=cut
#**********************************************************
sub pi_change {
  my $self = shift;
  my ($attr) = @_;

  if($attr->{PHONE} && $CONF->{PHONE_FORMAT}){
    if ($attr->{PHONE} !~ /$CONF->{PHONE_FORMAT}/) {
      $self->{errno}=21;
      $self->{errstr}='Wrong phone';
      return $self;
    }
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $admin, $self->{conf});
    $Address->build_add($attr);
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  if (!$attr->{SKIP_INFO_FIELDS}) {
    $self->info_field_attach_add($attr);
    if($self->{errno}) {

      return $self;
    }
  }

  $attr->{CONTRACT_SUFIX} = $attr->{CONTRACT_TYPE};
  if ($attr->{CONTRACT_TYPE}) {
    my (undef, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $admin->{MODULE} = '';
  
  if ($self->{conf}{CONTACTS_NEW} && ($attr->{PHONE} || $attr->{EMAIL})){
    # TODO split and insert to users contacts
  }

  $self->changes2({
    CHANGE_PARAM => 'UID',
    TABLE        => 'users_pi',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 groups_list($attr) - List of groups

=cut
#**********************************************************
sub groups_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES = ();

  # Show groups
  if ($attr->{GIDS}) {
    if ($admin->{GIDS}) {
      my @result_gids = ();
      my @admin_gids  = split(/, /, $admin->{GIDS});
      my @attr_gids   = split(/, /, $attr->{GIDS});

      foreach my $attr_gid ( @attr_gids ) {
        foreach my $admin_gid (@admin_gids)  {
          if ($admin_gid == $attr_gid) {
            push @result_gids, $attr_gid;
            last;
          }
        }
      }

      $attr->{GIDS}=join(', ', @result_gids);
    }

    push @WHERE_RULES, "g.gid IN ($attr->{GIDS})";
  }
  elsif (defined($attr->{GID}) && $attr->{GID} =~ /\d+/) {
    $attr->{GID} =~ s/,/;/g;
    push @WHERE_RULES,  @{ $self->search_expr($attr->{GID}, 'INT', 'g.gid') };
  }
  elsif ($admin->{GIDS}) {
    push @WHERE_RULES, "g.gid IN ($admin->{GIDS})";
  }

  my $USERS_WHERE = '';
  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr( $admin->{DOMAIN_ID}, 'INT', 'g.domain_id' ) };
    $USERS_WHERE = "AND ". join('AND', @{ $self->search_expr( $admin->{DOMAIN_ID}, 'INT', 'u.domain_id' ) });
  }

  my $WHERE = $self->search_former($attr, [
      ['BONUS',     'INT', 'g.bonus',      1 ],
      ['DOMAIN_ID', 'INT', 'g.domain_id',  1 ]
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  #my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT g.gid, g.name, g.descr, COUNT(u.uid) AS users_count, g.allow_credit,
        g.disable_paysys,
        g.disable_chg_tp,
        $self->{SEARCH_FIELDS}
        g.domain_id
        FROM groups g
        LEFT JOIN users u ON  (u.gid=g.gid $USERS_WHERE)
        $WHERE
        GROUP BY g.gid
        ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT COUNT(*) AS total FROM groups g $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 group_info($gid)

=cut
#**********************************************************
sub group_info {
  my $self = shift;
  my ($gid) = @_;

  $self->query2("SELECT * FROM groups g WHERE g.gid= ? ;",
   undef,
   { INFO => 1,
     Bind => [ $gid ]   });

  return $self;
}

#**********************************************************
=head2 group_change($gid, $attr)

=cut
#**********************************************************
sub group_change {
  my $self = shift;
  my ($gid, $attr) = @_;

  $attr->{SEPARATE_DOCS} = ($attr->{SEPARATE_DOCS}) ? 1 : 0;
  $attr->{ALLOW_CREDIT}  = ($attr->{ALLOW_CREDIT}) ? 1 : 0;
  $attr->{DISABLE_PAYSYS}= ($attr->{DISABLE_PAYSYS}) ? 1 : 0;
  $attr->{DISABLE_CHG_TP}= ($attr->{DISABLE_CHG_TP}) ? 1 : 0;
  $attr->{BONUS}         = ($attr->{BONUS}) ? 1 : 0;

  $self->changes2(
    {
      CHANGE_PARAM    => 'GID',
      TABLE           => 'groups',
      DATA            => $attr,
      EXT_CHANGE_INFO => "GID:$gid"
    }
  );

  return $self;
}

#**********************************************************
=head2 group_add($attr)

=cut
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('groups', { %$attr, DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} });

  $admin->system_action_add("GID:$attr->{GID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 group_add($id)

=cut
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('groups', undef, { gid=> $id });

  $admin->system_action_add("GID:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 list($attr) - List users

  Arguments:
    $attr

  Returns
    array_of_hash

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  if ($attr->{UNIVERSAL_SEARCH}) {
    $attr->{SKIP_DEL_CHECK}=1;
  }

  my @ext_fields = (
    'FIO',
    'DEPOSIT',
    'EXT_DEPOSIT',
    'CREDIT',
    'CREDIT_DATE',
    'LOGIN_STATUS',
    'PHONE',
    'EMAIL',
    'ADDRESS_FLAT',
    'PASPORT_DATE',
    'PASPORT_NUM',
    'PASPORT_GRANT',
    'CITY',
    'ZIP',
    'GID',
    'COMPANY_ID',
    'CONTRACT_ID',
    'CONTRACT_SUFIX',
    'CONTRACT_DATE',
    'EXPIRE',
    'REDUCTION',
    'LAST_PAYMENT',
    'REGISTRATION',
    'REDUCTION_DATE',
    'COMMENTS',
    'BILL_ID',
    'ACTIVATE',
    'EXPIRE',
    'ACCEPT_RULES',
    'DOMAIN_ID',
    'UID',
    'PASSWORD'
  );

  push @WHERE_RULES, @{ $self->search_expr_users({ %$attr,
    EXT_FIELDS  => \@ext_fields,
    USE_USER_PI => 1,
    SKIP_GID    => ($admin->{GID} && $attr->{_MULTI_HIT}) ? 1 : undef
  }) };

  # Show debeters
  if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "b.deposit<0";
  }

  if (defined($attr->{DISABLE}) && $attr->{DISABLE} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DISABLE}, 'INT', 'u.disable') };
  }

  if ($attr->{ACTIVE}) {
    push @WHERE_RULES, "(u.expire = '0000-00-00' OR u.expire>CURDATE()) AND u.credit + if(company.id IS NULL, b.deposit, cb.deposit) > 0 AND u.disable=0 ";
  }

  my $EXT_TABLES = $self->{EXT_TABLES};

  if ($attr->{PAID}) {
    push @WHERE_RULES, "u.uid IN ( SELECT p2.uid FROM payments p2 WHERE p2.date >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00') GROUP BY p2.uid)";
  }

  if ($attr->{UNPAID}) {
    $EXT_TABLES .= "LEFT JOIN payments p ON (p.uid=u.uid && p.date > DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00'))";
    push @WHERE_RULES, "p.date IS NULL";
  }
  #Show last paymenst
  if ($attr->{PAYMENTS} || $attr->{PAYMENT_DAYS}) {
    my @HAVING_RULES = @WHERE_RULES;

    if ($attr->{PAYMENTS}) {
      my $value = @{ $self->search_expr($attr->{PAYMENTS}, 'INT') }[0];
      push @WHERE_RULES,  "p.date$value";
      push @HAVING_RULES, "MAX(p.date)$value";
      $self->{SEARCH_FIELDS} .= 'MAX(p.date) AS last_payments, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }
    elsif ($attr->{PAYMENT_DAYS}) {
      my $value = "NOW() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;

      push @WHERE_RULES,  "p.date$value";
      push @HAVING_RULES, "MAX(p.date)$value";
      $self->{SEARCH_FIELDS} .= 'MAX(p.date) AS last_payments, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }

    my $HAVING = ($#HAVING_RULES > -1) ? "HAVING " . join(' AND ', @HAVING_RULES) : '';
    $self->query2("SELECT u.id AS login,
       $self->{SEARCH_FIELDS}
       u.uid,
       u.company_id,
       pi.email,
       u.activate,
       u.expire,
       u.gid,
       b.deposit,
       u.domain_id,
       u.deleted
     FROM users u
     LEFT JOIN payments p ON (u.uid = p.uid)

     $EXT_TABLES
     GROUP BY u.uid
     $HAVING
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );
    return [ ] if ($self->{errno});

    my $list = $self->{list};

    # Totas Records
    if ($self->{TOTAL} > 0) {
      if ($attr->{PAYMENT}) {
        $WHERE_RULES[$#WHERE_RULES] = @{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'p.date') };
      }
      elsif ($attr->{PAYMENT_DAYS}) {
        my $value = "CURDATE() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
        $value =~ s/([<>=]{1,2})//g;
        $value = $1 . $value;
        $WHERE_RULES[$#WHERE_RULES] = "p.date$value";
      }

      my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

      $self->query2("SELECT count(DISTINCT u.uid) AS total FROM users u
       LEFT JOIN users_pi pi ON (u.uid = pi.uid)
       LEFT JOIN bills b ON (u.bill_id = b.id)
       LEFT JOIN (
          SELECT max(date) AS date, uid FROM payments GROUP BY uid
        ) AS p  ON u.uid=p.uid
       $WHERE;",
      undef,
      { INFO => 1 }
      );
    }

    return $list;
  }

  #Show last fees
  if ($attr->{FEES} || $attr->{FEES_DAYS}) {
    my @HAVING_RULES = @WHERE_RULES;
    if ($attr->{FEES}) {
      my $value = @{ $self->search_expr($attr->{FEES}, 'INT') }[0];
      push @WHERE_RULES,  "f.date$value";
      push @HAVING_RULES, "MAX(f.date)$value";
      $self->{SEARCH_FIELDS} .= 'MAX(f.date) AS last_fees, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }
    elsif ($attr->{FEES_DAYS}) {
      my $value = "NOW() - INTERVAL $attr->{FEES_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;

      push @WHERE_RULES,  "p.date$value";
      push @HAVING_RULES, "MAX(f.date)$value";
      $self->{SEARCH_FIELDS} .= 'MAX(f.date) AS last_fees, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }

    my $HAVING = ($#HAVING_RULES > -1) ? "HAVING " . join(' AND ', @HAVING_RULES) : '';

    $self->query2("SELECT u.id AS login,
       $self->{SEARCH_FIELDS}
       u.uid,
       u.company_id,
       pi.email,
       u.activate,
       u.expire,
       u.gid,
       b.deposit,
       u.domain_id,
       u.deleted
     FROM users u
     LEFT JOIN fees f ON (u.uid = f.uid)
     $EXT_TABLES
     GROUP BY u.uid
     $HAVING
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );
    return [ ] if ($self->{errno});

    my $list = $self->{list};

    if ($self->{TOTAL} > 0) {
      if ($attr->{FEES}) {
        $WHERE_RULES[$#WHERE_RULES] = @{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'f.date') };
      }
      elsif ($attr->{FEES_DAYS}) {
        my $value = "curdate() - INTERVAL $attr->{FEES_DAYS} DAY";
        $value =~ s/([<>=]{1,2})//g;
        $value = $1 . $value;
        $WHERE_RULES[$#WHERE_RULES] = "f.date$value";
      }

      my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

      $self->query2("SELECT count(DISTINCT u.uid) AS total FROM users u
       LEFT JOIN fees f ON (u.uid = f.uid)
       LEFT JOIN users_pi pi ON (u.uid = pi.uid)
       LEFT JOIN bills b ON (u.bill_id = b.id)
      $WHERE;",
      undef,
      { INFO => 1 }
      );
    }

    return $list;
  }

  my $where_delimeter = ' AND ';
  if ( $attr->{_MULTI_HIT} ) {
    $where_delimeter = ' OR ';
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE (" . join($where_delimeter, @WHERE_RULES) .')' : '';

  if ($admin->{GID}) {
    $WHERE .= (($WHERE) ? 'AND' : '') ." u.gid IN ($admin->{GID})";
  }

  if ( ! $admin->{permissions}->{0}->{8} ) {
    $WHERE .= " AND u.deleted=0";
  }

  $self->query2("SELECT u.id AS login,
      $self->{SEARCH_FIELDS}
      u.uid
     FROM users u
     $EXT_TABLES
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});
  my $list = $self->{list} || [];

  if ($self->{TOTAL} == $PAGE_ROWS || $PG > 0 || $attr->{FULL_LIST}) {
    $self->query2("SELECT COUNT(u.id) AS total,
     SUM(IF(u.expire<CURDATE() AND u.expire>'0000-00-00', 1, 0)) AS total_expired,
     SUM(IF(u.disable=1, 1, 0)) AS total_disabled,
     SUM(u.deleted) AS total_deleted
     FROM users u
     $EXT_TABLES
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 add($attr) - Add user function

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  if (! $self->check_params()) {
    return $self;
  }

  if (! $attr->{LOGIN}) {
    #check autofill trigger
    $self->query2("SHOW TRIGGERS WHERE `Trigger` = 'login_id';");
    if (! $self->{TOTAL}) {
      $self->{errno}  = 8;
      $self->{errstr} = 'ERROR_ENTER_NAME';
      return $self;
    }

    if ($attr->{REGISTRATION_PREFIX}) {
      $self->query2("SET \@login_prefix = '$attr->{REGISTRATION_PREFIX}';");
    }
  }
  elsif (length($attr->{LOGIN}) > $self->{conf}->{MAX_USERNAME_LENGTH}) {
    $self->{errno}  = 9;
    $self->{errstr} = 'ERROR_LONG_USERNAME';
    return $self;
  }
  #ERROR_SHORT_PASSWORD
  elsif ($attr->{LOGIN} !~ /$usernameregexp/) {
    $self->{errno}  = 10;
    $self->{errstr} = 'ERROR_WRONG_NAME';
    return $self;
  }
  elsif ($attr->{EMAIL} && $attr->{EMAIL} ne '') {
    if ($attr->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno}  = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  $self->query_add('users', {
    %$attr,
    REGISTRATION => $attr->{REGISTRATION} || 'NOW()',
    DISABLE      => int($attr->{DISABLE} || 0),
    ID           => $attr->{LOGIN},
    PASSWORD     => "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')",
    DOMAIN_ID    => $admin->{DOMAIN_ID}
  });

  return $self if ($self->{errno});

  $self->{UID}   = $self->{INSERT_ID};
  $self->{LOGIN} = $attr->{LOGIN} || $self->{UID};

  $admin->{MODULE} = '';
  $admin->action_add($self->{UID}, "LOGIN:$self->{LOGIN}", { TYPE => 7 });

  if ($attr->{CREATE_BILL}) {
    $self->change(
      $self->{UID},
      {
        DISABLE         => int($attr->{DISABLE} || 0),
        UID             => $self->{UID},
        CREATE_BILL     => 1,
        CREATE_EXT_BILL => $attr->{CREATE_EXT_BILL}
      }
    );
  }

  return $self;
}

#**********************************************************
=head2 change($uid, $attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;

  if ($attr->{CREATE_BILL}) {
    use Bills;
    my $Bill = Bills->new($self->{db}, $admin, $self->{conf});
    $Bill->create({ UID => $self->{UID} || $uid });
    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{BILL_ID} = $Bill->{BILL_ID};

    if ($attr->{CREATE_EXT_BILL}) {
      $Bill->create({ UID => $self->{UID} });
      if ($Bill->{errno}) {
        $self->{errno}  = $Bill->{errno};
        $self->{errstr} = $Bill->{errstr};
        return $self;
      }
      $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
    }
  }
  elsif ($attr->{CREATE_EXT_BILL}) {
    use Bills;
    my $Bill = Bills->new($self->{db}, $admin, $self->{conf});
    $Bill->create({ UID => $self->{UID} });

    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
  }

  if (defined($attr->{CREDIT}) && $attr->{CREDIT} == 0) {
    $attr->{CREDIT_DATE} = '0000-00-00';
  }
  if (defined($attr->{REDUCTION}) && $attr->{REDUCTION} == 0) {
    $attr->{REDUCTION_DATE} = '0000-00-00';
  }

  if (!defined($attr->{DISABLE}) && ! $attr->{SKIP_STATUS_CHANGE}) {
    $attr->{DISABLE} = 0;
  }

  #Make extrafields use
  $admin->{MODULE} = '';

  $self->changes2(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'users',
      DATA         => $attr,
      ACTION_ID    => $attr->{ACTION_ID},
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 del(attr) - Delete user info from all tables

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{FULL_DELETE}) {
    my @clear_db = ('admin_actions', 'fees', 'payments', 'users_nas', 'users', 'users_pi', 'shedule', 'msgs_messages');

    $self->{info} = '';
    foreach my $table (@clear_db) {
      if ($table eq 'payments') {
        $self->query2("DELETE FROM docs_invoice2payments WHERE payment_id IN (SELECT id FROM payments WHERE uid= ? )", 'do', { Bind => [ $self->{UID} ] });
        $self->query2("DELETE FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE uid= ? );", 'do', { Bind => [ $self->{UID} ] });
        $self->query_del('docs_receipts', undef, { uid => $self->{UID} });
      }

      $self->query_del($table, undef, { uid =>  $self->{UID} });
      $self->{info} .= "$table, ";
    }

    my $Attach = Attach->new($self->{db}, $admin, $CONF);
    $Attach->attachment_del({ UID => $self->{UID}, FULL_DELETE => 1 });

    $admin->{MODULE} = '';
    $admin->action_add($self->{UID}, "DELETE $self->{UID}:$self->{LOGIN}", { TYPE => 12 });
  }
  else {
    $self->change($self->{UID}, { DELETED => 1, ACTION_ID => 12, UID => $self->{UID} });
  }

  return $self->{result};
}

#**********************************************************
=head2 nas_list() - list_allow nass

=cut
#**********************************************************
sub nas_list {
  my $self = shift;
  my $list;
  $self->query2("SELECT nas_id FROM users_nas WHERE uid='$self->{UID}';");

  if ($self->{TOTAL} > 0) {
    $list = $self->{list};
  }
  else {
    $self->query2("SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TARIF_PLAN}';");
    $list = $self->{list};
  }

  return $list;
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
  my $self = shift;
  my ($nas) = @_;

  $self->nas_del();

  my @MULTI_QUERY = ();

  foreach my $id (@$nas) {
    push @MULTI_QUERY, [ $id,
                         $self->{UID}
                        ];
  }

  $self->query2("INSERT INTO users_nas (nas_id, uid) VALUES (?, ?);",
      undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  $admin->action_add($self->{UID}, "NAS " . join(',', @$nas));
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;

  $self->query_del('users_nas', undef, { uid => $self->{UID} });
  return $self if ($self->{error} > 0);

  $admin->action_add($self->{UID}, "DELETE NAS");
  return $self;
}

#**********************************************************
=head2 bruteforce_add($attr)

=cut
#**********************************************************
sub bruteforce_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_bruteforce', {
      %$attr,
      IP       => $attr->{REMOTE_ADDR},
      DATETIME => 'NOW()'
    });

  return $self;
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

  my $GROUP = 'GROUP BY login';
  my $count = 'COUNT(login) AS count';
  my $DISTINCT = 'DISTINCT';

  my $WHERE = $self->search_former($attr, [
      ['LOGIN',             'STR', 'login',         ],
      ['AUTH_STATE',        'INT', 'auth_state',       ],
    ],
    { WHERE       => 1,
    }
    );

  if ($attr->{LOGIN}) {
    $count = 'auth_state';
    $GROUP = '';
  }

  my $list;

  if (!$attr->{CHECK}) {
    $self->query2("SELECT login, password, datetime, $count, INET_NTOA(ip) AS ip FROM users_bruteforce
      $WHERE
      $GROUP
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );
    $list = $self->{list};
  }
  else {
    $DISTINCT='';
  }

  $self->query2("SELECT COUNT($DISTINCT login) AS total FROM users_bruteforce $WHERE;", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 bruteforce_del() - clear bruterforce listing

=cut
#**********************************************************
sub bruteforce_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "";

  if ($attr->{DATE}) {
    $WHERE = "datetime <= '$attr->{DATE} 24:00:00'";
  }
  elsif($attr->{LOGIN}){
    $WHERE = "login='$attr->{LOGIN}'";
  }

  $self->query2("DELETE FROM users_bruteforce
   WHERE $WHERE;", 'do'
  );

  return $self;
}

#**********************************************************
=head2 web_session_update($attr)
  Attributes:
    $attr
      SID

=cut
#**********************************************************
sub web_session_update {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("UPDATE web_users_sessions SET
     datetime = UNIX_TIMESTAMP()
    WHERE sid = ?;", 'do', { Bind => [ $attr->{SID} ] });

  return $self;
}

#**********************************************************
=head2 web_session_add($attr)  - Add web sessions user info

  Arguments:
    $attr
      UID
      LOGIN
      REMOTE_ADDR
      SID
      EXT_INFO

  Returns:
    Object

=cut
#**********************************************************
sub web_session_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE FROM web_users_sessions WHERE uid=?;", 'do', { Bind => [ $attr->{UID} ] });

  $self->query2("INSERT INTO web_users_sessions
        (uid, datetime, login, remote_addr, sid, ext_info, coordx, coordy) VALUES
        (?, UNIX_TIMESTAMP(), ?, INET_ATON( ? ), ?, ?, ?, ?);",
     'do',
     { Bind => [
         $attr->{UID},
         $attr->{LOGIN},
         $attr->{REMOTE_ADDR},
         $attr->{SID},
         $attr->{EXT_INFO} || '',
         $attr->{COORDX} || 0,
         $attr->{COORDY} || 0
       ] }
  );

  return $self;
}

#**********************************************************
=head2 web_session_info($attr) - User information

  Argumnets:
    $attr
      SID
      UID

  Returns:
    Object

=cut
#**********************************************************
sub web_session_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE;
  my @request_arr = (  );

  if ($attr->{SID}) {
    $WHERE = "WHERE sid= ? ";
    @request_arr = ($attr->{SID});
  }
  elsif ($attr->{UID}) {
    $WHERE = "WHERE uid= ? ";
    @request_arr = ($attr->{UID});
  }
  else {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  $self->query2("SELECT uid,
    datetime,
    login,
    INET_NTOA(remote_addr) AS remote_addr,
    UNIX_TIMESTAMP() - datetime AS session_time,
    sid
     FROM web_users_sessions
     $WHERE;",
    undef,
    { INFO => 1,
      Bind => [ @request_arr ] }
  );

  return $self;
}

#**********************************************************
=head2 web_sessions_list() - List of users web sessions

=cut
#**********************************************************
sub web_sessions_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP = 'GROUP BY login';
  my $count = 'count(login) AS count';
  my @WHERE_RULES = ();

  if ($attr->{LOGIN} && $attr->{LOGIN} ne '_SHOW') {
    $count = 'auth_state';
    $GROUP = '';
  }

  if ($attr->{ACTIVE}) {
    push @WHERE_RULES, "UNIX_TIMESTAMP() - datetime < $attr->{ACTIVE}";
  }

  my $WHERE =  $self->search_former($attr, [
      ['LOGIN',        'INT', 'login',       ],
      ['EXT_INFO',     'INT', 'ext_info',  1 ],
      ['COORDX',       'INT', 'coordx',    1 ],
      ['COORDY',       'INT', 'coordy',    1 ],
      ['UID',          'INT', 'uid',         ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
    }
  );

  my $list;

  if (!$attr->{CHECK}) {
    $self->query2("SELECT FROM_UNIXTIME(datetime) AS datetime, login, INET_NTOA(remote_addr) AS ip, sid, $self->{SEARCH_FIELDS} uid
     FROM web_users_sessions
      $WHERE
      $GROUP
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );
    $list = $self->{list};
  }

  $self->query2("SELECT count(DISTINCT login) AS total FROM web_users_sessions $WHERE;", undef, {INFO => 1 });

  return $list;
}


#**********************************************************
=head2 web_session_del($attr) - Del user web sessions

  Arguments:
    $attr
      SID
      ALL

  Returns:
    Object

=cut
#**********************************************************
sub web_session_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('web_users_sessions', undef,  { sid => $attr->{SID}}, { CLEAR_TABLE => $attr->{ALL}  });

  return $self;
}

#**********************************************************
=head2 info_field_attach_add($attr) - Info fields attach add

  Arguments:
    $attr
      COMPANY_PREFIX
  Returns:
    Object

=cut
#**********************************************************
sub info_field_attach_add {
  my $self = shift;
  my ($attr) = @_;
	my $insert_id = 0;

  my $prefix = ($attr->{COMPANY_PREFIX}) ? 'ifc' : 'ifu';

  my $Conf   = Conf->new($self->{db}, $admin, $self->{conf});
  my $Attach = Attach->new($self->{db}, $admin, $CONF);
  my $list   = $Conf->config_list({ PARAM => $prefix .'*' });

  if ($self->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if ($line->[0] =~ /$prefix(\S+)/) {
        my $field_name = $1;
        my (undef, $type, undef) = split(/:/, $line->[1]);
        if ($type == 13) {
          #attach
          if (ref $attr->{uc($field_name)} eq 'HASH' && $attr->{uc($field_name)}{filename}) {
            if($CONF->{ATTACH2FILE}) {
              if($self->{UID}) {
                $self->pi({ UID => $self->{UID} });
                if($self->{uc($field_name)}) {
                  $Attach->attachment_del({
                    ID         => $self->{uc($field_name)},
                    TABLE      => $field_name.'_file',
                    UID        => $self->{UID},
                    SKIP_ERROR => 1
                  })
                }
              }
            }

            $Attach->attachment_add(
              {
                TABLE        => $field_name . '_file',
                CONTENT      => $attr->{uc($field_name)}{Contents},
                FILESIZE     => $attr->{uc($field_name)}{Size},
                FILENAME     => $attr->{uc($field_name)}{filename},
                CONTENT_TYPE => $attr->{uc($field_name)}{'Content-Type'},
                UID          => $attr->{UID},
                FIELD_NAME   => $field_name
              }
            );

            if($Attach->{errno}) {
              $self->{errno} = $Attach->{errno};
              $self->{errstr} = $Attach->{errstr};
            }
            else {
              $attr->{uc($field_name)} = $Attach->{INSERT_ID};
              $insert_id = $Attach->{INSERT_ID};
            }
          }
          else {
            delete $attr->{uc($field_name)};
          }
        }
      }
    }
  }

  return $attr;
}


#**********************************************************
=head2 info_field_add($attr) - Infofields add
  Arguments:
    $attr
      FIELD_ID
      FIELD_TYPE
      COMPANY_ADD
      CAN_BE_CHANGED_BY_USER
      USERS_PORTAL

  Returns:
    $self
=cut
#**********************************************************
sub info_field_add {
  my $self = shift;
  my ($attr) = @_;

  my @column_types = (
    " varchar(120) not null default ''",
    " int(11) NOT NULL default '0'",
    " smallint unsigned NOT NULL default '0' ",
    " text not null ",
    " tinyint(11) NOT NULL default '0' ",
    " content longblob NOT NULL",
    " varchar(100) not null default ''",
    " int(11) unsigned NOT NULL default '0'",
    " varchar(12) not null default ''",
    " varchar(120) not null default ''",
    " varchar(20) not null default ''",
    " varchar(50) not null default ''",
    " varchar(50) not null default ''",
    " int unsigned NOT NULL default '0' ",
    " INT(11) UNSIGNED NOT NULL DEFAULT '0' REFERENCES users(uid) ",
  );

  $attr->{FIELD_TYPE} = 0 if (!$attr->{FIELD_TYPE});

  my $column_type  = $column_types[ $attr->{FIELD_TYPE} ] || " varchar(120) not null default ''";
  my $field_prefix = 'ifu';

  #Add field to table
  if ($attr->{COMPANY_ADD}) {
    $field_prefix = 'ifc';
    $self->query2("ALTER TABLE companies ADD COLUMN _" . $attr->{FIELD_ID} . " $column_type;", 'do');
  }
  else {
    $self->query2("ALTER TABLE users_pi ADD COLUMN _" . $attr->{FIELD_ID} . " $column_type;", 'do');
  }

  if (!$self->{errno} || ($self->{errno} && $self->{errno} == 3)) {
    if ($attr->{FIELD_TYPE} == 2) {
      $self->query2("CREATE TABLE _$attr->{FIELD_ID}_list (
       id smallint unsigned NOT NULL primary key auto_increment,
       name varchar(120) not null default 0
       )DEFAULT CHARSET=$self->{conf}->{dbcharset};", 'do'
      );
    }
    elsif ($attr->{FIELD_TYPE} == 13) {
      $self->query2("CREATE TABLE `_$attr->{FIELD_ID}_file` (`id` int(11) unsigned NOT NULL PRIMARY KEY auto_increment,
         `filename` varchar(250) not null default '',
         `content_size` varchar(30) not null  default '',
         `content_type` varchar(250) not null default '',
         `content` longblob NOT NULL,
         `create_time` datetime NOT NULL default '0000-00-00 00:00:00') DEFAULT CHARSET=$self->{conf}->{dbcharset};", 'do'
      );
    }

    my $Conf = Conf->new($self->{db}, $admin, $self->{conf});

    $Conf->config_add(
      {
        PARAM     => $field_prefix . "_$attr->{FIELD_ID}",
        VALUE     => "$attr->{POSITION}:$attr->{FIELD_TYPE}:$attr->{NAME}:$attr->{USERS_PORTAL}:$attr->{CAN_BE_CHANGED_BY_USER}",
        DOMAIN_ID => $admin->{DOMAIN_ID} || 0
      }
    );
  }


  $admin->system_action_add("IF:_$attr->{FIELD_ID}:$attr->{NAME}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 info_field_del($attr)

  Arguments:
    $attr
      FIELD_ID
      SECTION
  Returns:
    Object

=cut
#**********************************************************
sub info_field_del {
  my $self = shift;
  my ($attr) = @_;

  my $sql = '';
  if ($attr->{SECTION} eq 'ifc') {
    $sql = "ALTER TABLE companies DROP COLUMN `$attr->{FIELD_ID}`;";
  }
  else {
    $sql = "ALTER TABLE users_pi DROP COLUMN `$attr->{FIELD_ID}`;";
  }

  $self->query2($sql, 'do');

  if (!$self->{errno} || $self->{errno} == 3) {
    my $Conf = Conf->new($self->{db}, $admin, $self->{conf});

    $Conf->config_del("$attr->{SECTION}$attr->{FIELD_ID}");
    $admin->system_action_add("IF:_$attr->{FIELD_ID}", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 info_list_add($attr)

=cut
#**********************************************************
sub info_list_add {
  my $self = shift;
  my ($attr) = @_;

  if(! $attr->{LIST_TABLE}) {
    $self->{errno}=100;
    $self->{errstr}='NO list table';
    return $self;
  }

  $self->query_add($attr->{LIST_TABLE}, $attr);

  return $self;
}

#**********************************************************
=head2 info_list_del($attr) - Info list del value

=cut
#**********************************************************
sub info_list_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del($attr->{LIST_TABLE}, $attr);

  return $self;
}

#**********************************************************
=head2 info_lists_list($attr)
=cut
#**********************************************************
sub info_lists_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT id, name FROM $attr->{LIST_TABLE} ORDER BY name;",
  undef,
  $attr);

  return $self->{list};
}

#**********************************************************
=head2 info_list_info($id, $attr)

=cut
#**********************************************************
sub info_list_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id, name FROM $attr->{LIST_TABLE} WHERE id= ? ;",
   undef,
   { INFO => 1,
     Bind => [ $id ]
   });

  return $self;
}

#**********************************************************
=head2 info_list_change($id, $attr)

=cut
#**********************************************************
sub info_list_change {
  my $self = shift;
  my (undef, $attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => $attr->{LIST_TABLE},
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 report_users_summary($attr)

=cut
#**********************************************************
sub report_users_summary {
  my $self = shift;
  #my ($attr) = @_;

  my @WHERE_RULES = ();
  if ($admin->{GID}) {
    $admin->{GID}=~s/,/;/g;
    push @WHERE_RULES,  @{ $self->search_expr($admin->{GID}, 'INT', 'u.gid') };
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES,  @{ $self->search_expr($admin->{DOMAIN_ID}, 'INT', 'u.domain_id') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' AND ', @WHERE_RULES) : '';

  $self->query2("SELECT count(*) AS total_users,
      SUM(IF(u.disable>0, 1, 0)) AS disabled_users,
      SUM(IF(u.credit>0, 1, 0)) AS creditors_count,
      SUM(IF(u.credit>0, u.credit, 0)) AS creditors_sum,
      SUM(IF(IF(company.id IS NULL, b.deposit, cb.deposit)<0, 1, 0)) AS debetors_count,
      SUM(IF(IF(company.id IS NULL, b.deposit, cb.deposit)<0, b.deposit, 0)) AS debetors_sum
    FROM users u
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
    WHERE u.deleted=0 $WHERE
    ;",
 undef,
 { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# check_params()
#**********************************************************
sub check_params {
  my $self = shift;
  $self->query2("SELECT count(*) AS count FROM users;");

  my $constant = 0x3E8;

  my $content = '';
  my $string = pack("H*", '6c6963656e73652e6b6579');

  if (-f '/usr/'. 'abills'. '/libexec/'. $string && open(my $fh, '<', '/usr'. '/abills'. '/libexec/'. $string)) {
    while(<$fh>) {
      $content .= $_;
    }

    if ($content) {
      $constant = substr(pack("H*", $content) ^ '1' x 30, 20, 10);
    }
    close($fh);
  }

  if ($constant < $self->{list}->[0]->[0]) {
    $self->{errno}  = 0x2BB;
    $self->{errstr} = $self->{list}->[0]->[0];
    return 0
  }

  return 1;
}

#**********************************************************
=head2 contacts_migrate() - migrates contacts from old to new model
    
  Returns:
    boolean - success flag
    
=cut
#**********************************************************
sub contacts_migrate {
  my ($self, $attr) = @_;
  
  if ($attr->{IGNORE_DUPLICATE}){
    $self->query2("ALTER TABLE users_contacts DROP KEY `_type_value`;");
    return 0 if ($self->{errno});
  };
  
  my %old_type_to_new = (
    EMAIL => 9,
    PHONE => 2
  );
  
  $self->query2("SELECT u.uid, up.phone, up.email
   FROM users u
   LEFT JOIN users_pi up ON (u.uid=up.uid)
   WHERE up.phone <> '' OR up.email <> ''
   ORDER BY u.uid", undef, { COLS_NAME => 1 });
  
  return 0 if ($self->{errno});
  return 1 if (!$self->{list} || scalar @{$self->{list}} <= 0);
  
  # Accumulating requests
  my @contacts_to_add = ();
  
  foreach my $user_pi ( @{$self->{list}} ) {
    if ( $user_pi->{phone} ) {
      my @phones = split(',\s?', $user_pi->{phone});
      map {
        push @contacts_to_add, [ $user_pi->{uid}, $old_type_to_new{PHONE}, $_ ];
      } @phones;
    }
    if ( $user_pi->{email} ) {
      my @emails = split(',\s?', $user_pi->{email});
      map {
        push @contacts_to_add, [ $user_pi->{uid}, $old_type_to_new{EMAIL}, $_ ];
      } @emails;
    }
  }
  
  # Start a transaction
  my DBI $db_ = $self->{db}->{db};
  $db_->{AutoCommit} = 0;
  
  # Add all contacts
  $self->query2( "INSERT INTO users_contacts (uid, type_id, value) VALUES (?, ?, ?);",
    undef,
    { MULTI_QUERY => \@contacts_to_add }
  );
  
  if ( $self->{errno} ) {
    # If error was occured, part of contacts could be inserted,
    # so next time we will get DUPLICATE, need to remove all inserted contacts
    $db_->rollback();
    return 0;
  }
  
  if ( $self->{errno} ) {
    $db_->rollback();
    return 0;
  }
  
  $db_->commit();
  $db_->{AutoCommit} = 1;
  
  
  # If insert was successful, can remove old info
  $self->query2("UPDATE users_pi SET phone='', email='';", { });
  
  return 1;
}

1;
