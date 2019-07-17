
=head1 NAME

  Cashbox - module for CRM

=head1 SYNOPSIS

  use Cashbox;
  my $Cashbox = Cashbox->new($db, $admin, \%conf);

=cut

package Crm;

use strict;
use parent qw(main);

my ($admin, $CONF);

#*******************************************************************

=head2 new()

=cut

#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#**********************************************************

=head2 add_cashbox() - add new cashbox

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub add_cashbox {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cashbox_cashboxes', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function list_cashbox() - get list of all cashboxes

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Cashbox->list_cashbox({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_cashbox {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'COMMENTS', 'STR', 'comments', 1 ], ], { WHERE => 1, });

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT * FROM cashbox_cashboxes
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM cashbox_cashboxes",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function delete_cashbox() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Cashbox->delete_cashbox( {ID => 1} );

=cut

#*******************************************************************
sub delete_cashbox {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cashbox_cashboxes', $attr);

  return $self;
}

#*******************************************************************

=head2 function info_cashbox() - get information about cashbox

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $cashbox_info = $Cashbox->info_cashbox({ ID => 1 });

=cut

#*******************************************************************
sub info_cashbox {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM cashbox_cashboxes
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function change_cashbox() - change cashbox's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Cashbox->change_cashbox({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub change_cashbox {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cashbox_cashboxes',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************

=head2 add_type() - add type, coming or spending

  Arguments:
    $attr -
      spending - if it is spending type
      coming   - if it is coming type
  Returns:

  Examples:
    $Cashbox->add_type({ %FORM, SPENDING => 1 });
    $Cashbox->add_type({ %FORM, COMING   => 1 });

=cut

#**********************************************************
sub add_type {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SPENDING}) {
    $self->query_add('cashbox_spending_types', {%$attr});
  }

  if ($attr->{COMING}) {
    $self->query_add('cashbox_coming_types', {%$attr});
  }

  return $self;
}

#*******************************************************************

=head2 function list_spending_types() - get list spending types

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Cashbox->list_spending_types({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_spending_type {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'COMMENTS', 'STR', 'comments', 1 ], ], { WHERE => 1, });

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT * FROM cashbox_spending_types
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM cashbox_spending_types",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function delete_type() - delete type, spending or coming

  Arguments:
    $attr

  Returns:

  Examples:
    $Cashbox->delete_type( {ID => 1, SPENDING => 1} );
    $Cashbox->delete_type( {ID => 1, SPENDING => 1} );

=cut

#*******************************************************************
sub delete_type {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SPENDING}) {
    $self->query_del('cashbox_spending_types', $attr);
  }

  if ($attr->{COMING}) {
    $self->query_del('cashbox_coming_types', $attr);
  }

  return $self;
}

#*******************************************************************

=head2 function info_type() - get information type, spending or coming

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $spend_type_info  = $Cashbox->info_type({ ID => 1, SPENDING => 1 });
    my $coming_type_info = $Cashbox->info_type({ ID => 1, COMING   => 1 });

=cut

#*******************************************************************
sub info_type {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SPENDING}) {
    $self->query2(
      "SELECT * FROM cashbox_spending_types
       WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  if ($attr->{COMING}) {
    $self->query2(
      "SELECT * FROM cashbox_coming_types
       WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}

#*******************************************************************

=head2 function change_type() - change type, coming or spending

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Cashbox->change_type({ COMING   => 1, %FORM });
    $Cashbox->change_type({ SPENDING => 1, %FORM });

=cut

#*******************************************************************
sub change_type {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SPENDING}) {
    $self->changes2(
      {
        CHANGE_PARAM => 'ID',
        TABLE        => 'cashbox_spending_types',
        DATA         => $attr
      }
    );
  }

  if ($attr->{COMING}) {
    $self->changes2(
      {
        CHANGE_PARAM => 'ID',
        TABLE        => 'cashbox_coming_types',
        DATA         => $attr
      }
    );
  }

  return $self;
}

#*******************************************************************

=head2 function list_coming_type() - get list of coming types

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Cashbox->list_coming_type({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_coming_type {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'COMMENTS', 'STR', 'comments', 1 ], ], { WHERE => 1, });

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT * FROM cashbox_coming_types
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM cashbox_coming_types",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************

=head2 add_spending() - add spending

  Arguments:
    $attr -
  Returns:

  Examples:
    $Cashbox->add_spending({%FORM});
=cut

#**********************************************************
sub add_spending {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cashbox_spending', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function delete_spending() - delete spending

  Arguments:
    $attr

  Returns:

  Examples:
    $Cashbox->delete_spending( {ID => 1} );

=cut

#*******************************************************************
sub delete_spending {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cashbox_spending', $attr);

  return $self;
}

#*******************************************************************

=head2 function info_spending() - get information about spending

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $info_spending = $Cashbox->info_spending({ ID => 1 });

=cut

#*******************************************************************
sub info_spending {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM cashbox_spending
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function change_spending() - change spending

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Cashbox->change_spending({
      ID       => 1,
      AMOUNT   => 100
    });


=cut

#*******************************************************************
sub change_spending {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cashbox_spending',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************

=head2 function list_spending() - get list of spendings

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Cashbox->list_spending({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_spending {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 50;

  if ($attr->{CASHBOX_ID}) {
    push @WHERE_RULES, "CASHBOX_ID = $attr->{CASHBOX_ID}";
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "DATE >= '$attr->{FROM_DATE}'";
  }

  if ($attr->{TO_DATE}) {
    push @WHERE_RULES, "DATE <= '$attr->{TO_DATE}'";
  }

  my $WHERE = $self->search_former(
    $attr,
    [ [ 'ID', 'INT', 'cs.id', 1 ], [ 'AMOUNT', 'DOUBLE', 'cs.amount', 1 ], [ 'SPENDING_TYPE_NAME', 'STR', 'cst.name as spending_type_name', 1 ], [ 'CASHBOX_NAME', 'STR', 'cc.name as cashbox_name', 1 ], [ 'DATE', 'STR', 'cs.date', 1 ], [ 'ADMIN', 'STR', 'a.name as admin', 1 ] ,[ 'COMMENTS', 'STR', 'cs.comments', 1 ], ],
    { WHERE => 1, }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
    cs.id,
    cs.amount,
    cc.name as cashbox_name,
    cst.name as spending_type_name,
    cs.date,
    a.name as admin,
    cs.comments,
    cs.spending_type_id,
    cs.cashbox_id
    FROM cashbox_spending as cs
    LEFT JOIN cashbox_spending_types cst ON (cst.id = cs.spending_type_id)
    LEFT JOIN cashbox_cashboxes cc ON (cc.id = cs.cashbox_id)
    LEFT JOIN admins a ON (a.aid = cs.aid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM cashbox_spending",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************

=head2 add_coming() - add coming

  Arguments:
    $attr -
  Returns:

  Examples:


=cut

#**********************************************************
sub add_coming {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cashbox_coming', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function delete_coming() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Cashbox->delete_coming( {ID => 1} );

=cut

#*******************************************************************
sub delete_coming {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cashbox_coming', $attr);

  return $self;
}

#*******************************************************************

=head2 function info_coming() - get information about coming

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $info_coming = $Cashbox->info_coming({ ID => 1 });

=cut

#*******************************************************************
sub info_coming {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM cashbox_coming
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function change_coming() - change

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Cashbox->change_coming({
      ID     => 1,
      AMOUNT   => 100
    });


=cut

#*******************************************************************
sub change_coming {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cashbox_coming',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************

=head2 function list_coming() - get list of all comings

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Cashbox->list_coming({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_coming {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{CASHBOX_ID}) {
    push @WHERE_RULES, "CASHBOX_ID = $attr->{CASHBOX_ID}";
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "DATE >= '$attr->{FROM_DATE}'";
  }

  if ($attr->{TO_DATE}) {
    push @WHERE_RULES, "DATE <= '$attr->{TO_DATE}'";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',               'INT',    'cs.id',                        1 ],
      [ 'AMOUNT',           'DOUBLE', 'cs.amount',                    1 ],
      [ 'COMING_TYPE_NAME', 'STR',    'cct.name as coming_type_name', 1 ],
      [ 'CASHBOX_NAME',     'STR',    'cc.name as cashbox_name',      1 ],
      [ 'DATE',             'STR',    'cs.date',                      1 ],
      [ 'ADMIN',             'STR',    'a.name as admin',                      1 ],
      [ 'COMMENTS',         'STR',    'cs.comments',                  1 ],
    ],
    { WHERE => 1, }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
    cac.id,
    cac.amount,
    cc.name as cashbox_name,
    cct.name as coming_type_name,
    cac.date,
    a.name as admin,
    cac.comments,
    cac.coming_type_id,
    cac.cashbox_id
    FROM cashbox_coming as cac
    LEFT JOIN cashbox_coming_types cct ON (cct.id = cac.coming_type_id)
    LEFT JOIN cashbox_cashboxes cc ON (cc.id = cac.cashbox_id)
    LEFT JOIN admins a ON (a.aid = cac.aid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM cashbox_coming",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 add_bet() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_bet {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_bet', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function info_aid_schedule() -

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $info_coming = $Crm->info_coming({ ID => 1 });

=cut

#*******************************************************************
sub info_bet {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM crm_bet
      WHERE aid = $attr->{AID};", undef, {COLS_NAME => 1, COLS_UPPER => 1}
  );

  return $self->{list}[0];
}

#*******************************************************************

=head2 function change_schedule() - change

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Cashbox->change_schedule({
      AID     => 1,
      AMOUNT   => 100
    });


=cut

#*******************************************************************
sub del_bet {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_bet', undef, {aid => $attr->{AID}});

  return $self;
}


#**********************************************************
=head2 add_payed_salary() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_payed_salary {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_salaries_payed', {%$attr, DATE => 'NOW()'});

  return $self;
}

#**********************************************************
=head2 info_payed_salary() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub info_payed_salary {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT
    csp.aid,
    csp.month,
    csp.year,
    csp.bet,
    csp.date
    FROM crm_salaries_payed as csp
    WHERE aid = $attr->{AID} and month = $attr->{MONTH} and year = $attr->{YEAR};", undef, { COLS_NAME => 1 }
    );

  if($self->{list} && ref $self->{list} eq 'ARRAY' && scalar @{$self->{list}} > 0){
    return $self->{list}[0];
  }

  return ;
}

#**********************************************************
=head2 add_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_reference_works {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_reference_works', {%$attr});

  return $self;
}

#**********************************************************
=head2 change_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub change_reference_works {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_reference_works',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 info_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub info_reference_works {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM crm_reference_works
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 delete_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub delete_reference_works {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_reference_works', $attr);

  return $self;
}

#**********************************************************
=head2 list_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub list_reference_works {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  #if ($attr->{CASHBOX_ID}) {
  #  push @WHERE_RULES, "CASHBOX_ID = $attr->{CASHBOX_ID}";
  #}
  
  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',       'INT',    'crw.id',       1 ],
      [ 'NAME',     'STR',    'crw.name',     1 ],
      [ 'SUM',      'DOUBLE', 'crw.sum',      1 ],
      [ 'TIME',     'INT',    'crw.time',     1 ],
      [ 'UNITS',    'STR',    'crw.units',    1 ],
      [ 'DISABLED', 'STR',    'crw.disabled', 1 ],
      [ 'COMMENTS', 'STR',    'crw.comments', 1 ],
    ],
    { WHERE => 1, }
  );

  $self->query2(
    "SELECT
    crw.id,
    crw.name,
    crw.sum,
    crw.time,
    crw.units,
    crw.disabled,
    crw.comments
    FROM crm_reference_works as crw
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total
   FROM cashbox_coming",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 works_list($attr) - list of tp services

  Arguments:
    $attr

=cut
#**********************************************************
sub works_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'DATE',       'DATE','w.date',      1 ],
      [ 'EMPLOYEE',   'STR', 'employee.name', 'employee.name AS employee' ],
      [ 'WORK_ID',    'INT', 'w.work_id',   1 ],
      [ 'WORK',       'INT', 'crw.name',   'crw.name AS work' ],
      [ 'RATIO',      'STR', 'w.ratio',     1 ],
      [ 'EXTRA_SUM',  'INT', 'w.extra_sum', 1 ],
      [ 'SUM',        'INT', 'w.sum', 'if(w.extra_sum > 0, w.extra_sum, w.sum * w.ratio) AS sum' ],
      [ 'COMMENTS',   'INT', 'w.comments',  1 ],
      [ 'PAID',       'INT', 'w.paid',      1 ],
      [ 'ADMIN_NAME', 'STR', 'a.login',     'a.name AS admin_name' ],
      [ 'EXT_ID',     'INT', 'w.ext_id',    1  ],
      [ 'EMPLOYEE_ID','INT', 'w.employee_id', 1 ],
      [ 'FROM_DATE|TO_DATE','DATE', "DATE_FORMAT(w.date, '%Y-%m-%d')", 1 ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query2( "SELECT $self->{SEARCH_FIELDS} w.aid, w.id
   FROM crm_works w
   LEFT JOIN admins a ON (a.aid=w.aid)
   LEFT JOIN admins employee ON (employee.aid=w.employee_id)
   LEFT JOIN crm_reference_works AS crw ON (crw.id = w.work_id)
    $WHERE
    GROUP BY w.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query2( "SELECT COUNT(*) AS total, SUM(if(w.extra_sum > 0, w.extra_sum, w.sum * w.ratio)) AS total_sum
   FROM crm_works w
   LEFT JOIN admins a ON (a.aid=w.aid)
   LEFT JOIN crm_reference_works AS crw ON (crw.id = w.work_id)
    $WHERE",
    undef,
    { INFO => 1 }
  );


  return $list;
}

#**********************************************************
=head2 works_add($attr)

=cut
#**********************************************************
sub works_add{
  my $self = shift;
  my ($attr) = @_;

  if(! $attr->{EXTRA_SUM}) {
    $self->info_reference_works({ ID => $attr->{WORK_ID} });
    if($self->{TOTAL}) {
      $attr->{SUM} = $self->{SUM} * ($attr->{RATIO} || 1);
    }
  }

  $self->query_add( 'crm_works', { %$attr, AID => $admin->{AID} });

  return $self;
}

#**********************************************************
=head2 warks_change($attr)

=cut
#**********************************************************
sub works_change{
  my $self = shift;
  my ($attr) = @_;

  if(! $attr->{EXTRA_PRICE}) {
    $self->info_reference_works({ ID => $attr->{WORK_ID} });
    if($self->{TOTAL}) {
      $attr->{SUM} = $self->{SUM} * ($attr->{RATIO} || 1);
    }
  }

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_works',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 works_del($id, $attr)

=cut
#**********************************************************
sub works_del{
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del( 'crm_works', $attr, { ID => $id } );

  return $self;
}

#**********************************************************
=head2 works_info($id, $attr)

=cut
#**********************************************************
sub works_info{
  my $self = shift;
  my ($id) = @_;

  $self->query2( "SELECT * FROM crm_works
    WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 crm_lead_add() - add new lead

  Arguments:
    $attr  -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_leads', {%$attr, DATE => $attr->{DATE} || 'NOW()'});

  return $self;
}

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
 #**********************************************************
 sub crm_lead_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_leads',
      DATA         => $attr
    }
  );

  return $self;
 }

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_leads', $attr);

  return $self;
}

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM crm_leads
      WHERE id = ?;", undef, {COLS_NAME => 1, COLS_UPPER=> 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0] || {};
}

#**********************************************************
=head2 crm_lead_list() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'LEAD_ID',               'INT',   'cl.id as lead_id',               1 ],
      [ 'FIO',              'STR',   'cl.fio',                         1 ],
      [ 'PHONE',            'STR',   'cl.phone',                       1 ],
      [ 'EMAIL',            'STR',   'cl.email',                       1 ],
      [ 'COMPANY',          'STR',   'cl.company',                     1 ],
      [ 'CITY',             'STR',   'cl.city',                        1 ],
      [ 'RESPONSIBLE',      'INT',   'cl.responsible',                 1 ],
      [ 'ADMIN_NAME',       'STR',   'a.name as admin_name',           1 ],
      [ 'SOURCE',           'INT',   'cl.source',                      1 ],
      [ 'SOURCE_NAME',      'STR',   'cls.name as source_name',        1 ],
      [ 'DATE',             'DATE',  'cl.date',                        1 ],
      [ 'CURRENT_STEP',     'INT',   'cl.current_step',                1 ],
      [ 'CURRENT_STEP_NAME','STR',   'cps.name as current_step_name',  1 ],
      [ 'STEP_COLOR',       'STR',   'cps.color as step_color',        1 ],
      [ 'ADDRESS',          'STR',   'cl.address',                     1 ],
      [ 'LAST_ACTION',      'STR',   'cl.id as last_action',           1 ],
      [ 'PRIORITY' ,        'STR',   'cl.priority',                    1 ],
      [ 'COMMENTS',         'STR',   'cl.comments',                      ],
    ],
    { WHERE => 1, }
  );
  my @WHERE_RULES = ();

  if($attr->{FROM_DATE}){
    push @WHERE_RULES, "DATE >= '$attr->{FROM_DATE}'";
  }

  if($attr->{TO_DATE}){
    push @WHERE_RULES, "DATE <= '$attr->{TO_DATE}'";
  }

  if($attr->{SOURCE_ID}){
    push @WHERE_RULES, "SOURCE = '$attr->{SOURCE_ID}'";
  }

  if($attr->{PHONE_SEARCH}){
    push @WHERE_RULES, "cl.phone LIKE '\%$attr->{PHONE_SEARCH}\%'";
  }

  $WHERE .= ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
    $self->{SEARCH_FIELDS}
    cl.id as lead_id
    FROM crm_leads as cl
    LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
    LEFT JOIN crm_progressbar_steps cps ON (cps.step_number = cl.current_step)
    LEFT JOIN admins a ON (a.aid = cl.responsible)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);
    
  $self->query2(
    "SELECT COUNT(*) AS total
   FROM crm_leads as cl
   LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
   $WHERE",
    undef,
    { INFO => 1 }
  );
  
  return $list;
}


#**********************************************************
=head2 crm_add_progressbar_step() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_progressbar_step_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_progressbar_steps', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function crm_progressbar_step_info() - get information about step

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $step_info = $Cashbox->crm_progressbar_step_info({ ID => 1 });

=cut

#*******************************************************************
sub crm_progressbar_step_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM crm_progressbar_steps
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function crm_progressbar_step_delete() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Crm->crm_progressbar_step_delete( {ID => 1} );

=cut

#*******************************************************************
sub crm_progressbar_step_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_progressbar_steps', $attr);

  return $self;
}

#*******************************************************************

=head2 function crm_progressbar_step_delete() - change step's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Crm->crm_progressbar_step_delete({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub crm_progressbar_step_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_progressbar_steps',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************

=head2 function list_coming() - get list of all comings

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Cashbox->list_coming({ COLS_NAME => 1});

=cut

#*******************************************************************
sub crm_progressbar_step_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 2;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',          'INT', 'id',           1 ],
      [ 'STEP_NUMBER', 'INT', 'step_number',  1 ],
      [ 'NAME',        'STR', 'name',         1 ],
      [ 'COLOR',       'STR', 'color',        1 ],
      [ 'DESCRIPTION', 'STR', 'description',  1 ],
    ],
    { WHERE => 1, }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
    id,
    step_number,
    name,
    color,
    description
    FROM crm_progressbar_steps 
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM crm_progressbar_steps",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 leads_source_add() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_leads_sources', {%$attr});

  return $self;
}

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
 #**********************************************************
 sub leads_source_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_leads_sources',
      DATA         => $attr
    }
  );

  return $self;
 }

#**********************************************************
=head2 leads_source_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_leads_sources', $attr);

  return $self;
}

#**********************************************************
=head2 leads_source_info() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM crm_leads_sources
      WHERE id = ?;", undef, { COLS_NAME=>1, COLS_UPPER=> 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0] || {};
}

#**********************************************************
=head2 leads_source_list() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'cls.id',       1 ],
      [ 'NAME',       'STR',    'cls.name',     1 ],
      [ 'COMMENTS',   'STR',    'cls.comments', 1 ],
    ],
    { WHERE => 1, }
  );

  $self->query2(
    "SELECT
    cls.id,
    cls.name,
    cls.comments
    FROM crm_leads_sources as cls
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total
   FROM crm_leads_sources",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 progressbar_comment_add() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub progressbar_comment_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_progressbar_step_comments', {%$attr});

  return $self;
}

#**********************************************************
=head2 progressbar_comment_delete()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub progressbar_comment_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_progressbar_step_comments', $attr);

  return $self;
}

#**********************************************************
=head2 progressbar_comment_list() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub progressbar_comment_list  {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 99999;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'cpsc.id',           1 ],
      [ 'STEP_ID',    'INT',    'cpsc.step_id',      1 ],
      [ 'LEAD_ID',    'INT',    'cpsc.lead_id',      1 ],
      [ 'MESSAGE',    'STR',    'cpsc.message',      1 ],
      [ 'DATE',       'DATE',   'cpsc.date',         1 ],
      [ 'ADMIN',      'STR',    'a.id as admin',     1 ],
      [ 'ACTION',     'STR',    'ca.name as action', 1 ],
      [ 'AID',        'INT',    'cpsc.aid', 1 ],
      [ 'LEAD_FIO',   'STR',    'cl.fio as lead_fio', 1 ],
      [ 'PLANNED_DATE',       'DATE',   'cpsc.planned_date',         1 ],
    ],
    { WHERE => 1, }
  );

  $self->query2(
    "SELECT
    $self->{SEARCH_FIELDS}
    cpsc.id
    FROM crm_progressbar_step_comments cpsc
    LEFT JOIN admins a ON (a.aid = cpsc.aid)
    LEFT JOIN crm_actions ca ON (ca.id = cpsc.action_id)
    LEFT JOIN crm_leads cl ON (cl.id = cpsc.lead_id)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total
   FROM crm_progressbar_step_comments",
    undef,
    { INFO => 1 }
  );

  return $list;
}


#**********************************************************
=head2 crm_actions_add() - add new action

  Arguments:
     NAME   - name of the action
     ACTION - action
    
  Returns:
    $self

  Examples:
  
=cut
#**********************************************************
sub crm_actions_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_actions', {%$attr});

  return $self;
}

#*******************************************************************
=head2 crm_actions_change() - change action

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Crm->crm_action_change({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub crm_actions_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_actions',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************

=head2  crm_actions_delete() - delete action

  Arguments:
    $attr

  Returns:

  Examples:
    $Cashbox->crm_action_delete( {ID => 1} );

=cut

#*******************************************************************
sub crm_actions_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_actions', $attr);

  return $self;
}

#**********************************************************
=head2 crm_actions_list() - return list of actions

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_actions_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'ca.id',       1 ],
      [ 'NAME',       'STR',    'ca.name',     1 ],
      [ 'ACTION',     'STR',    'ca.action',   1 ],
    ],
    { WHERE => 1, }
  );

  $self->query2(
    "SELECT
    $self->{SEARCH_FIELDS}
    ca.id
    FROM crm_actions as ca
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total
   FROM crm_actions",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 crm_actions_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_actions_info {
  my $self = shift;
  my ($attr) = @_;

  my $action_info = $self->crm_actions_list({%$attr});

  if($action_info && ref $action_info eq 'ARRAY' && scalar @{$action_info} == 1){
    return $action_info->[0];
  }
  else{
    return ();
  }
}

1