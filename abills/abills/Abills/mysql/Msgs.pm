package Msgs;

=head1 NAME

 Message system
 Help Desk SQL

=cut

use strict;
our $VERSION = 7.00;
use parent qw(dbcore);
use POSIX qw(strftime);
use Admins;

my $MODULE = 'Msgs';
our Admins $admin;
my $SORT      = 1;
my $DESC      = '';
my $PG        = 0;
my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  $admin    = shift;
  my $CONF  = shift;

  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);

  $self->{db}   = $db;
  $self->{admin}= $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head1 messages_new($attr) - Show new message

=cut
#**********************************************************
sub messages_new {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLE   = '';
  my $fields      = '';

  if ($attr->{USER_READ}) {
    push @WHERE_RULES, "m.user_read='$attr->{USER_READ}' AND admin_read>'0000-00-00 00:00:00' AND m.inner_msg='0'";
    $fields = 'count(*) AS total, \'\', \'\', max(m.id), m.chapter, m.id, 1';
  }
  elsif($attr->{ADMIN_UNREAD}) {
    $fields = 'COUNT(*) AS total, \'\', \'\', max(m.id), m.chapter, m.id, 1';
  }
  elsif ($attr->{ADMIN_READ}) {
    $fields = "SUM(if(admin_read='0000-00-00 00:00:00', 1, 0)) AS admin_unread_count,
     SUM(IF(plan_date=curdate(), 1, 0)) AS today_plan_count,
     SUM(IF(state = 0, 1, 0)) AS open_count,
    1,1,1,1
      ";
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, "m.uid='$attr->{UID}'";
  }

  if ($attr->{CHAPTER}) {
    $attr->{CHAPTER} =~ s/,/;/g;
    push @WHERE_RULES, @{ $self->search_expr($attr->{CHAPTER}, 'INT', 'c.id') };
  }

  if (defined($attr->{STATE}) && $attr->{STATE} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state') };
  }

  if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GID})";
    $EXT_TABLE = "LEFT JOIN users u  ON (m.uid = u.uid)";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  if ($attr->{SHOW_CHAPTERS}) {
    $self->query("SELECT c.id, c.name,
     SUM(IF(admin_read='0000-00-00 00:00:00', 1, 0)) AS admin_unread_count,
     SUM(IF(plan_date=CURDATE(), 1, 0)) AS today_plan_count,
     SUM(IF(state = 0, 1, 0)) AS open_count,
     SUM(IF(resposible = $admin->{AID}, 1, 0)) AS resposible_count,
     1, 1, 1
    FROM msgs_chapters c
    LEFT JOIN msgs_messages m ON (m.chapter= c.id AND m.state=0)
    $EXT_TABLE
    $WHERE
    GROUP BY c.id;",
    undef,
    $attr
    );

    return $self->{list};
  }

  if ($attr->{GID}) {
    $self->query("SELECT $fields
      FROM (msgs_messages m, users u)
      $WHERE and u.uid=m.uid GROUP BY 7;"
      );
  }
  else {
    $self->query("SELECT $fields
      FROM msgs_messages m
      $WHERE GROUP BY 7;"
    );
  }

  if ($self->{TOTAL}) {
    ($self->{UNREAD}, $self->{TODAY}, $self->{OPENED}, $self->{LAST_ID}, $self->{CHAPTER}, $self->{MSG_ID}) = @{ $self->{list}->[0] };
  }

  return $self;
}

#**********************************************************
=head2 messages_list($attr) -  Show message

  Arguments:
    $attr

  Returns:
     array_hash_ref

=cut
#**********************************************************
sub messages_list {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS})? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})     ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})     ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})       ? $attr->{PG}        : 0;

  delete $self->{COL_NAMES_ARR};
  $self->{EXT_TABLES} = '';
  my @WHERE_RULES = ();

  if ($attr->{PLAN_FROM_DATE}) {
    push @WHERE_RULES, "(DATE_FORMAT(m.plan_date, '%Y-%m-%d')>='$attr->{PLAN_FROM_DATE}' and DATE_FORMAT(m.plan_date, '%Y-%m-%d')<='$attr->{PLAN_TO_DATE}')";
  }
  elsif ($attr->{PLAN_WEEK}) {
    push @WHERE_RULES, "(WEEK(m.plan_date)=WEEK(CURDATE()) and DATE_FORMAT(m.plan_date, '%Y')=DATE_FORMAT(CURDATE(), '%Y'))";
  }
  elsif ($attr->{PLAN_MONTH}) {
    push @WHERE_RULES, "DATE_FORMAT(m.plan_date, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')";
  }

  if ($attr->{CHAPTERS_DELIGATION}) {
    my @WHERE_RULES_pre = ();
    while (my ($chapter, $deligation) = each %{ $attr->{CHAPTERS_DELIGATION} }) {
      my $privileges = '';
      if ($attr->{PRIVILEGES}) {
        if ($attr->{PRIVILEGES}->{$chapter} <= 2) {
          $privileges = " AND (m.resposible=0 or m.aid='$admin->{AID}' OR m.resposible='$admin->{AID}')";
        }
      }
      push @WHERE_RULES_pre, "(m.chapter='$chapter' AND m.deligation<='$deligation' $privileges)";
    }
    push @WHERE_RULES, "(" . join(" OR ", @WHERE_RULES_pre) . ")";
  }

  if (!defined $attr->{STATE}){

  }
  elsif ($attr->{STATE} !~ /^\d$/) {

    if ( $attr->{STATE} eq '_SHOW' && $attr->{SHOW_UNREAD} ) {
      push @WHERE_RULES, "(m.state=0 OR m.admin_read='0000-00-00 00:00:00')";
    }
    else{
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state') };
    }
  }
  elsif ($attr->{STATE} == 0 && $attr->{SHOW_UNREAD}) {
    push @WHERE_RULES, "(m.state=0 OR m.admin_read='0000-00-00 00:00:00')";
  }
  elsif ($attr->{STATE} == 0 && $attr->{USER_UNREAD}) {
    push @WHERE_RULES, "(m.state=0 OR m.state=6 OR m.user_read='0000-00-00 00:00:00')";
  }
  elsif ($attr->{STATE} == 4) {
    push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'm.admin_read') };
  }
  elsif ($attr->{STATE} == 7) {
    push @WHERE_RULES, @{ $self->search_expr(">0", 'INT', 'm.deligation') };
  }
  elsif ($attr->{STATE} == 8) {
    push @WHERE_RULES, @{ $self->search_expr($admin->{AID}, 'INT', 'm.resposible') };
    push @WHERE_RULES, @{ $self->search_expr("0;3;6", 'INT', 'm.state') };
    delete $attr->{DELIGATION};
  }
  elsif ($attr->{STATE} == 12) {
    my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
    push @WHERE_RULES, @{ $self->search_expr(">0000-00-00;<$DATE", 'INT', 'm.plan_date') };
    push @WHERE_RULES, @{ $self->search_expr('0',      'INT', 'm.state') };
  }
  else {
    push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state') };
  }

  if ($attr->{GET_NEW}) {
  	push @WHERE_RULES, " ((m.date > NOW() - INTERVAL $attr->{GET_NEW} second) OR (r.datetime > NOW() - INTERVAL $attr->{GET_NEW} SECOND)) ";
  }

  if ($admin->{GID}) {
    $attr->{SKIP_GID}=1;
    $admin->{GID} =~ s/;/,/g;
    push @WHERE_RULES, "(u.gid IN ($admin->{GID}) OR m.gid IN ($admin->{GID}))";
  }

  if ($attr->{SEARCH_MSGS_BY_WORD}) {
    push @WHERE_RULES, "(m.subject LIKE '%$attr->{SEARCH_MSGS_BY_WORD}%' OR m.message LIKE '%$attr->{SEARCH_MSGS_BY_WORD}%' OR r.text LIKE '%$attr->{SEARCH_MSGS_BY_WORD}%')";
  }

  $admin->{permissions}->{0}->{8}=1;
  my $WHERE = $self->search_former($attr, [
      ['MSG_ID',            'INT',      'm.id',   ],
      ['CLIENT_ID',         'STR',      'if(m.uid>0, u.id, mg.name)', 'if(m.uid>0, u.id, mg.name) AS client_id' ],
      ['SUBJECT',           'STR',      'm.subject',           1 ],
      ['CHAPTER_NAME',      'STR',      'mc.name', 'mc.name AS chapter_name' ],
      ['CHAPTER',           'INT',      'm.chapter'              ],
      ['DATETIME',          'DATE',     "m.date AS datetime",  1 ],
      ['DATE',              'DATE',     "DATE_FORMAT(m.date, '%Y-%m-%d')",  "DATE_FORMAT(m.date, '%Y-%m-%d') AS date" ],
      ['STATE',             'INT',      '',            'm.state' ],
      ['PRIORITY',          'INT',      'm.priority',          1 ],
      ['RESPOSIBLE_ADMIN_LOGIN', 'STR', 'ra.id', 'ra.id AS resposible_admin_login' ],
      ['LAST_REPLIE_DATE', 'DATE',      'MAX(r.datetime)  AS last_replie_date', 1],
      ['PLAN_DATE_TIME',   'DATE',      "CONCAT(m.plan_date, ' ', m.plan_time)", "CONCAT(m.plan_date, ' ', m.plan_time) AS plan_date_time" ],
      ['DISABLE',          'INT',       'u.disable',           1 ],
      ['INNER_MSG',        'INT',       'm.inner_msg',         1 ],
      ['MESSAGE',          'STR',       'm.message',           1 ],
      ['REPLY',            'STR',       'm.user_read',         1 ],
      ['MSG_PHONE',        'STR',       'm.phone', 'm.phone AS msg_phone' ],
      ['USER_READ',        'INT',       'm.user_read',         1 ],
      ['CLOSED_DATE',      'DATE',      'm.closed_date',       1 ],
      ['RUN_TIME',         'DATE',      'SEC_TO_TIME(SUM(r.run_time))',  'SEC_TO_TIME(SUM(r.run_time)) AS run_time' ],
      ['DONE_DATE',        'DATE',      'm.done_date',         1 ],
      ['UID',              'INT',       'm.uid',                 ],
      ['DELIGATION',       'INT',       'm.delegation',        1 ],
      ['RESPOSIBLE',       'INT',       'm.resposible',          ],
      ['PLAN_DATE',        'DATE',      'm.plan_date',         1 ],
      ['SOFT_DEADLINE',    'DATE',      "DATEDIFF(curdate(), m.date)", "DATEDIFF(curdate(), m.date) as soft_deadline" ],
      ['HARD_DEADLINE',    'DATE',      "DATEDIFF(curdate(), MAX(r.datetime))", "DATEDIFF(curdate(), MAX(r.datetime)) as hard_deadline" ],
      ['ADMIN_READ',       'INT',       'm.admin_read',        1 ],
      #['PLAN_DATE',       'INT',       "DATE_FORMAT(plan_date, '%w')", "DATE_FORMAT(plan_date, '%w') AS plan_date", 1 ],
      ['PLAN_TIME',        'INT',       'm.plan_time',         1 ],
      ['DISPATCH_ID',      'INT',       'm.dispatch_id',       1 ],
      ['IP',               'IP',        'm.ip',  'INET_NTOA(m.ip) AS ip'         ],
      ['FROM_DATE|TO_DATE','DATE',      "DATE_FORMAT(m.date, '%Y-%m-%d')"        ],
      ['ADMIN_LOGIN',      'INT',       'a.aid',  'a.id AS admin_login',       1 ],
      ['A_NAME',           'INT',       'a.name', 'a.name AS admin_name',      1 ],
      ['REPLIES_COUNTS',   '',          '',       'IF(r.id IS NULL, 0, COUNT(r.id)) AS replies_counts' ],
      ['RATING',           'INT',       'm.rating',                            1 ],
      ['RATING_COMMENT',   'STR',       'm.comment',                           1 ],
      ['STATE_ID',         'INT',       'm.state', 'm.state AS state_id'         ],
      ['PRIORITY_ID',      'INT',       'm.priority', 'm.priority AS priority_id'],
      ['CHG_MSGS',         'INT',       'm.id', 'm.id AS chg_msgs'               ],
      ['DEL_MSGS',         'INT',       'm.id', 'm.id AS del_msgs'               ],
      ['PAR',              'INT',       'm.par',                               1 ],
      ['MSGS_TAGS',        'INT',       'qrt.quick_reply_id', 'qrt.quick_reply_id AS msgs_tags' ],
      ['DOWNTIME',         '','',       "TIMEDIFF(IF(r.datetime <> '0000-00-00 00:00:00', r.datetime, NOW()), m.date) AS downtime"],
      ['REPLY_TEXT',       'STR',       'r.text', 'GROUP_CONCAT(r.text) AS reply_text'],
      ['MONTH',            'DATE',      'DATE_FORMAT(m.date, \'%Y-%m\')'         ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'GID', 'UID' ],
      USE_USER_PI       => 1
    }
    );

  my $EXT_TABLES = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /r\./ || $WHERE =~ /r\./) {
    $EXT_TABLES .= "LEFT JOIN msgs_reply r ON (m.id=r.main_msg)";
  }

  if ($self->{SEARCH_FIELDS} =~ /qrt\./ || $WHERE =~ /qrt\./) {
    $EXT_TABLES .= "LEFT JOIN msgs_quick_replys_tags qrt ON (m.id=qrt.msg_id)";
  }

  if ($self->{SEARCH_FIELDS} =~ /mc\./ || $WHERE =~ /mc\./) {
    $EXT_TABLES .= "LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)";
  }

  #Old section
#  SELECT m.id, $self->{SEARCH_FIELDS}
#       m.uid,
#    a.aid,
#    m.chapter AS chapter_id,
#       m.deligation,
#    m.admin_read,
#       m.inner_msg,
#    m.plan_time,
#       m.resposible,
#    u.id AS user_name

  $self->query("SELECT m.id, $self->{SEARCH_FIELDS}
       m.uid,
       a.aid,
       m.chapter AS chapter_id,
       m.deligation,
       m.inner_msg,
       m.plan_time,
       m.resposible,
       u.id AS user_name
      FROM msgs_messages m
      LEFT JOIN users u ON (m.uid=u.uid)
      $EXT_TABLES
      LEFT JOIN admins a ON (m.aid=a.aid)
      LEFT JOIN groups mg ON (m.gid=mg.gid)
      LEFT JOIN admins ra ON (m.resposible=ra.aid)
      $WHERE
      GROUP BY m.id
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(DISTINCT m.id) AS total,
  COUNT(DISTINCT IF(m.admin_read = '0000-00-00 00:00:00', m.id, 0)) AS in_work,
  COUNT(DISTINCT IF(m.state = 0, m.id, 0)) AS open,
  COUNT(DISTINCT IF(m.state = 1, m.id, 0)) AS unmaked,
  COUNT(DISTINCT IF(m.state = 2, m.id, 0)) AS closed
    FROM msgs_messages m
    LEFT JOIN users u ON (m.uid=u.uid)
    $EXT_TABLES
    $WHERE",
    undef,
    { INFO => 1 }
    );

  return $list;
}

#**********************************************************
=head2 message_add($attr)

=cut
#**********************************************************
sub message_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_messages', {
    %$attr,
    CLOSED_DATE => ($attr->{STATE} == 1 || $attr->{STATE} == 2) ? 'NOW()' : "0000-00-00 00:00:00",
    AID         => ($attr->{USER_SEND}) ? 0 : $admin->{AID},
    DATE        => 'NOW()'
  });

  $self->{MSG_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
=head2 message_del($attr)

  Arguments:
    $attr
      UID
      ID

  Results:
    $self

=cut
#**********************************************************
sub message_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_messages', $attr, {
    uid  => $attr->{UID}
  });

  $self->message_reply_del({
    MAIN_MSG => $attr->{ID},
    UID      => $attr->{UID}
  });

  if ($attr->{ID}) {
    my @id_arr = split(/,/, $attr->{ID});
    $self->query("DELETE FROM msgs_attachments
      WHERE message_id IN (". join(',', map { '?' } @id_arr) . ")
      AND message_type=0", 'do', { Bind => \@id_arr }
    );

    $self->query("DELETE FROM msgs_watch
      WHERE main_msg IN (". join(',', map { '?' } @id_arr) . ")", 'do', { Bind => \@id_arr }
    );
  }

  if ($attr->{UID}) {
    $self->query("
        DELETE FROM msgs_attachments 
        WHERE create_by = ?
        AND message_type=0",
      'do',
      { Bind => [ $attr->{UID} ] });

    $self->query("UPDATE msgs_unreg_requests SET
      state = 0,
      uid   = 0
      WHERE uid = ? ", 'do', { Bind => [ $attr->{UID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 message_info($id, $attr)

=cut
#**********************************************************
sub message_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = ($attr->{UID}) ? "AND m.uid='$attr->{UID}'" : '';

  $self->query("SELECT m.*,
  INET_NTOA(m.ip) AS ip,
  u.id AS login,
  a.id AS a_name,
  mc.name AS chapter_name,
  g.name AS fg_name,
  SEC_TO_TIME(SUM(r.run_time)) AS ticket_run_time,
  MAX(r.datetime) AS last_replie_date
    FROM msgs_messages m
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN users u ON (m.uid=u.uid)
    LEFT JOIN admins a ON (m.aid=a.aid)
    LEFT JOIN groups g ON (m.gid=g.gid)
    LEFT JOIN msgs_reply r ON (m.id=r.main_msg)
  WHERE m.id= ? $WHERE
  GROUP BY m.id;",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  $self->attachment_info({ MSG_ID => $self->{ID} });

  return $self;
}

#**********************************************************
=head2 message_change($attr)

=cut
#**********************************************************
sub message_change {
  my $self = shift;
  my ($attr) = @_;

  #delete $attr->{UID};

  $attr->{PAR}    = $attr->{PARENT_ID} if ($attr->{PARENT_ID});
  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'msgs_messages',
      DATA            => $attr,
      EXT_CHANGE_INFO => "MSG_ID:$attr->{ID}"
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 chapters_list($attr)

=cut
#**********************************************************
sub chapters_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, [
      ['INNER_CHAPTER',  'INT',  'mc.inner_chapter' ],
      ['NAME',           'STR',  'mc.name'          ],
      ['CHAPTER',        'STR',  'mc.id'            ],
      ['MSG_COUNTS',     '',     'COUNT(m.chapter) AS msg_counts',   'COUNT(m.chapter) AS msg_counts' ],
      ['RESPONSIBLE',    'INT',   'mc.responsible'  ],
      ['AUTOCLOSE',      'INT',   'mc.autoclose'    ],
    ],
    { WHERE => 1 }
  );

  my $EXT_TABLES = $self->{EXT_TABLES};

 if ($self->{SEARCH_FIELDS} =~ /m\./ || $WHERE =~ /m\./) {
    $EXT_TABLES .= "LEFT JOIN msgs_messages m ON (mc.id=m.chapter)";
  }

  $self->query("SELECT mc.id, $self->{SEARCH_FIELDS} mc.name, mc.inner_chapter, mc.responsible, mc.autoclose, ra.id AS admin_login
    FROM msgs_chapters mc
    LEFT JOIN admins ra ON (ra.aid=mc.responsible)
    $EXT_TABLES
    $WHERE
    GROUP BY mc.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  if($self->{TOTAL}){
    return $self->{list};
  }

  return [];
}

#**********************************************************
=head2 chapter_add($attr)

=cut
#**********************************************************
sub chapter_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_chapters', $attr);

  $admin->system_action_add("MGSG_CHAPTER:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 chapter_del($attr)

=cut
#**********************************************************
sub chapter_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_chapters', $attr);

  return $self;
}

#**********************************************************
=head2 chapter_info($id, $attr)

=cut
#**********************************************************
sub chapter_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_chapters
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 chapter_change($attr)

=cut
#**********************************************************
sub chapter_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_chapters',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 admins_list($attr)

=cut
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['AID',          'INT',  'ma.aid'             ],
      ['EMAIL_NOTIFY', 'INT',  'ma.email_notify'    ],
      ['EMAIL',        'STR',  'a.email',           ],
      ['CHAPTER_ID',   'INT',  'ma.chapter_id'      ],
      ['DISABLE',      'INT',  'a.disable'          ]
    ],
    { WHERE => 1,
    }
    );

  $self->query("SELECT a.id AS admin_login,
     mc.name AS chapter_name,
     ma.priority,
     ma.deligation_level,
     a.aid,
     if(ma.chapter_id IS NULL, 0, ma.chapter_id) AS chapter_id,
     ma.email_notify,
     a.email
    FROM admins a
    LEFT join msgs_admins ma ON (a.aid=ma.aid)
    LEFT join msgs_chapters mc ON (ma.chapter_id=mc.id)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 admin_change($attr)

=cut
#**********************************************************
sub admin_change {
  my $self = shift;
  my ($attr) = @_;

  $self->admin_del({ AID => $attr->{AID} });

  my @chapters = split(/, /, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@chapters) {
    push @MULTI_QUERY, [
       $attr->{AID},
       $id,
       $attr->{ 'PRIORITY_' . $id },
       $attr->{ 'EMAIL_NOTIFY_' . $id } || 0,
       $attr->{ 'DELIGATION_LEVEL_' . $id }
      ];
  }

  $self->query("INSERT INTO msgs_admins (aid, chapter_id, priority, email_notify, deligation_level)
        VALUES (?, ?, ?, ?, ?);",
        undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 chapter_del($attr)

=cut
#**********************************************************
sub admin_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_admins', undef, { aid => $attr->{AID} });

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub admin_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_chapters WHERE id= ? ",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
    );

  return $self;
}

#**********************************************************
=head2 message_reply_del($attr)

=cut
#**********************************************************
sub message_reply_del {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_FIELDS = ();
  my @WHERE_VALUES = ();

  if ($attr->{MAIN_MSG}) {
    my @id_arr = split(/,/, $attr->{MAIN_MSG});
    push @WHERE_FIELDS, "main_msg IN (". join(',', map { '?' } @id_arr) .')';
    push @WHERE_VALUES, @id_arr;

    $self->query("
        DELETE FROM msgs_attachments 
        WHERE message_id IN (SELECT id FROM msgs_reply WHERE $WHERE_FIELDS[0])
        AND message_type=1",
      'do',
      { Bind => \@WHERE_VALUES }
    );
  }
  elsif ($attr->{ID}) {
    push @WHERE_FIELDS, 'id = ?';
    push @WHERE_VALUES, $attr->{ID};

    $self->query("DELETE FROM msgs_attachments WHERE message_id= ? and message_type=1", 'do', { Bind => [ $attr->{ID} ]  });
  }
  elsif ($attr->{UID}) {
    push @WHERE_FIELDS, 'uid = ?';
    push @WHERE_VALUES, $attr->{UID};

    $self->query("
        DELETE FROM msgs_attachments 
        WHERE message_id IN (SELECT id FROM msgs_reply WHERE uid = ?)
        AND message_type=1",
      'do',
      { Bind => [ $attr->{UID} ] }
    );
  }

  if($#WHERE_FIELDS == -1) {
    return $self;
  }

  $self->query("DELETE FROM msgs_reply WHERE ". join(' AND ', @WHERE_FIELDS),
    'do', { Bind => \@WHERE_VALUES });

  return $self;
}

#**********************************************************
=head2 messages_list($attr)

=cut
#**********************************************************
sub messages_reply_list {
  my $self = shift;
  my ($attr) = @_;

#  $PAGE_ROWS = ($attr->{PAGE_ROWS})     ? $attr->{PAGE_ROWS} : 25;
#  $SORT      = ($attr->{SORT})          ? $attr->{SORT}      : 1;
#  $DESC      = (defined($attr->{DESC})) ? $attr->{DESC}      : 'DESC';

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "mr.datetime BETWEEN '$attr->{FROM_DATE} 00:00:00' AND '$attr->{TO_DATE} 23:59:59'";
  }

  my $WHERE = $self->search_former($attr, [
      ['ID',           'INT',  'mr.id',          ],
      ['MSG_ID',       'INT',  'mr.main_msg',   1],
      ['LOGIN',        'INT',  'u.id'            ],
      ['UID',          'INT',  'm.uid'           ],
      ['INNER_MSG',    'INT',  'mr.inner_msg'    ],
      ['REPLY',        'STR',  'm.reply',        ],
      ['STATE',        'INT',  'm.state'         ],
      ['FILE_NAME',    'INT',  'ma.filename',       ],
      ['CONTENT_SIZE', 'INT',  'ma.content_size', 1 ],
      ['CONTENT_TYPE', 'INT',  'ma.content_type', 1 ],
      ['ATTACH_COORDX','INT',  'ma.coordx',       1 ],
      ['ATTACH_COORDY','INT',  'ma.coordy',       1 ],
      # ['FROM_DATE|TO_DATE',   'DATE',  "DATE_FORMAT(mr.datetime, '%Y-%m-%d')" ],
      ['ADMIN',        'STR',  'a.id', 'a.id AS admin', 1],
      ['AID',          'INT',  'mr.aid',  1],
      ['DATETIME',   'DATE',  "mr.datetime", '1' ],
      ['SURVEY_ID',    'INT',  'mr.survey_id',  1],
    ],
    {
     WHERE_RULES      => \@WHERE_RULES,
     WHERE             => 1,
    }
    );


  $self->query("SELECT mr.id,
    $self->{SEARCH_FIELDS}
    mr.datetime,
    mr.text,
    if(mr.aid>0, a.id, u.id) AS creator_id,
    mr.status,
    mr.caption,
    INET_NTOA(mr.ip) AS ip,
    ma.filename,
    ma.content_size,
    ma.id AS attachment_id,
    mr.uid,
    SEC_TO_TIME(mr.run_time) AS run_time,
    mr.aid,
    mr.inner_msg,
    mr.survey_id
    FROM msgs_reply mr
    LEFT JOIN users u ON (mr.uid=u.uid)
    LEFT JOIN admins a ON (mr.aid=a.aid)
    LEFT JOIN msgs_attachments ma ON (mr.id=ma.message_id and ma.message_type=1 )
    $WHERE
    GROUP BY mr.id
    ORDER BY datetime ASC;",
  undef,
  $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 message_reply_add($attr)

  Arguments:
    $attr - hash_ref
      ID               - message reply is attached to
      REPLY_SUBJECT
      REPLY_TEXT
      STATE            - state that was sent with reply
      REPLY_INNER_MSG  - is this reply inner ( administrators visible only )
      
  Returns:
    $self

=cut
#**********************************************************
sub message_reply_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_reply', {
        %$attr,
        MAIN_MSG  => $attr->{ID},
        CAPTION   => $attr->{REPLY_SUBJECT},
        TEXT      => $attr->{REPLY_TEXT},
        DATETIME  => 'NOW()',
        STATUS    => $attr->{STATE},
        INNER_MSG => $attr->{REPLY_INNER_MSG},
        ID        => 'undef', # FIXME: WTF?
      });

  $self->{REPLY_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
=head2 message_reply_change()

=cut
#**********************************************************
sub message_reply_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_reply',
      DATA         => $attr,
    }
  );

  return $self;
}

#**********************************************************
=head2 attachments_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub attachments_list{
  my ($self, $attr) = @_;

  $SORT = $attr->{SORT} || 'id';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG   = $attr->{PG} || '0';
  $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  # Both values are stored in single column
  if ( $attr->{REPLY_ID} ){
    $attr->{MESSAGE_ID}   = $attr->{REPLY_ID};
    $attr->{MESSAGE_TYPE} = 1;
  }

  my $search_columns = [
    ['ID',             'INT',    'ma.id'            ,1 ],
    ['MESSAGE_ID',     'INT',    'ma.message_id'    ,1 ],
    ['FILENAME',       'STR',    'ma.filename'      ,1 ],
    ['CONTENT_SIZE',   'STR',    'ma.content_size'  ,1 ],
    ['CONTENT_TYPE',   'STR',    'ma.content_type'  ,1 ],
    ['CONTENT',        'STR',    'ma.content'       ,1 ],
    ['CREATE_TIME',    'DATE',   'ma.create_time'   ,1 ],
    ['CREATE_BY',      'INT',    'ma.create_by'     ,1 ],
    ['CHANGE_TIME',    'DATE',   'ma.change_time'   ,1 ],
    ['CHANGE_BY',      'INT',    'ma.change_by'     ,1 ],
    ['MESSAGE_TYPE',   'INT',    'ma.message_type'  ,1 ],
    ['COORDX',         'INT',    'ma.coordx'        ,1 ],
    ['COORDY',         'INT',    'ma.coordy'        ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query( "SELECT $self->{SEARCH_FIELDS} ma.id
   FROM msgs_attachments ma
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr // {}}}
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 attachment_add($attr) Add attachments

=cut
#**********************************************************
sub attachment_add {
  my $self = shift;
  my ($attr) = @_;

  # Message type and reply id are stored in single column ( Curious )
  my @msgs_ids = ($attr->{REPLY_ID})
                   ? $attr->{REPLY_ID}
                   : (ref $attr->{MSG_ID} eq 'ARRAY') ? @{ $attr->{MSG_ID} } : ($attr->{MSG_ID});

  foreach my $id ( @msgs_ids ) {

    $self->query(
      "INSERT INTO msgs_attachments
      (message_id, filename, content_type, content_size, content,
       create_time, create_by, change_time, change_by, message_type,
       coordx, coordy)
       VALUES
      (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, '0', ?, ?, ?)",
      'do',
      { Bind => [
          $id,
          $attr->{FILENAME},
          $attr->{CONTENT_TYPE},
          $attr->{FILESIZE} || 0,
          $attr->{CONTENT},
          $attr->{UID} || 0,
          $attr->{MESSAGE_TYPE} || 0,
          $attr->{COORDX} || 0,
          $attr->{COORDY} || 0
        ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 attachment_change($attr) change attachments

=cut
#**********************************************************
sub attachment_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_attachments',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 attachment_info($attr)

=cut
#**********************************************************
sub attachment_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{MSG_ID}) {
    $WHERE = "message_id='$attr->{MSG_ID}' and message_type='0'";
  }
  elsif ($attr->{REPLY_ID}) {
    $WHERE = "message_id='$attr->{REPLY_ID}' and message_type='1'";
  }
  elsif ($attr->{ID}) {
    $WHERE = "id='$attr->{ID}'";
  }

  if ($attr->{UID}) {
    $WHERE .= " AND (create_by='$attr->{UID}' or create_by='0')";
  }

  if (! $WHERE ) {
    return $self;
  }

  $self->query("SELECT id AS attachment_id, filename,
    content_type,
    content_size,
    content
   FROM  msgs_attachments
   WHERE $WHERE",
   undef,
   { INFO => 1 }
  );

  if ($self->{errno} && $self->{errno} == 2) {
    $self->{errno} = undef;
  }

#  if ($self->{conf}{MSGS_ATTACH2FILE} && $self->{CONTENT} && $self->{CONTENT} =~ /^FILE: (..\/)*([a-zA-Z0-9_\-.]+)/){
#    require Attach;
#    Attach->import();
#
#    my $Attach = Attach->new($self->{db}, $self->{admin}, $self->{conf}, {
#        ATTACH_PATH => ($self->{conf}->{MSGS_ATTACH2FILE} ne '1')
#                         ? $self->{conf}->{MSGS_ATTACH2FILE}
#                         : 'msgs/'
#      });
#
#    $self->{CONTENT} = $Attach->read_file_from_disk({
#      UID => $attr->{UID},
#
#    })
#  }

  return $self;
}

#**********************************************************
=head2 attachment_del($attachment_id) - deletes attachment by id

  Arguments:
    $attachment_id -
    
  Returns:
    1
    
=cut
#**********************************************************
sub attachment_del {
  my ($self, $attachment_id) =  @_;

  $self->query_del('msgs_attachments', { ID => $attachment_id });

  return 1;
}

#**********************************************************
=head2 messages_reports($attr)

=cut
#**********************************************************
sub messages_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my $GROUP_BY = '1';
  my %EXT_TABLE_JOINS_HASH = ();
  my $ext_fields = '';

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();

  my $date      = 'DATE_FORMAT(m.date, \'%Y-%m-%d\') AS date';
  if ($attr->{TYPE}) {
    my $type = $attr->{TYPE};
    if ($type eq 'ADMINS') {
      $date       = 'a.id AS admin_name';
      $EXT_TABLE_JOINS_HASH{admins}=1;
    }
    elsif ($type eq 'USER') {
      $date      = 'u.id AS login';
      $EXT_TABLE_JOINS_HASH{users}=1;
    }
    elsif ($type eq 'RESPOSIBLE') {
      $date      = "a.id AS admin_name";
      $EXT_TABLE_JOINS_HASH{admins}=1;
    }
    elsif ($type eq 'HOURS') {
      $date      = 'DATE_FORMAT(m.date, \'%H\') AS hours';
    }
    elsif ($type eq 'CHAPTERS') {
      $date      = "c.name AS chapter_name";
      $EXT_TABLE_JOINS_HASH{chapters}=1;
    }
    elsif ($type eq 'DISTRICT') {
      $date = "districts.name AS district_name";
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
      $EXT_TABLE_JOINS_HASH{districts}=1;
    }
    elsif ($type eq 'STREET') {
      $date = "streets.name AS street_name";
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    elsif ($type eq 'BUILD') {
      $date = "CONCAT(streets.name, '$self->{conf}->{BUILD_DELIMITER}', builds.number) AS build";
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    elsif ($type eq 'REPLY') {
      $ext_fields = "COUNT(r.id) AS replies_count, ";
      $EXT_TABLE_JOINS_HASH{reply}=1;
    }
    elsif ($type eq 'PER_MONTH') {
      $date = "DATE_FORMAT(m.date, \'%Y-%m\') AS month ";
    }
    #else {
    #  $date = "u.id AS login";
    #  $EXT_TABLE_JOINS_HASH{users}=1;
    #}
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, "DATE_FORMAT(m.date, '%Y-%m-%d')='$attr->{DATE}'";
    $date = "DATE_FORMAT(m.date, '%Y-%m-%d') AS date";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(m.date, '%Y-%m-%d')>='$from' AND DATE_FORMAT(m.date, '%Y-%m-%d')<='$to'";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "DATE_FORMAT(m.date, '%Y-%m')='$attr->{MONTH}'";
    $date = "DATE_FORMAT(m.date, '%Y-%m-%d') AS date";
  }
  else {
    $date = "DATE_FORMAT(m.date, '%Y-%m') AS month";
  }

  my $WHERE = $self->search_former($attr, [
      [ 'LOGIN',        'STR',  'u.id',   ],
      [ 'STATUS',       'INT',  'm.state' ],
      [ 'GID',          'INT',  'm.gid',  ],
      [ 'UID',          'INT',  'm.uid',  ],
      [ 'MSG_ID',       'INT',  'm.id',   ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
    }
  );

  my $EXT_TABLES = $self->mk_ext_tables({
    JOIN_TABLES     => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN  => [
      'users:LEFT JOIN users u ON (m.uid=u.uid)',
      'admins:LEFT JOIN admins a ON (m.resposible=a.aid)',
      'chapters:LEFT JOIN msgs_chapters c ON (m.chapter=c.id)',
      'reply:LEFT JOIN msgs_reply r ON (m.id=r.main_msg)',
    ]
  });

  $self->query("SELECT $date,
   COUNT(DISTINCT IF (m.state=0, m.id, NULL)) AS open,
   COUNT(DISTINCT IF (m.state=1, m.id, NULL)) AS unmaked,
   COUNT(DISTINCT IF (m.state=2, m.id, NULL)) AS maked,
   COUNT(DISTINCT IF (m.state>2, m.id, NULL)) AS other,
   COUNT(DISTINCT m.id) AS total_msgs,
   SEC_TO_TIME(SUM(mr.run_time)) AS run_time,
   $ext_fields
   m.uid,
   m.chapter
  FROM msgs_messages m
  LEFT JOIN  msgs_reply mr ON (m.id=mr.main_msg)
  $EXT_TABLES
  $WHERE
  GROUP BY $GROUP_BY
  ORDER BY $SORT $DESC ; ",
  undef,
  $attr
  );

  #  LIMIT $PG, $PAGE_ROWS;");
  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT COUNT(DISTINCT m.id) AS total,
      SUM(IF (m.state=0, 1, 0)) AS open,
      SUM(IF (m.state=1, 1, 0)) AS unmaked,
      SUM(IF (m.state=2, 1, 0)) AS maked,
      SUM(IF (m.state>2, 1, 0)) AS other,
      SEC_TO_TIME(SUM(t1.run_time)) AS run_time,
      SUM(IF(m.admin_read = '0000-00-00 00:00:00', 1, 0)) AS in_work
     FROM msgs_messages m
     LEFT JOIN (SELECT mr.main_msg, SUM(mr.run_time) as run_time FROM msgs_reply mr GROUP BY mr.main_msg) as t1 ON (m.id=t1.main_msg)
     $EXT_TABLES
    $WHERE;",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 dispatch_list($attr)

=cut
#**********************************************************
sub dispatch_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'DESC';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if (defined($attr->{STATE}) && $attr->{STATE} ne '') {
    if ($attr->{STATE} == 4) {
      push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'm.admin_read') };
    }
    else {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'd.state') };
    }
  }

  my $WHERE = $self->search_former($attr, [
      ['NAME',        'STR',  'd.name'           ],
      ['CHAPTER',     'INT',  'd.id'             ],
      ['PLAN_DATE',   'DATE', 'd.plan_date'      ],
      ['MSGS_DONE',   'INT',  'SUM(IF(m.state=2, 1, 0))', 'SUM(IF(m.state=2, 1, 0)) AS msgs_done' ],
      ['CLOSED_DATE', 'DATE', 'd.closed_date', 1 ],
      ['RESPOSIBLE',  'INT',  'd.resposible',  1 ],
      ['AID',         'INT',  'd.aid',         1 ]
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("SELECT d.id,
     d.comments,
     d.plan_date,
     d.created,
     dc.name,
     $self->{SEARCH_FIELDS}
     COUNT(m.id) AS message_count
  FROM msgs_dispatch d
  LEFT JOIN msgs_dispatch_category dc ON (d.category=dc.id)
  LEFT JOIN msgs_messages m ON (d.id=m.dispatch_id)
  $WHERE
  GROUP BY d.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
    FROM msgs_dispatch d
    LEFT JOIN msgs_messages m ON (d.id=m.dispatch_id)
    $WHERE;",
    undef,
    { INFO => 1 },
  );

  return $list;
}

#**********************************************************
=head2 chapter_add($attr)

=cut
#**********************************************************
sub dispatch_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_dispatch', { %$attr,
                                      COMMENTS => $attr->{COMMENTS} || '',
                                      CREATED  => 'now()'
                                     });
  $self->{DISPATCH_ID} = $self->{INSERT_ID};

  $admin->system_action_add("MGSG_DISPATCH:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 chapter_del

=cut
#**********************************************************
sub dispatch_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_dispatch', $attr);

  $admin->system_action_add("MGSG_DISPATCH:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 dispatch_info()

=cut
#**********************************************************
sub dispatch_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT md.*,
  a.aid,
  ra.aid AS resposible_id,
  a.name AS admin_fio,
  ra.name AS resposible_fio
    FROM msgs_dispatch md
    LEFT JOIN admins a ON (a.aid=md.aid)
    LEFT JOIN admins ra ON (ra.aid=md.resposible)
  WHERE md.id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 dispatch_change()

=cut
#**********************************************************
sub dispatch_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_dispatch',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 dispatch_admins_change

=cut
#**********************************************************
sub dispatch_admins_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_dispatch_admins', undef, { dispatch_id=> $attr->{DISPATCH_ID} });
  my @admins = split(/, /, $attr->{AIDS});
  my @MULTI_QUERY = ();
  foreach my $aid (@admins) {
    push @MULTI_QUERY, [
         $attr->{DISPATCH_ID},
         $aid
       ];
  }

  $self->query("INSERT INTO msgs_dispatch_admins (dispatch_id, aid)
        VALUES (?, ?);",
        undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 dispatch_admins_list($attr)
=cut
#**********************************************************
sub dispatch_admins_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT dispatch_id, aid FROM msgs_dispatch_admins WHERE dispatch_id= ? ;",
    undef,
    { %$attr, Bind => [ $attr->{DISPATCH_ID} ] });

  return $self->{list};
}

#**********************************************************
=head2 chapter_info($id, $attr)

=cut
#**********************************************************
sub dispatch_category_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_dispatch_category
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 chapter_change($attr)

=cut
#**********************************************************
sub dispatch_category_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_dispatch_category',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 chapter_del

=cut
#**********************************************************
sub dispatch_category_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_dispatch_category', $attr);

  $admin->system_action_add("MGSG_DISPATCH_CATEGORY:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 dispatch_category_add($attr)

=cut
#**********************************************************
sub dispatch_category_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_dispatch_category', $attr);

  $admin->system_action_add("MGSG_DISPATCH_CATEGORY:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 dispatch_category_list($attr)

=cut
#**********************************************************
sub dispatch_category_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'DESC';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
      ['ID',        'INT',  'dc.id',   1],
      ['NAME',      'STR',  'dc.name', 1],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("SELECT dc.id,
     dc.name
  FROM msgs_dispatch_category dc
  $WHERE
  GROUP BY dc.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
    FROM msgs_dispatch_category dc
    $WHERE;",
    undef,
    { INFO => 1 },
  );

  return $list;
}

#**********************************************************
=head2 unreg_requests_count($attr) - Count unreg message

=cut
#**********************************************************
sub unreg_requests_count {
  my $self = shift;

  $self->query("SELECT COUNT(m.id) AS unreg_count
   FROM msgs_unreg_requests m
   WHERE state=0",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 unreg_requests_list($attr) - Unreg request list

=cut
#**********************************************************
sub unreg_requests_list {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS})     ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})          ? $attr->{SORT}      : 1;
  $DESC      = (defined($attr->{DESC})) ? $attr->{DESC}      : 'DESC';
  $PG        = ($attr->{PG})       ? $attr->{PG}        : 0;

  my @WHERE_RULES = ();
  $self->{COL_NAMES_ARR}=undef;
  $self->{SEARCH_FIELDS}=undef;
  $self->{SEARCH_FIELDS_COUNT}=0;

  if (defined($attr->{STATE})) {
    if ($attr->{STATE} == 7) {
      push @WHERE_RULES, @{ $self->search_expr(">0", 'INT', 'm.deligation') };
    }
    elsif ($attr->{STATE} == 8) {
      push @WHERE_RULES, @{ $self->search_expr("$admin->{AID}", 'INT', 'm.resposible') };
      push @WHERE_RULES, @{ $self->search_expr("0;3;6",         'INT', 'm.state') };
      delete $attr->{DELIGATION};
    }
    else {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state') };
    }
  }

  if ($attr->{LOCATION_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOCATION_ID}, 'INT', 'm.location_id', { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build, m.address_flat, builds.id AS build_id' }) };
    $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
   LEFT JOIN streets ON (streets.id=builds.street_id)";
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  else {
    if ($attr->{STREET_ID}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STREET_ID}, 'INT', 'builds.street_id', { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build' }) };
      $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
     LEFT JOIN streets ON (streets.id=builds.street_id)";
      $self->{SEARCH_FIELDS_COUNT} += 1;
    }
    elsif ($attr->{DISTRICT_ID}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' }) };
      $self->{EXT_TABLES} .= " LEFT JOIN builds ON (builds.id=m.location_id)
      LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
    elsif ($self->{conf}->{ADDRESS_REGISTER}) {
      if ($attr->{CITY}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{CITY}, 'STR', 'city', { EXT_FIELD => 1 }) };
      }

      if ($attr->{DISTRICT_NAME}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_NAME}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' }) };
      }

      if ($attr->{ADDRESS_DISTRICT}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_DISTRICT}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' }) };
      }

      if ($attr->{ADDRESS_STREET}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'streets.name AS address_street', { EXT_FIELD => 1 }) };
        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
        LEFT JOIN streets ON (streets.id=builds.street_id)" if ($self->{EXT_TABLES} !~ /streets/);
      }
      elsif ($attr->{ADDRESS_FULL}) {
        $attr->{BUILD_DELIMITER}=',' if (! $attr->{BUILD_DELIMITER});
         push @WHERE_RULES, @{ $self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT(streets.name, ' ', builds.number, '$attr->{BUILD_DELIMITER}', m.address_flat) AS address_full", { EXT_FIELD => 1 }) };

        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
          LEFT JOIN streets ON (streets.id=builds.street_id)";
      }

      if ($attr->{ADDRESS_BUILD}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'builds.number', { EXT_FIELD => 'builds.number AS address_build' }) };

        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)" if ($self->{EXT_TABLES} !~ /builds/);
      }
    }
    else {
      if ($attr->{ADDRESS_FULL}) {
        $attr->{BUILD_DELIMITER}=',' if (! $attr->{BUILD_DELIMITER});
        push @WHERE_RULES, @{ $self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT(m.address_street, ' ', m.address_build, '$attr->{BUILD_DELIMITER}', m.address_flat) AS address_full", { EXT_FIELD => 1 }) };
      }

      if ($attr->{ADDRESS_STREET}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'm.address_street', { EXT_FIELD => 1 }) };
      }

      if ($attr->{ADDRESS_BUILD}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'm.address_build', { EXT_FIELD => 1 }) };
      }

      if ($attr->{COUNTRY_ID}) {
        push @WHERE_RULES, @{ $self->search_expr($attr->{COUNTRY_ID}, 'STR', 'm.country_id', { EXT_FIELD => 1 }) };
      }
    }
  }

  if ($attr->{ADDRESS_FLAT}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_FLAT}, 'STR', 'm.address_flat', { EXT_FIELD => 1 }) };
  }

  if ($attr->{GET_NEW}) {
  	push @WHERE_RULES, " (m.datetime > now() - interval $attr->{GET_NEW} second) ";
  }

  my $search_fields       = $self->{SEARCH_FIELDS};
  my $search_fields_count = $self->{SEARCH_FIELDS_COUNT};
  my $WHERE = $self->search_former($attr, [
      ['MSG_ID',       'INT',  'm.id'             ],
      ['ID',           'INT',  'm.id'             ],
      ['DATETIME',     'DATE', 'm.datetime',    1 ],
      ['SUBJECT',      'STR',  'm.subject',     1 ],
      ['FIO',          'STR',  'm.fio',         1 ],
      ['PHONE',        'STR',  'm.phone',       1 ],
      ['EMAIL',        'STR',  'm.email',       1 ],
      ['STATE',        'INT',  'm.state',       1 ],
      ['CONNECTION_TIME','DATE',  'm.connection_time',   1 ],
      ['CHAPTER_NAME', 'INT',  'm.chapter', 'mc.name AS chapter_name'],
      ['CLOSED_DATE',  'DATE', 'm.closed_date', 1 ],
      ['ADMIN_LOGIN',  'INT',  'a.id',  'a.id AS admin_login' ],
      ['INNER_MSG',    'INT',  'm.inner_msg',   1 ],
      ['COMMENTS',     'STR',  'm.comments',    1 ],
      ['REACTION_TIME','STR',  'm.reaction_time'],
      ['DONE_DATE',    'DATE', 'm.done_date',   1 ],
      ['UID',          'INT',  'm.uid',           ],
      ['DELIGATION',   'INT',  'm.delegation',  1 ],
      ['RESPOSIBLE_ADMIN_LOGIN', 'STR', 'ra.id', 'ra.id AS resposible_admin_login'],
      ['RESPOSIBLE',   'INT',  'm.resposible',   ],
      ['PRIORITY',     'INT',  'm.priority',    1 ],
#      ['DISPATCH_ID',  'INT',  'm.dispatch_id', 1 ],
      ['IP',           'IP',   'm.ip',  'INET_NTOA(m.ip) AS ip' ],
      ['DATE',         'DATE',  "DATE_FORMAT(m.datetime, '%Y-%m-%d')" ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(m.datetime, '%Y-%m-%d')" ],
      ['SHOW_TEXT',    '',    '',       'm.message' ],
      ['REACTION_TIME', 'STR', 'm.reaction_time', 1],
      ['CONTACT_NOTE',  'STR', 'm.contact_note',  1],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->{SEARCH_FIELDS_COUNT} += $search_fields_count;
  my $EXT_TABLES = '';

  if ($self->{conf}->{ADDRESS_REGISTER}) {
    $EXT_TABLES = "LEFT JOIN builds ON builds.id=m.location_id
     LEFT JOIN streets ON (streets.id=builds.street_id)
     LEFT JOIN districts ON (districts.id=streets.district_id)";
  }

  $self->query("SELECT  m.id,
  $self->{SEARCH_FIELDS}
  $search_fields
  m.resposible,
  m.uid,
  m.chapter AS chapter_id
FROM msgs_unreg_requests m
LEFT JOIN admins a ON (m.received_admin=a.aid)
LEFT JOIN admins ra ON (m.resposible=ra.aid)
LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
$EXT_TABLES
 $WHERE
GROUP BY m.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT count(*) AS total
    FROM msgs_unreg_requests m
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    $EXT_TABLES
    $WHERE",
    undef, { INFO => 1 }
    );
  }

  $WHERE       = '';
  @WHERE_RULES = ();

  return $list;
}

#**********************************************************
=head2 unreg_requests_add($attr) - add admin message

=cut
#**********************************************************
sub unreg_requests_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && ! $attr->{LOCATION_ID}) {
    use Address;
    our $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add($attr);
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  $self->query_add('msgs_unreg_requests', {
     %$attr,
     DATETIME        => 'NOW()',
     RECEIVED_ADMIN  => $admin->{AID},
     COMMENTS        => $attr->{COMMENTS} || '',
     IP              => $admin->{SESSION_IP},
    });
  $self->{MSG_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
# unreg_requests_del
#**********************************************************
sub unreg_requests_del {
  my $self = shift;
  my ($attr) = @_;

  if(!$attr->{ID}){
    return $self;
  }

  $self->query_del('msgs_unreg_requests', $attr, { ID => $attr->{ID} });

  return $self;
}

#**********************************************************
=head2 unreg_requests_info($id, $attr)

=cut
#**********************************************************
sub unreg_requests_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = ($attr->{UID}) ? "AND m.uid='$attr->{UID}'" : '';

  $self->query("SELECT
    m.*,
    ra.id AS received_admin,
    mc.name AS chapter,
    INET_NTOA(m.ip) AS ip
    FROM msgs_unreg_requests m
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN admins ra ON (m.received_admin=ra.aid)
  WHERE m.id=? $WHERE
  GROUP BY m.id;",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  if ($self->{TOTAL} && $self->{LOCATION_ID} > 0) {
    $self->query("SELECT d.id AS district_id,
      d.city,
      d.name AS address_district,
      s.name AS address_street,
      b.number AS address_build
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id= ? ",
     undef,
     { INFO => 1,
       Bind => [ $self->{LOCATION_ID} ]
       }
    );
  }

  return $self;
}


#**********************************************************
=head2 unreg_requests_change($attr)

=cut
#**********************************************************
sub unreg_requests_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;

  $admin->{MODULE} = $MODULE;

  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'msgs_unreg_requests',
      DATA            => $attr,
      EXT_CHANGE_INFO => "MSG_ID:$attr->{ID}"
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 survey_subjects_list($attr)

=cut
#**********************************************************
sub survey_subjects_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  delete $self->{COL_NAMES_ARR};

  my $WHERE = $self->search_former($attr, [
      ['ID',           'INT',  'ms.id',             ],
      ['NAME',         'STR',  'ms.name'            ],
      ['COMMENTS',     'STR',  'ms.comments',     1 ],
      ['TPL',          'STR',  'ms.tpl',          1 ],
      ['STATUS',       'STR',  'ms.status',       1 ],
      ['ADMIN_NAME',   'STR',  'ms.aid',   'ms.aid AS admin_name' ],
      ['CREATED',      'STR',  'ms.created',      1 ],
      ['FILENAME',     'STR',  'm.filename',      1 ],
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT ms.id, ms.name, $self->{SEARCH_FIELDS} ms.id AS survey_id
    FROM msgs_survey_subjects ms
    $WHERE
    GROUP BY ms.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT count(*) AS total
     FROM msgs_survey_subjects ms
     $WHERE",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 survey_subjects_add($attr)

=cut
#**********************************************************
sub survey_subject_add {
  my $self = shift;
  my ($attr) = @_;

  if(! $attr->{NAME}) {
    return $self;
  }

  $self->query_add('msgs_survey_subjects',  { %$attr,
                                              CREATED => 'NOW()',
                                              TPL     => $attr->{TPL} || ' ',
                                              COMMENTS=> $attr->{COMMENTS} || ' ',
                                              CONTENTS=> $attr->{CONTENTS} || ' ',
                                            });

  return $self;
}

#**********************************************************
=head2 survey_subject_del()

=cut
#**********************************************************
sub survey_subject_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_survey_subjects', $attr);

  return $self;
}

#**********************************************************
=head2 survey_subjects_info($id)

=cut
#**********************************************************
sub survey_subject_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *,
     id AS survey_id
    FROM msgs_survey_subjects
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# survey_subjects_change()
#**********************************************************
sub survey_subject_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_survey_subjects',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
# survey_subjects_list
#**********************************************************
sub survey_questions_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['SURVEY_ID',  'STR',  'mq.survey_id'     ],
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT  mq.num, mq.question, mq.comments, mq.params, mq.user_comments, mq.fill_default, mq.id
    FROM msgs_survey_questions mq
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT count(*) AS total
     FROM msgs_survey_questions mq
     $WHERE",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# survey_questions_add
#**********************************************************
sub survey_question_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_survey_questions', $attr);

  return $self;
}

#**********************************************************
# urvey_questions_del
#**********************************************************
sub survey_question_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_survey_questions', $attr);

  return $self;
}

#**********************************************************
# survey_questions_info
#**********************************************************
sub survey_question_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_survey_questions WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# survey_questions_change()
#**********************************************************
sub survey_question_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;
  $attr->{USER_COMMENTS} = ($attr->{USER_COMMENTS}) ? 1 : 0;
  $attr->{FILL_DEFAULT}  = ($attr->{FILL_DEFAULT})  ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_survey_questions',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 survey_answer_show($attr)

  Arguments:
    REPLY_ID
    SURVEY_ID
    UID

  Results:

=cut
#**********************************************************
sub survey_answer_show {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = ($attr->{REPLY_ID}) ? "AND reply_id='$attr->{REPLY_ID}'" : "AND msg_id='$attr->{MSG_ID}' AND reply_id='0' ";

  $self->query("SELECT question_id,
  uid,
  answer,
  comments,
  date_time,
  survey_id
  FROM msgs_survey_answers
  WHERE survey_id= ?
  AND uid= ? $WHERE;",
  undef,
  { Bind => [$attr->{SURVEY_ID}, $attr->{UID} ],
    %$attr }
  );

  return $self->{list};
}

#**********************************************************
=head2 survey_answer_list($attr)

=cut
#**********************************************************
sub survey_answer_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
    ma.*,
    u.id as login
    FROM msgs_survey_answers ma
    LEFT JOIN users u ON (u.uid=ma.uid)
    WHERE survey_id= ? ;",
    undef,
    { Bind => [$attr->{SURVEY_ID}], COLS_NAME => 1}
  );

  return $self->{list};

}

#**********************************************************
=head2 survey_answer_add($attr)

=cut
#**********************************************************
sub survey_answer_add {
  my $self = shift;
  my ($attr) = @_;

  my @ids = split(/, /, $attr->{IDS});

  my @fill_default      = ();
  my %fill_default_hash = ();
  if ($attr->{FILL_DEFAULT}) {
    @fill_default = split(/, /, $attr->{FILL_DEFAULT});
    foreach my $id (@fill_default) {
      $fill_default_hash{$id} = 1;
    }
  }

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    if ($attr->{FILL_DEFAULT} && !$fill_default_hash{$id}) {
      next;
    }

    push @MULTI_QUERY, [ $id,
       $attr->{UID},
       $attr->{ 'PARAMS_' . $id } || '',
       $attr->{ 'USER_COMMENTS_' . $id } || '',
       $attr->{SURVEY_ID},
       $attr->{MSG_ID},
       $attr->{REPLY_ID}
    ];
  }

  $self->query("INSERT INTO msgs_survey_answers (question_id,
     uid, answer, comments, date_time, survey_id, msg_id, reply_id)
        VALUES (?, ?, ?, ?, NOW(), ?, ?, ?);",
        undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#**********************************************************
#
#**********************************************************
sub survey_answer_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_survey_answers', $attr,
     { survey_id => $attr->{SURVEY_ID},
       uid       => $attr->{UID},
       reply_id  => ($attr->{REPLY_ID}) ? $attr->{REPLY_ID} : undef,
       msg_id    => (! $attr->{REPLY_ID}) ? $attr->{MSG_ID} : undef
      });

  return $self;
}


#**********************************************************
# pb_list
#**********************************************************
sub pb_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  delete $self->{COL_NAMES_ARR};

  my $WHERE = $self->search_former($attr, [
      ['STEP_NUM',     'INT',  'pb.step_num'   ],
      ['STEP_NAME',    'STR',  'pb.step_name'  ],
      ['CHAPTER_ID',   'STR',  'pb.chapter_id' ]
    ],
    { WHERE => 1 });

  $self->query("SELECT pb.step_num, pb.step_name, pb.step_tip, pb.id
    FROM msgs_proggress_bar pb
    $WHERE
    GROUP BY pb.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# pb_add
#**********************************************************
sub pb_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_proggress_bar', $attr);

  $admin->system_action_add("MGSG_PB:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
# pb_del
#**********************************************************
sub pb_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_proggress_bar', $attr);

  return $self;
}

#**********************************************************
# pb_info
#**********************************************************
sub pb_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_proggress_bar
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# pb_change()
#**********************************************************
sub pb_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_proggress_bar',
      DATA         => $attr,
    }
  );

  return $self->{result};
}


#**********************************************************
=head2 pb_msg_list($attr)

=cut
#**********************************************************
sub pb_msg_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['MSG_ID',             'INT',  'pb_m.msg_id'   ],
      ['STEP_NUM',           'INT',  'pb.step_num'   ],
      ['STEP_NAME',          'STR',  'pb.step_name'  ],
      ['CHAPTER_ID',         'STR',  'pb.chapter_id' ],
      ['USER_NOTICE',        'STR',  'pb.user_notice' ],
      ['RESPONSIBLE_NOTICE', 'STR',  'pb.responsible_notice' ],
      ['FOLLOWER_NOTICE',    'STR',  'pb.follower_notice' ],
      ['MAIN_MSG',           'INT',  'mpb.main_msg' ],
    ],
    { WHERE => 1 });

  $self->query("SELECT pb.step_num, pb.step_name, mpb.step_date, pb.step_tip,
    mpb.coordx, mpb.coordy, pb.id, pb.user_notice, pb.responsible_notice, pb.follower_notice, mpb.main_msg
    FROM msgs_proggress_bar pb
    LEFT JOIN msgs_message_pb mpb ON (mpb.main_msg='$attr->{MAIN_MSG}' AND mpb.step_num=pb.step_num)
    $WHERE
    GROUP BY pb.id
    ORDER BY pb.step_num;",
    undef,
    $attr
  );

  return $self->{list};
}


#**********************************************************
# pb_msg_change
#**********************************************************
sub pb_msg_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM `msgs_message_pb` WHERE step_num>='$attr->{STEP_NUM}' AND main_msg='$attr->{ID}'");

  $self->query_add('msgs_message_pb', { %$attr,
                                        AID        => ($attr->{USER_SEND}) ? 0 : $admin->{AID},
                                        MAIN_MSG   => $attr->{ID},
                                        STEP_DATE  => 'NOW()'
                                      });

  return $self->{list};
}


#**********************************************************
=head2 msg_watch_info($msg_id, $attr)

=cut
#**********************************************************
sub msg_watch_info {
  my $self = shift;
  my ($msg_id) = @_;

  $self->query("SELECT *
    FROM msgs_watch
  WHERE main_msg = ? ",
  undef,
  { INFO => 1,
    Bind => [ $msg_id ] }
  );

  return $self;
}
#**********************************************************
# msg_watch
#**********************************************************
sub msg_watch {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_watch', { %$attr,
                                   AID      => $admin->{AID},
                                   MAIN_MSG => $attr->{ID},
                                   ADD_DATE => 'NOW()'
                                 });

  return $self->{list};
}

#**********************************************************
=head2 msg_watch_del($attr)

=cut
#**********************************************************
sub msg_watch_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_watch', undef, { aid      => $admin->{AID},
                                          main_msg => $attr->{ID},
                                        });

  return $self->{list};
}

#**********************************************************
=head2 msg_watch_list($attr)

=cut
#**********************************************************
sub msg_watch_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['MAIN_MSG',     'INT',  'MAIN_MSG'     ],
      ['AID',          'INT',  'aid'        ],
      ['ADD_DATE',     'INT',  'add_date'   ],
    ],
    { WHERE => 1 });

  $self->query("SELECT main_msg, add_date, aid
    FROM msgs_watch
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 status_add($attr) -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub status_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_status', $attr);

  return $self;
}

#**********************************************************
=head2 status_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub status_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = $attr->{SORT} // 'id';

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',          'INT',  'id',           1],
      [ 'NAME',        'STR',  'name',         1],
      [ 'READINESS',   'INT',  'readiness',    1],
      [ 'TASK_CLOSED', 'INT',  'task_closed',  1],
      [ 'COLOR',       'INT',  'color',        1],
      [ 'ICON',        'STR',  'icon',         1],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT * FROM msgs_status
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($attr->{STATUS_ONLY} || !$self->{TOTAL} < 1) {
    return $list;
  }

  $self->query(
    "SELECT COUNT(*) AS total
     FROM msgs_status",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 status_del() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub status_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_status', $attr);

  return $self;
}


#**********************************************************
=head2 status_info() -

  Arguments:
urns:

  Examples:

=cut
#**********************************************************
sub status_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_status
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 status_change() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub status_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_status',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 msgs_delivery_add($attr) -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_delivery', {
     %$attr,
     ADDED => 'NOW()',
     AID   => $admin->{AID},
  });

  $self->{DELIVERY_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
=head2 msgs_delivery_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_list {
  my $self = shift;
  my ($attr) = @_;

  delete($self->{SEARCH_FIELDS});

  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',          'INT',      'id',             ],
      [ 'SEND_DATE',   'DATE',     'send_date',     1],
      [ 'SEND_TIME',   'TIME',     'send_time',     1],
      [ 'SUBJECT',     'STR',      'subject',        ],
      [ 'SEND_METHOD', 'INT',      'send_method',   1],
      [ 'PRIORITY',    'INT',      'priority',      1],
      [ 'STATUS',      'INT',      'status',        1],
      [ 'TEXT',        'STR',      'text',          1],
      [ 'SEND_METHOD', 'INT',      'send_method',   1],
      [ 'ADDED',       'DATETIME', 'added',         1],
      [ 'AID',         'INT',      'aid',           1],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    id,
    $self->{SEARCH_FIELDS}
    subject
    FROM msgs_delivery
    $WHERE
    GROUP BY id
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total
     FROM msgs_delivery md
     $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 msgs_delivery_del($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_delivery', $attr);
  $self->query_del('msgs_delivery_users',undef,{ mdelivery_id => $attr->{ID}});

  return $self;
}


#**********************************************************
=head2 msgs_delivery_info($id) -

  Arguments:
  $id

  Returns:

=cut
#**********************************************************
sub msgs_delivery_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_delivery
    WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 msgs_delivery_change($attr) -

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_delivery',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 delivery_user_list_add($attr)

  Arguments:
    $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_user_list_add {
  my $self = shift;
  my ($attr) = @_;

  my @ids = split(/, /, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $id,
       $attr->{MDELIVERY_ID}   || '',
       $attr->{SENDED_DATE}    || '',
       $attr->{SEND_METHOD}    || '',
       $attr->{STATUS}         || 0,
    ];
  }

  $self->query("INSERT IGNORE INTO msgs_delivery_users (uid, mdelivery_id, sended_date, send_method, status)
        VALUES (?, ?, ?, ?, ?);",
        undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 delivery_user_list($attr)

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_user_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    [ 'ID',           'INT', 'mdl.id'       ],
    [ 'UID',          'INT', 'uid'          ],
    [ 'STATUS',       'INT', 'mdl.status'   ],
    [ 'LOGIN',        'STR', 'u.id'         ],
    [ 'MDELIVERY_ID', 'INT', 'mdl.mdelivery_id' ],
    [ 'FIO',          'STR', 'pi.fio'       ],
    [ 'EMAIL',        'STR', 'pi.email'     ],
    ],
  {
    WHERE       => 1,
  });

  $self->query("SELECT mdl.id, u.id AS login, pi.fio, mdl.status, mdl.uid, pi.email
     FROM msgs_delivery_users mdl
     INNER JOIN users u ON (u.uid=mdl.uid)
     LEFT JOIN users_pi pi ON (mdl.uid=pi.uid)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
     FROM msgs_delivery_users mdl
     INNER JOIN users u ON (u.uid=mdl.uid)
     $WHERE;",
     undef, {INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 delivery_user_list_del($attr)

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_user_list_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_delivery_users', $attr);

  return $self;
}

#**********************************************************
=head2 delivery_user_list_change($attr)

=cut
#**********************************************************
sub delivery_user_list_change {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ("mdelivery_id='$attr->{MDELIVERY_ID}'");

  my $WHERE =  $self->search_former($attr, [
      [ 'UID',        'INT', 'uid' ],
      [ 'ID',         'INT', 'id' ],
    ],
    {
      WHERE_RULES => \@WHERE_RULES
    }
  );

  my $status = 1;
  $self->query("UPDATE msgs_delivery_users SET status='$status' WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
=head2 messages_reports($attr)
  Arguments:
     $attr
       $attr->{FROM_DATE} - create date
       $attr->{TO_DATE}  - create date
  Returns:
      $list
=cut
#**********************************************************
sub messages_admins_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "mur.datetime BETWEEN '$attr->{FROM_DATE}' AND '$attr->{TO_DATE}'";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'AID',      'INT',      'ra.aid',       1 ],
      [ 'MSG_ID',   'INT',      'mur.id',       1 ],
      [ 'DATETIME', 'DATETIME', 'mur.datetime', 1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("SELECT
    ra.aid,
    ra.id,
    COUNT(DISTINCT mur.id) AS total_msg,
    COUNT(DISTINCT IF(mur.state = 0, mur.id, NULL)) AS open,
    COUNT(DISTINCT IF(mur.state = 1, mur.id, NULL)) AS unmaked,
    COUNT(DISTINCT IF(mur.state = 2, mur.id, NULL)) AS closed,
    COUNT(DISTINCT IF(mur.state = 11, mur.id, NULL)) AS potential_client,
    COUNT(DISTINCT IF(mur.state = 3, mur.id, NULL)) AS in_process,
    mur.datetime
      FROM admins ra
      LEFT JOIN msgs_unreg_requests mur ON (ra.aid=mur.resposible)
      $WHERE
      GROUP BY ra.aid
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT IF(ra.aid=mur.resposible, COUNT(*), NULL) AS total
      FROM admins ra
      LEFT JOIN msgs_unreg_requests mur ON (ra.aid=mur.resposible)
      $WHERE;",
     undef, {INFO => 1 }
  );
  return $list;
}

#**********************************************************
=head2 messages_quick_replys_types_info($id, $attr)

=cut
#**********************************************************
sub messages_quick_replys_types_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_quick_replys_types
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_types_change($attr)

=cut
#**********************************************************
sub messages_quick_replys_types_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_quick_replys_types',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 messages_quick_replys_types_del

=cut
#**********************************************************
sub messages_quick_replys_types_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys', undef, { type_id => $attr->{ID} });

  $self->query_del('msgs_quick_replys_types', $attr);

  $admin->system_action_add("MGSG_QUICK_REPORTS_TYPES_DELL:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_types_add($attr)

=cut
#**********************************************************
sub messages_quick_replys_types_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_quick_replys_types', $attr);

  $admin->system_action_add("MGSG_QUICK_REPORTS_TYPES_ADD:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 messages_quick_replys_types_list($attr)

=cut
#**********************************************************
sub messages_quick_replys_types_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'DESC';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
      ['ID',   'INT',  'qrt.id',     1],
      ['NAME', 'STR',  'qrt.name',   1],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("SELECT qrt.*
  FROM msgs_quick_replys_types qrt
  $WHERE
  GROUP BY qrt.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
    FROM msgs_quick_replys_types qrt
    $WHERE;",
    undef,
    { INFO => 1 },
  );

  return $list;
}

#**********************************************************
=head2 messages_quick_replys_info($id, $attr)

=cut
#**********************************************************
sub messages_quick_replys_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_quick_replys
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_change($attr)

=cut
#**********************************************************
sub messages_quick_replys_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_quick_replys',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 messages_quick_replys_del

=cut
#**********************************************************
sub messages_quick_replys_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys', $attr);

  $admin->system_action_add("MSGS_QUICK_REPLYS_DELL:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_add($attr)

=cut
#**********************************************************
sub messages_quick_replys_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_quick_replys', $attr);

  $admin->system_action_add("MSGS_QUICK_REPLYS_ADD:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 messages_quick_replys_list($attr)

=cut
#**********************************************************
sub messages_quick_replys_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
      ['ID',      'INT',  'qr.id',            1],
      ['REPLY',   'STR',  'qr.reply',         1],
      ['TYPE_ID', 'INT',  'qr.type_id',       1],
      ['TYPE',    'STR',  'qrt.name AS type', 1],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} qr.color,
  qrt.name AS type
  FROM msgs_quick_replys qr
  LEFT JOIN msgs_quick_replys_types qrt ON (qrt.id=qr.type_id)
  $WHERE
  GROUP BY qr.id
  ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  if ($self->{errno}){
    return [];
  }

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
    FROM msgs_quick_replys qr
    LEFT JOIN msgs_quick_replys_types qrt ON (qrt.id=qr.type_id)
    $WHERE;",
    undef,
    { INFO => 1 },
  );

  return $list;
}

#**********************************************************
=head2 quick_replys_tags_info($id, $attr)

=cut
#**********************************************************
sub quick_replys_tags_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_quick_replys_tags
  WHERE id= ? ",
  undef,
  { INFO => 1,
    Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 quick_replys_tags_change($attr)

=cut
#**********************************************************
sub quick_replys_tags_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_quick_replys_tags',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 quick_replys_tags_del

=cut
#**********************************************************
sub quick_replys_tags_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys_tags', $attr);

  $admin->system_action_add("ADD MSGS TAG:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 quick_replys_tags_add($attr)

=cut
#**********************************************************
sub quick_replys_tags_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys_tags', undef, { msg_id => $attr->{MSG_ID} });

  my @ids = split(/, /, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $id,
       $attr->{MSG_ID}   || '',
    ];
  }

  $self->query("INSERT msgs_quick_replys_tags (quick_reply_id, msg_id)
        VALUES (?, ?);",
        undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 quick_replys_tags_list($attr)

=cut
#**********************************************************
sub quick_replys_tags_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'DESC';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
      ['MSG_ID',         'INT', 'qrt.msg_id',         1],
      ['QUICK_REPLY_ID', 'INT', 'qrt.quick_reply_id', 1],
      ['REPLY',          'STR', 'qr.reply',           1],
      ['COLOR',          'STR', 'qr.color',           1],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("SELECT qrt.*,
    qr.reply,
    qr.type_id,
    qr.color
  FROM msgs_quick_replys_tags qrt
  LEFT JOIN msgs_quick_replys qr ON(qr.id=qrt.quick_reply_id)
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if($self->{errno}) {
    return $list;
  }

  $self->query("SELECT COUNT(*) AS total
    FROM msgs_quick_replys_tags qrt
    $WHERE;",
    undef,
    { INFO => 1 },
  );

  return $list;
}

#**********************************************************
=head2 messages_report_per_month($attr)

=cut
#**********************************************************
sub messages_report_closed {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT DATE_FORMAT(m.closed_date, \'%Y-%m\') AS month,
    COUNT(DISTINCT m.id) AS total_msgs,
    SUM(t1.time) AS run_time,
    SUM(t1.replys) AS total_replys,
    SUM(m.rating) AS total_rating
  FROM msgs_messages m
  LEFT JOIN (SELECT mr.main_msg, SUM(mr.run_time) as time, COUNT(DISTINCT mr.id) AS replys FROM msgs_reply mr GROUP BY mr.main_msg) as t1 ON (m.id=t1.main_msg)
  WHERE m.closed_date >= ? AND m.closed_date <= ?
  GROUP BY month;",
  undef,
  { COLS_NAME => 1, Bind => [ $attr->{F_DATE}, $attr->{T_DATE} ]}
  );

  return $self->{list};
}

#**********************************************************
=head2 messages_report_per_month($attr)

=cut
#**********************************************************
sub messages_report_tags_count {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(mm.date, '%Y-%m-%d')" ],
      ['SUBTAG',            'INT',  "mt2.quick_reply_id"               ],
      ['TAG_ID',            'INT',  "mt1.quick_reply_id"               ],
    ],
    { WHERE => 1}
  );
  my $EXT_TABLES = "";

  if ($attr->{SUBTAG}) {
    $EXT_TABLES = "LEFT JOIN msgs_quick_replys_tags mt2 ON (mt1.msg_id = mt2.msg_id)";
  }

  $self->query("SELECT count(mt1.msg_id) as count
    FROM msgs_quick_replys_tags mt1
    LEFT JOIN msgs_messages mm ON (mt1.msg_id = mm.id)
    $EXT_TABLES
    $WHERE;",
  undef,
  { COLS_NAME => 1}
  );
  return $self->{list}->[0]->{count} || 0;
}

#**********************************************************
=head2 messages_report_per_month($attr)

=cut
#**********************************************************
sub messages_tags_total_count {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['FROM_DATE|TO_DATE','DATE',      "DATE_FORMAT(mm.date, '%Y-%m-%d')"        ],
    ],
    { WHERE => 1}
  );

  $self->query("SELECT count(*) as total
    FROM msgs_quick_replys_tags mt
    LEFT JOIN msgs_messages mm ON (mt.msg_id = mm.id)
    $WHERE;",
  undef,
  {COLS_NAME => 1}
  );

  return $self->{list}->[0]->{total};
}

#**********************************************************
=head2 messages_report_replys($attr)

=cut
#**********************************************************
sub messages_report_replys_time {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(mr.datetime, '%Y-%m-%d')" ],
      ['AID',               'INT',  "mr.aid" ],
    ],
    { WHERE => 1}
  );

  $self->query("SELECT 
    DATE_FORMAT(mr.datetime, '%Y-%m') AS month,
    SUM(mr.run_time) as run_time,
    COUNT(mr.id) as replys
    FROM msgs_reply mr
    $WHERE
    GROUP BY month;",
  undef,
  { COLS_NAME => 1}
  );

  return $self->{list};
}
#**************************************************************
=head2 chat_add()  -ADD user to DB

=cut
#**************************************************************
sub chat_add {
  my $self = shift;
  my ($attr) = @_;
  $self->query_add('msgs_chat', $attr);
  return $self;
}
#**************************************************************
=head2 chat_list()  -Get chat messages

=cut
#**************************************************************
sub chat_list {
  my $self = shift;
  my ($attr) = @_;
  my $msg_id = $attr->{Msg_ID};
  $self->query("SELECT * FROM msgs_chat WHERE num_ticket=$msg_id;", undef, { COLS_NAME => 1 });
  return $self->{list};
}
#**************************************************************
=head2 chat_count()  -Get count of unread messages

=cut
#**************************************************************
sub chat_count {
  my $self = shift;
  my ($attr) = @_;
  my $msg_id = $attr->{Msg_ID};
  my $sender = $attr->{SENDER};
  my $WHERE = '';
  if ($attr->{SENDER}) {
    $WHERE = "mc.num_ticket=$msg_id AND mc.msgs_unread=0 AND mc.$sender=0";
  }
  elsif ($attr->{AID}) {
    my $aid = $attr->{AID};
    $WHERE = "mc.msgs_unread=0 AND mc.aid=0 AND mm.resposible=$aid";
  }
  elsif ($attr->{UID}) {
    $WHERE = "mc.msgs_unread=0 AND mm.uid=$attr->{UID} AND mc.uid=0";
  }
  $self->query("SELECT COUNT(*) as count
    FROM msgs_chat mc
    JOIN msgs_messages mm
    ON mc.num_ticket=mm.id
    WHERE $WHERE;", undef, { COLS_NAME => 1 });
  return $self->{list}[0]{count} || '0';
}
#**************************************************************
=head2 chat_count()  -Get count of unread messages

=cut
#**************************************************************
sub chat_change {
  my $self = shift;
  my ($attr) = @_;
  my $msg_id = $attr->{Msg_ID};
  my $sender = $attr->{SENDER};
  $self->query("UPDATE msgs_chat SET msgs_unread = 1 WHERE num_ticket=$msg_id AND msgs_unread=0 AND $sender=0;", undef, { COLS_NAME => 1 });
  return 1;
}
#**************************************************************
=head2 chat_message_info()  -Get info of unread messages for admin and user

=cut
#**************************************************************
sub chat_message_info {
  my $self = shift;
  my ($attr) = @_;
  my $WHERE = '';
  if ($attr->{AID}) {
    my $aid = $attr->{AID};
    $WHERE = "mc.msgs_unread=0 AND mc.aid=0 AND mm.resposible=$aid";
  }
  if ($attr->{UID}) {
  my $uid = $attr->{UID};
  $WHERE = "mc.msgs_unread=0 AND mc.uid=0 AND mm.uid=$uid";
  }
  $self->query("SELECT DISTINCT mc.num_ticket,mm.uid, mm.subject, mm.id
    FROM msgs_chat mc
    JOIN msgs_messages mm
    ON mc.num_ticket=mm.id
    WHERE  $WHERE ;", undef, { COLS_NAME => 1 });
  return $self->{list};
}
1;

