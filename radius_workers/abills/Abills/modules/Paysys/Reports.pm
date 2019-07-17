#package Paysys::Reports;
use strict;
use warnings FATAL => 'all';

our (
  $html,
  %lang,
  @status,
  @status_color,
  $admin,
  $db,
  @MONTHES,
  @WEEKDAYS,

);

our Paysys $Paysys;
#**********************************************************
=head2 paysys_log() - Show paysys operations

=cut
#**********************************************************
sub paysys_log {

  if (form_purchase_module({
    HEADER          => $user->{UID},
    MODULE          => 'Paysys',
    REQUIRE_VERSION => 4.21
  })) {
    return 0;
  }

  my %PAY_SYSTEMS = ();

  my $connected_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => '_SHOW',
    STATUS    => 1,
    COLS_NAME => 1,
  });

  foreach my $payment_system (@$connected_systems) {
    $PAY_SYSTEMS{$payment_system->{paysys_id}} = $payment_system->{name};
  }

  if ($FORM{info}) {
    $Paysys->info({ ID => $FORM{info} });
    my @info_arr = split(/\n/, $Paysys->{INFO});
    my $table = $html->table({ width => '100%' });
    foreach my $line (@info_arr) {
      my ($k, $v) = split(/,/, $line, 2);
      $table->addrow($k, $v);
    }

    $Paysys->{INFO} = $table->show();
    $table = $html->table(
      {
        width   => '500',
        caption => $lang{INFO},
        rows    => [
          [ "ID", $Paysys->{ID} ],
          [ "$lang{LOGIN}", $Paysys->{LOGIN} ],
          [ "$lang{DATE}", $Paysys->{DATETIME} ],
          [ "$lang{SUM}", $Paysys->{SUM} ],
          [ "$lang{COMMISSION}", $Paysys->{COMMISSION} ],
          [ "$lang{PAY_SYSTEM}", $PAY_SYSTEMS{ $Paysys->{SYSTEM_ID} } ],
          [ "$lang{TRANSACTION}", $Paysys->{TRANSACTION_ID} ],
          [ "$lang{USER} IP", $Paysys->{CLIENT_IP} ],
          [ "PAYSYS IP", $Paysys->{PAYSYS_IP} ],
          [ "$lang{INFO}", $Paysys->{INFO} ],
          [ "$lang{ADD_INFO}", $Paysys->{USER_INFO} ],
          [ "$lang{STATUS}", $status[ $Paysys->{STATUS} ] ],
        ],
        ID      => 'PAYSYS_INFO'
      }
    );

    print $table->show();
  }
  elsif (defined($FORM{del}) && ($FORM{COMMENTS} || $FORM{is_js_confirmed})) {
    $Paysys->del($FORM{del});

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Paysys);

  my %info = ();

  if ($FORM{search_form} && !$user->{UID}) {
    my %ACTIVE_SYSTEMS = %PAY_SYSTEMS;

    #    while (my ($k, $v) = each %CONF_OPTIONS) {
    #      if (!$conf{$k}) {
    #        delete $ACTIVE_SYSTEMS{$v};
    #      }
    #    }

    $info{PAY_SYSTEMS_SEL} = $html->form_select(
      'PAYMENT_SYSTEM',
      {
        SELECTED => $FORM{PAYMENT_SYSTEM} || '',
        SEL_HASH => { '' => $lang{ALL}, %ACTIVE_SYSTEMS },
        NO_ID    => 1
      }
    );

    $info{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED     => $FORM{STATUS} || '',
        SEL_ARRAY    => \@status,
        ARRAY_NUM_ID => 1,
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    $info{DATERANGE_PICKER} = $html->form_daterangepicker({
      NAME  => 'FROM_DATE/TO_DATE',
      #      FORM_NAME => 'invoice_add',
      VALUE => $FORM{'FROM_DATE_TO_DATE'},
    });

    form_search({ SEARCH_FORM => $html->tpl_show(_include('paysys_search', 'Paysys'),
        { %info, %FORM },
        { OUTPUT2RETURN => 1 }),
      ADDRESS_FORM            => 1 });
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }
  my Abills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'list',
    BASE_FIELDS     => 7,
    FUNCTION_FIELDS => 'status, del',
    EXT_TITLES      => {
      id             => 'ID',
      system_id      => $lang{PAY_SYSTEM},
      transaction_id => $lang{TRANSACTION},
      info           => $lang{INFO},
      sum            => $lang{SUM},
      ip             => "$lang{USER} IP",
      status         => $lang{STATUS},
      date           => $lang{DATE},
      month          => $lang{MONTH},
      datetime       => $lang{DATE},
    },
    TABLE           => {
      width      => '100%',
      caption    => "Paysys",
      cols_align => [ 'left', 'left', 'right', 'right', 'left', 'right', 'right', 'center:noprint', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $Paysys->{TOTAL},
      ID         => 'PAYSYS_LOG',
      EXPORT     => "$lang{EXPORT} XML:&xml=1",
      MENU       => "$lang{SEARCH}:index=$index&search_form=1:search;",
    },
  });

  foreach my $line (@$list) {
    my @fields_array = ($line->{id},
      $html->button($line->{login}, "index=15&UID=$line->{uid}"),
      $line->{datetime},
      $line->{sum},
      (($PAY_SYSTEMS{$line->{system_id}}) ? $PAY_SYSTEMS{$line->{system_id}} : "Unknown: " . $line->{system_id}),
      $html->button("$line->{transaction_id}", "index=2&EXT_ID=$line->{transaction_id}&search=1"),
      #"$line->{status}:$status[$line->{status}]"
      "$line->{status}:" . $html->color_mark($status[$line->{status}], $status_color[$line->{status}]),
    );

    for (my $i = 7; $i < 7 + $Paysys->{SEARCH_FIELDS_COUNT}; $i++) {
      push @fields_array, $line->{$Paysys->{COL_NAMES_ARR}->[$i]};
    }

    $table->addrow(
      @fields_array,
      $html->button($lang{INFO}, "index=$index&info=$line->{id}", { class => 'show' })
        . ' ' . ($user->{UID} ? '-' : $html->button($lang{DEL}, "index=$index&del=$line->{id}",
          { MESSAGE => "$lang{DEL} $line->{id}?", class => 'del' }))
    );
  }
  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b($Paysys->{TOTAL}), "$lang{SUM}", $html->b($Paysys->{SUM}) ],
        [ "$lang{TOTAL} $lang{COMPLETE}:", $html->b($Paysys->{TOTAL_COMPLETE}), "$lang{SUM} $lang{COMPLETE}:",
          $html->b($Paysys->{SUM_COMPLETE}) ]
      ]
    }
  );
  if (!$admin->{MAX_ROWS}) {
    print $table->show();
  }
  # print $table->show();

  return 1;
}

#**********************************************************
=head2 paysys_reports()

=cut
#**********************************************************
sub paysys_reports {
  my ($attr) = @_;

  my $select = _paysys_select_connected_systems();
  my $systems = $html->form_main(
    {
      CONTENT => $select,
      HIDDEN  => { index => $index },
      SUBMIT  => { show => $lang{SHOW} },
      class   => 'navbar-form navbar-right',
    }
  );

  func_menu({ $lang{NAME} => $systems });

  if ($FORM{SYSTEM_ID}) {
    my $system_info = $Paysys->paysys_connect_system_info({
      ID               => $FORM{SYSTEM_ID},
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1
    });

    my $REQUIRE_OBJECT = _configure_load_payment_module($system_info->{module});
    my $PAYSYS_OBJECT = $REQUIRE_OBJECT->new($db, $admin, \%conf, {
        CUSTOM_NAME => $system_info->{name},
        CUSTOM_ID   => $system_info->{paysys_id},
        DATE        => $DATE
      });

    if ($PAYSYS_OBJECT->can('report')) {
      $PAYSYS_OBJECT->report({
        FORM     => \%FORM,
        LANG     => \%lang,
        HTML     => $html,
        INDEX    => $index,
        OP_SID   => '',
        MONTHES  => \@MONTHES,
        WEEKDAYS => \@WEEKDAYS,
        DATE     => $DATE,
      });
    }
    else {
      $html->message("warn", "No sub report", "This module doesnt have report sub");
    }
  }

  return 1;
}

1;