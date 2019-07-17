package Employees;

=head1 NAME

  Employees - module for Employees configuration

=head1 SYNOPSIS

  use Employees;
  my $Employees = Employees->new($db, $admin, \%conf);

=cut

use strict;
use parent 'main';
my ($admin, $CONF);


#*******************************************************************
#  Инициализация обьекта
#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#*******************************************************************
=head2 function add_position() - add rule to table ring_rule

  Arguments:
    %$attr
      NAME             - position's name;
      SUBORDINATION    - the higher postion;

  Returns:
    $self object

  Examples:
    $Employees->add_position({
      NAME             => $FORM{NAME},
      SUBORDINATION    => $FORM{SUBORDINATION},

    });

=cut

#*******************************************************************
sub add_position {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('employees_positions', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function del_position() - delete position from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->del_position( {ID => 1} );

=cut

#*******************************************************************
sub del_position {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('employees_positions', $attr);

  return $self;
}


#**********************************************************

=head2 function position_list() - get articles list

  Arguments:
    $attr
      SUBORDINATION -
  Returns:
    @list

  Examples:
    my $list = $Employees->position_list({COLS_NAME=>1});

=cut

#**********************************************************
sub position_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{SUBORDINATION})) {
    push @WHERE_RULES, "ep.subordination='$attr->{SUBORDINATION}'";
  }

  my $WHERE = $self->search_former($attr, [
   [ 'ID',            'INT',  'ID',               1],
   [ 'POSITION',      'STR',  'position',         1],
   [ 'SUBORDINATED',  'STR',  'subordinated',     1],
   [ 'SUBORDINATION', 'INT',  'subordination',    1],
   [ 'VACANCY',       'INT',  'vacancy',          1],
  ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });


  $self->query2(
        "SELECT     
                ep.id,
                ep.position,
                (SELECT COUNT(id) FROM employees_profile WHERE position_id = ep.id) as total,
                ep.vacancy,
                (SELECT position FROM employees_positions WHERE id = ep.subordination) as subordinated,
                ep.subordination
                FROM employees_positions AS ep
                $WHERE
                ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list};
}


#**********************************************************
=head2 function position_info() - get position info

  Arguments:
    $attr
      ID - position identifier
  Returns:
    $self object

  Examples:
    my $list = $Employees->position_info({ ID => 1 });

=cut
#**********************************************************
sub position_info {
	my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query2(
      "SELECT * FROM employees_positions
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 function position_change() - get articles list

  Arguments:
    $attr
      ID            - position identifier;
      POSITION      - position name;
      SUBORDINATION - id of highier position;

  Returns:
    $self object

  Examples:
    my $list = $Employees->position_change({ ID       => 2,
                                             POSITION => "Admin",
                                             SUBORDINATION => 1 });

=cut
#**********************************************************
sub position_change {
	my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_positions',
      DATA         => $attr
    }
  );

  return $self;
}


#*******************************************************************

=head2 function add_geo() - add rule to table ring_rule

  Arguments:
    %$attr
      NAME             - position's name;
      SUBORDINATION    - the higher postion;

  Returns:
    $self object

  Examples:
    $Employees->add_geo({
      STREET_ID          => 1,
      EMPLOYEE_ID        => 2,

    });

=cut

#*******************************************************************
sub add_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('employees_geolocation', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function del_geo() - delete geolocation from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->del_geo( {EMPLOYEE_ID => 1} );

=cut

#*******************************************************************
sub del_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('employees_geolocation', $attr, {EMPLOYEE_ID => $attr->{EMPLOYEE_ID}});

  return $self;
}


#**********************************************************

=head2 function position_list() - get articles list

  Arguments:
    $attr
      SUBORDINATION -
  Returns:
    @list

  Examples:
    my $list = $Employees->position_list({COLS_NAME=>1});

=cut

#**********************************************************
sub geo_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{EMPLOYEE_ID})) {
    push @WHERE_RULES, "eg.employee_id='$attr->{EMPLOYEE_ID}'";
  }

  my $WHERE = $self->search_former($attr, [
   [ 'EMPLOYEE_ID',  'INT',  'employee_id',    1],
   [ 'STREET_ID',    'INT',  'street_id',      1],
   [ 'BUILD_ID',     'INT',  'build_id',       1],
   [ 'DISTRICT_ID',  'INT',  'district_id',    1],
  ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  $self->query2(
    "SELECT   eg.employee_id,
              eg.street_id,
              eg.build_id,
              eg.district_id
              FROM employees_geolocation AS eg
              $WHERE
              ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list};
}


#**********************************************************
# time_sheet_list()
#**********************************************************
sub time_sheet_list {
  my $self = shift;
  my ($attr) = @_;
  my @WHERE_RULES;

  if($attr->{DATE_START}){
    push @WHERE_RULES, "DATE >= '$attr->{DATE_START}'";
  }

  if($attr->{DATE_END}){
   push @WHERE_RULES, "DATE <= '$attr->{DATE_END}'";
  }

  if($attr->{BY_AID}){
   push @WHERE_RULES, "ts.aid = '$attr->{BY_AID}'"; 
  }

  my $WHERE = $self->search_former($attr, [
      ['GID',          'INT',  'a.gid',    ],
      ['POSITION',     'INT',  'a.position',    ],
      ['AID',          'INT',  'ts.aid'    ],
      ['DATE',         'DATE', 'ts.date'   ]
    ],
    { WHERE       => 1,
    }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT a.aid, a.name,
      ts.work_time,
      ts.overtime,
      ts.extra_fee,
      ts.day_type,
      ts.date,
      a.position,
      a.id AS a_login
    FROM admins a
    LEFT JOIN admins_time_sheet ts ON (a.aid=ts.aid)
    $WHERE;",
  undef,
  $attr);

  my $list = $self->{list};

  return $list;
}


#**********************************************************
=head2 time_sheet_add($attr)

=cut
#**********************************************************
sub time_sheet_add {
  my $self = shift;
  my ($attr) = @_;

  my @admins_arr = split(/,\s?/, $attr->{AIDS});
   my @MULTI_QUERY = ();

  foreach my $aid (@admins_arr) {
    if ( !defined $attr->{$aid.'_WORK_TIME'}
        && !defined $attr->{$aid.'_OVERTIME'}
        && !defined $attr->{$aid.'_EXTRA_FEE'}
        && !defined $attr->{$aid.'_DAY_TYPE'}) {
      next;
    }

    push @MULTI_QUERY, [ $aid,
                         (int($attr->{$aid.'_WORK_TIME'}) > 24) ? 24 : int($attr->{$aid.'_WORK_TIME'}),
                         (int($attr->{$aid.'_OVERTIME'})  > 24) ? 24 : int($attr->{$aid.'_OVERTIME'}),
                         (int($attr->{$aid.'_EXTRA_FEE'}) > 24) ? 24 : int($attr->{$aid.'_EXTRA_FEE'}),
                         int($attr->{$aid.'_DAY_TYPE'}),
                         $attr->{DATE}
                       ];
  }

  $self->query2("REPLACE INTO admins_time_sheet (aid, work_time, overtime, extra_fee, day_type, date)
     VALUES (?, ?, ?, ?, ?, ?);",
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#*******************************************************************
=head2 function add_question() - add new question to table employees_profile_question

  Arguments:
    %$attr
      QUESTION    - Question what you add;
      POSITION_ID - Position ID;
      ID          - Question ID;

  Returns:
    $self object

  Examples:
    $Employees->add_geo({
      QUESTION           => 'What your name?',
      POSITION_ID        => $FORM{POSITION_ID}
    });

=cut

#*******************************************************************
sub add_question {
  my $self =shift;
  my ($attr) = @_;

  $self->query_add('employees_profile_question', {%$attr});

  return $self;
}

#**********************************************************
=head2 function del_question() - delete question from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->del_question( {ID => 1} );

=cut
#**********************************************************
sub del_question {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('employees_profile_question', $attr, {ID => $attr->{ID}});


  return $self;
}

#**********************************************************
=head2 function questions_list() - get articles list

  Arguments:
    $attr
      ID - 
  Returns:
    @list

  Examples:
    my $list = $Employees->questions_list({COLS_NAME=>1});

=cut

#**********************************************************
sub questions_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
   [ 'ID',          'INT',  'pq.id',            1],
   [ 'QUESTION',    'STR',  'pq.question',      1],
   [ 'POSITION_ID', 'INT',  'pq.position_id',   1],
   [ 'POSITION',    'STR',   'ep.position',     1],

    ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  $self->query2(
    "SELECT  pq.id,
             pq.position_id,
             ep.position,
             pq.question
             FROM employees_profile_question AS pq
             LEFT JOIN employees_positions AS ep ON ep.id=pq.position_id
              $WHERE
              ORDER BY $SORT $DESC;", undef, $attr

  );

my $list=$self->{list};
return $self->{list};
}

#**********************************************************
=head2 function question_change() - 

  Arguments:
    $attr
      QUESTION    - Question what you add;
      POSITION_ID - Position ID;
      ID          - Question ID;

  Returns:
    $self object

  Examples:
    my $list = $Employees->question_change({ ID       => 2,
                                             QUESTION => "What?",
                                             POSITION_ID => 1 });

=cut
#**********************************************************
sub question_change {
  my $self =shift;
  my ($attr) = @_;

  $self->changes2({
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_profile_question',
      DATA         => $attr
    });

  return $self;
}

#**********************************************************
=head2 function question_info() - get question_info

  Arguments:
    $attr
      ID - question identifier
  Returns:
    $self object

  Examples:
    my $list = $Employees->question_info({ ID => 1 });

=cut
#**********************************************************
sub question_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query2(
      "SELECT * FROM employees_profile_question
       WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}

#*******************************************************************
=head2 function add_profile() - add new question to table employees_profile_question

  Arguments:
    %$attr
      POSITION_ID    - Position ID;
      FIO           - ;
      DATE_OF_BIRTH -
      EMAIL         -
      PHONE         -

  Returns:
    $self object

  Examples:
    $Employees->add_profile({
      POSITION_ID   - $FORM{P_ID};
      FIO           - Brolaf Anna Anna;
      DATE_OF_BIRTH -
      EMAIL         - zila@gmail.com
      PHONE         - 380876876
    });

=cut

#*******************************************************************
sub add_profile {
  my $self =shift;
  my ($attr) = @_;

  $self->query_add('employees_profile', {%$attr});

  return $self;
}

#**********************************************************
=head2 function del_profile() - delete profile from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->del_profile( {ID => 1} );

=cut
#**********************************************************
sub del_profile {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('employees_profile', $attr, {ID => $attr->{ID}});


  return $self;
}

#**********************************************************
=head2 function change_profile() - 

  Arguments:
    $attr
      POSITION_ID   - Position ID;
      FIO           - 
      DATE_OF_BIRTH -
      EMAIL         - 
      PHONE         - 

  Returns:
    $self object

  Examples:
    my $list = $Employees->change_profile({
       POSITION_ID   - $FORM{P_ID};
       FIO           - Brolaf Anna Anna;
       DATE_OF_BIRTH -
       EMAIL         - zila@gmail.com
       PHONE         - 380876876

=cut
#**********************************************************
sub change_profile {
  my $self =shift;
  my ($attr) = @_;

  $self->changes2({
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_profile',
      DATA         => $attr
    });

  return $self;
}

#**********************************************************
=head2 function profile_list() - get articles list

  Arguments:
    $attr
      POSITION_ID   - Position ID;
      FIO           - 
      DATE_OF_BIRTH -
      EMAIL         - 
      PHONE         - 
  Returns:
    @list

  Examples:
    my $list = $Employees->profile_list({COLS_NAME=>1});

=cut

#**********************************************************
sub profile_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC        = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $PG          = ($attr->{PG})        ? $attr->{PG}        : 0;


  my $WHERE = $self->search_former($attr, [
   ['ID',           'INT',  'p.id',             1],
   ['POSITION_ID', ' INT',  'p.position_id',    1],
   ['FIO',          'STR',  'p.fio',            1], 
   ['SUBORDINATION','STR',  'ep.subordination', 1],
   ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  $self->query2(
    "SELECT p.id,
            p.fio,
            p.rating,
            ep.position,
            p.phone,
            p.email,
            p.position_id
            FROM employees_profile AS p
            LEFT JOIN employees_positions AS ep ON ep.id=p.position_id
            $WHERE
            ORDER BY $SORT $DESC
            LIMIT $PG, $PAGE_ROWS;", undef, $attr
  );

my $list=$self->{list};
return $list;
}

#**********************************************************
=head2 function profile_info() - get position info

  Arguments:
    $attr
      ID - position identifier
  Returns:
    $self object

  Examples:
    my $list = $Employees->profile_info({ ID => 1 });

=cut
#**********************************************************
sub profile_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query2(
      "SELECT *
              FROM employees_profile WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}

#*******************************************************************
=head2 function add_reply() - add new question to table employees_profile_question

  Arguments:
    %$attr
      QUESTION_ID - Question ID;
      PROFILE_ID  -  Profile ID;
      REPLY       - Question reply;

  Returns:
    $self object

  Examples:
    $Employees->add_reply({
      QUESTION_ID           - ;
      PROFILE_ID -
      REPLY 
    });

=cut

#*******************************************************************
sub add_reply{
  my $self =shift;
  my ($attr) = @_;

  $self->query_add('employees_profile_reply', {%$attr});

  return $self;
}

#**********************************************************
=head2 function reply_list() - get articles list

  Arguments:
    $attr
      QUESTION_ID - Question ID;
      PROFILE_ID  -  Profile ID;
      REPLY       - Question reply;
  Returns:
    @list

  Examples:
    my $list = $Employees->reply_list({COLS_NAME=>1});

=cut

#**********************************************************
sub reply_list{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC        = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
   ['QUESTION_ID',  'INT',  'p.question_id',    1],
   ['PROFILE_ID', '  INT',  'p.profile_id',     1],
   ['REPLY',        'STR',  'p.reply',          1], 
   ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  $self->query2(
    "SELECT p.reply,
            p.profile_id,
            pq.question
            FROM employees_profile_reply AS p
            LEFT JOIN employees_profile_question AS pq ON pq.id = question_id
            $WHERE
            ORDER BY $SORT $DESC
            LIMIT $PAGE_ROWS;", undef, $attr
  );

  my $list=$self->{list};
  return $list;
}

#**********************************************************
=head2 rfid_log_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub rfid_log_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    ['ID',             'INT',        'erl.id'              ,1 ],
    ['DATETIME',       'DATE',       'erl.datetime'        ,1 ],
    ['RFID',           'INT',        'erl.rfid'            ,1 ],
    ['ADMIN',          'STR',        'a.id AS admin'       ,1 ],
    ['AID',       'INT',        'erl.aid AS admin_id' ,1 ]
  ];

  my @WHERE_RULES;
  if($attr->{DATE}){
    push @WHERE_RULES, "DATETIME >= '$attr->{DATE} 00:00:01' && DATETIME <= '$attr->{DATE} 23:59:59'";
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1, WHERE_RULES => \@WHERE_RULES });
  
  $self->query2( "SELECT $self->{SEARCH_FIELDS} erl.id
   FROM employees_rfid_log erl
   LEFT JOIN admins a ON (erl.aid=a.aid)
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return $self->{errno} ? 0 : ($self->{list} || []);
}

#*******************************************************************
=head2 function rfid_log_add() - add rfid log entry
  Arguments:
    $attr

  Returns:
   1

=cut
#*******************************************************************
sub rfid_log_add {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add('employees_rfid_log', {%$attr});
  
  return $self;
}

#*******************************************************************
=head2 function rfid_log_del() - delete rfid log entry
  Arguments:
    $attr

  Returns:
   1

=cut
#*******************************************************************
sub rfid_log_del {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del('employees_rfid_log', $attr);
  
  return 1;
}




1