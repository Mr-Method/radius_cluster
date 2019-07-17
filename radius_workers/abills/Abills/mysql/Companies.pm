package Companies;

=head1 NAME

  Companies

=cut

use strict;
use parent 'main';
use Users;
use Conf;
use Bills;

my $users;
my $admin;
my $CONF;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  $users = Users->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 add($attr) - Add companies

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{NAME}) {
    $self->{errno}  = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
  }

  if ($attr->{CONTRACT_TYPE}) {
    my (undef, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $attr = $users->info_field_attach_add({ %$attr, COMPANY_PREFIX => 1 });

  $self->query_add('companies', { %$attr,
           REGISTRATION   => 'NOW()',
         });

  if ($self->{errno}) {
    return $self;
  }

  $self->{COMPANY_ID} = $self->{INSERT_ID};

  if ($attr->{CREATE_BILL}) {
    $self->change(
      {
        DISABLE         => int($attr->{DISABLE}),
        ID              => $self->{COMPANY_ID},
        CREATE_BILL     => 1,
        CREATE_EXT_BILL => $attr->{CREATE_EXT_BILL}
      }
    );
  }

  return $self;
}

#**********************************************************
=head2 change($attr) Change

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  if (!defined($attr->{DISABLE})) {
    $attr->{DISABLE} = 0;
  }

  if ($attr->{CREATE_BILL}) {
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({ COMPANY_ID => $self->{ID}, UID => 0 });
    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{BILL_ID} = $Bill->{BILL_ID};

    if ($attr->{CREATE_EXT_BILL}) {
      $Bill->create({ COMPANY_ID => $self->{ID} });
      if ($Bill->{errno}) {
        $self->{errno}  = $Bill->{errno};
        $self->{errstr} = $Bill->{errstr};
        return $self;
      }
      $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
    }
  }
  elsif ($attr->{CREATE_EXT_BILL}) {
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({ COMPANY_ID => $self->{ID} });

    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
  }

  $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  $attr = $users->info_field_attach_add({ %$attr, COMPANY_PREFIX => 1 });

  my ($prefix, $sufix);
  if ($attr->{CONTRACT_TYPE}) {
    ($prefix, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'companies',
      #FIELDS       => \%FIELDS,
      #OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  $self->info($attr->{ID});

  return $self;
}

#**********************************************************
=head2 del($company_id)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($company_id) = @_;

  $self->query_del('companies', { ID => $company_id });

  return $self;
}

#**********************************************************
=head2 info($company_id) - Info

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($company_id) = @_;

  $self->query2("SELECT c.*,
     b.deposit
    FROM companies c
    LEFT JOIN bills b ON (c.bill_id=b.id)
    WHERE c.id= ? ;",
    undef,
    { INFO => 1,
    	Bind => [ 
    	  $company_id
    ]}
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} > 0) {
    $self->query2("SELECT b.deposit AS ext_bill_deposit, b.uid AS ext_bill_owner
     FROM bills b WHERE id= ? ;",
     undef,
     { INFO => 1, Bind => [ $self->{EXT_BILL_ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 list($attr) - List

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

  my $Conf = Conf->new($self->{db}, $admin, $CONF);
  my $list = $Conf->config_list({ PARAM => 'ifc*', SORT => 2 });

  if ($self->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if ($line->[0] =~ /ifc(\S+)/) {
        my $field_name = $1;
        my (undef, $type, undef) = split(/:/, $line->[1]);

        if (defined($attr->{$field_name}) && $type == 4) {
          push @WHERE_RULES, 'c.' . $field_name . "='$attr->{$field_name}'";
        }
        #Skip for bloab
        elsif ($type == 5) {
          next;
        }
        elsif ($attr->{$field_name}) {
          if ($type == 1) {
            my $value = $self->search_expr("$attr->{$field_name}", 'INT');
            push @WHERE_RULES, "(c." . $field_name . "$value)";
          }
          elsif ($type == 2) {
            push @WHERE_RULES, "(pi.$field_name='$attr->{$field_name}')";
            $self->{SEARCH_FIELDS} .= "$field_name" . '_list.name AS '. $field_name. '_list_name, ';
            $self->{SEARCH_FIELDS_COUNT}++;
            $self->{EXT_TABLES} .= "LEFT JOIN $field_name" . "_list ON (c.$field_name = $field_name" . "_list.id)";
            next;
          }
          else {
            $attr->{$field_name} =~ s/\*/\%/ig;
            push @WHERE_RULES, "c.$field_name LIKE '$attr->{$field_name}'";
          }

          $self->{SEARCH_FIELDS} .= "c.$field_name, ";
          $self->{SEARCH_FIELDS_COUNT}++;
        }
      }
    }
    $self->{EXTRA_FIELDS} = $list;
  }

  my $WHERE =  $self->search_former($attr, [
      ['COMPANY_NAME',   'STR', 'c.name',          ],
      ['DEPOSIT',        'INT', 'b.deposit',     1 ],
      ['CREDIT',         'INT', 'c.credit',      1 ],
      ['USERS_COUNT',    'INT', 'count(u.uid) AS users_count', 1 ],
      ['CREDIT_DATE',    'DATE','c.credit_date', 1 ],
      ['ADDRESS',        'STR', 'c.address',     1 ],
      ['REGISTRATION',   'DATE','c.registration',1 ],
      ['DISABLE',        'INT', 'c.disable AS status',  1 ],
      ['CONTRACT_ID',    'INT', 'c.contract_id', 1 ],
      ['COMPANY_ID',     'INT', 'c.id',            ],
    ],
    {
      WHERE_RULES => \@WHERE_RULES,
      WHERE       => 1,
    }
  );

  $self->{COL_NAMES_ARR}=undef;

  $self->query2("SELECT c.name, $self->{SEARCH_FIELDS} c.id 
    FROM companies  c
    LEFT JOIN users u ON (u.company_id=c.id)
    LEFT JOIN bills b ON (b.id=c.bill_id)
    $WHERE
    GROUP BY c.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );
  $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT COUNT(DISTINCT c.id) AS total FROM companies c
    LEFT JOIN users u ON (u.company_id=c.id)
    LEFT JOIN bills b ON (b.id=c.bill_id)
     $WHERE;",
    undef,
    { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 admins_list($attr)

=cut
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, "u.uid='$attr->{UID}'";
  }

  if ($attr->{GET_ADMINS}) {
    push @WHERE_RULES, "ca.uid>0";
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "c.id='$attr->{COMPANY_ID}'";
  }

  my $WHERE = ' AND ' . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);

  $self->query2("SELECT IF(ca.uid is null, 0, 1) AS is_company_admin,
      u.id AS login,
      pi.fio,
      pi.email,
      u.uid
    FROM (companies  c, users u)
    LEFT JOIN companie_admins ca ON (ca.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    WHERE u.company_id=c.id $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 admins_change($attr)

=cut
#**********************************************************
sub admins_change {
  my $self = shift;
  my ($attr) = @_;

  my @ADMINS = split(/, /, $attr->{IDS});

  $self->query_del('companie_admins', undef, { company_id => $attr->{COMPANY_ID} });

  foreach my $uid (@ADMINS) {
    $self->query_add('companie_admins', { %$attr,
    	                                    UID => $uid
    	                                  });
  }

  return $self;
}

1
