=head1 NAME

  User Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base;
use Users;
our(
  $html,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  %permissions,
  $db,
  $admin,
);
my $Users   = Users->new( $db, $admin, \%conf );
#**********************************************************
=head2 report_new_all_customers() - show chart for new and all customers

  Arguments:
    
  Returns:
    true
=cut
#**********************************************************
sub report_new_all_customers {
  my ($search_year, undef, undef) = split('-', $DATE);
  if ($FORM{NEXT} || $FORM{PRE}) {
    $search_year = $FORM{NEXT} || $FORM{PRE};
  }
  my $count_new_cust = $Users->info_user_reports({ LIST2HASH => 'reg_month,count',USER_NEW_COUNT => 1, YEAR => $search_year });
  my $all_count = '';
  my @data_hash = ();
  my @data_hash2 = ();
  my $i = 1;
  foreach (@MONTHES) {
    $i = sprintf("%02d", $i);
    $Users->list({ REGISTRATION => "<=$search_year-$i" });
    $all_count = $Users->{TOTAL};
    $count_new_cust->{$i} ? push @data_hash, $count_new_cust->{$i} : push @data_hash, 0;
    $count_new_cust->{$i} ? push @data_hash2, $all_count += $count_new_cust->{$i} : push @data_hash2, $all_count;
    $i++;
  }
  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [ {
        data            => \@data_hash,
        label           => $lang{NEW_CUST},
        yAxisID         => 'left-y-axis',
        borderColor     => '#5cc',
        fill            => 'false',
        backgroundColor => '#5cc',
      }, {
        data            => \@data_hash2,
        label           => $lang{ALL},
        yAxisID         => 'right-y-axis',
        borderColor     => '#a6f',
        fill            => 'false',
        backgroundColor => '#a6f',
      } ],
      labels   => \@MONTHES
    },
    OPTIONS    => {
      tooltips => {
        mode => 'index',
      },
      scales => {
        yAxes => [ {
          id       => 'left-y-axis',
          type     => 'linear',
          position => 'left',
          ticks    => {
            stepSize => 50,
            min      => 0
          }
        }, {
          id       => 'right-y-axis',
          type     => 'linear',
          position => 'right',
          ticks    => {
            min => 0
          }
        } ]
      }
    }
  });

  my $pre_button = $html->button(" ", "index=$index&PRE=" . ($search_year - 1),
    { class => ' btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-left', TITLE => $lang{BACK} });
  my $next_button = $html->button(" ", "index=$index&NEXT=" . ($search_year + 1),
    { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-right', TITLE => $lang{NEXT} });
  print " <div class='col-lg-10'>
            <div class='box box-theme'>
              <div class='box-header with-border'>$pre_button $search_year $next_button<h4 class='box-title'>$lang{REPORT_NEW_ALL_USERS}</h4></div>
              <div class='box-body'>
                $chart3
              </div>
          </div>\n";
  return 1;
}
#**********************************************************
=head2 report_new_arpu() - show chart for new and all customers

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub report_new_arpu {
  my ($search_year, undef, undef) = split('-', $DATE);
  if ($FORM{NEXT} || $FORM{PRE}) {
    $search_year = $FORM{NEXT} || $FORM{PRE};
  }
  my $count_new_cust = $Users->info_user_reports({ LIST2HASH => 'reg_month,count',USER_NEW_COUNT => 1, YEAR => $search_year });
  my $summ_for_month = '';
  my $all_count = '';
  my $arpu_val = '';
  my @data_hash = ();
  my @data_hash2 = ();
  my $i = 1;
  foreach (@MONTHES) {
    $i = sprintf("%02d", $i);
    $summ_for_month = $Users->info_user_reports({ PAY_SUM => 1, YEAR => $search_year, MONTH => $i, COLS_NAME => 1 });
    $Users->list({ REGISTRATION => "<=$search_year-$i" });
    $all_count = $Users->{TOTAL};
    $arpu_val = ($summ_for_month->{sum} || 0)/($all_count || 1);
    $arpu_val = sprintf("%0.3f", $arpu_val);
    push @data_hash2, $arpu_val;
    $count_new_cust->{$i} ? push @data_hash, $count_new_cust->{$i} : push @data_hash, 0;
    $i++;
  }
  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [ {
        data            => \@data_hash2,
        label           => 'ARPU',
        yAxisID         => 'right-y-axis',
        borderColor     => '#3af',
        fill            => 'false',
        backgroundColor => '#3af',
      }, {
        data            => \@data_hash,
        label           => $lang{NEW_CUST},
        yAxisID         => 'left-y-axis',
        borderColor     => '#f68',
        fill            => 'false',
        backgroundColor => '#f68',
      }
      ],
      labels   => \@MONTHES
    },
    OPTIONS    => {
      tooltips => {
        mode => 'index',
      },
      scales   => {
        yAxes => [ {
          id       => 'right-y-axis',
          type     => 'linear',
          position => 'right',
          ticks    => {
            stepSize => 500,
            min => 0
          }
        },
        {
          id       => 'left-y-axis',
          type     => 'linear',
          position => 'left',
          ticks    => {
            stepSize => 50,
            min      => 0
          }
        }
        ]
      }
    }
  });

  my $pre_button = $html->button(" ", "index=$index&PRE=" . ($search_year - 1),
    { class => ' btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-left', TITLE => $lang{BACK} });
  my $next_button = $html->button(" ", "index=$index&NEXT=" . ($search_year + 1),
    { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-right', TITLE => $lang{NEXT} });
  print " <div class='col-lg-10'>
            <div class='box box-theme'>
              <div class='box-header with-border'>$pre_button $search_year $next_button<h4 class='box-title'>$lang{REPORT_NEW_ARPU_USERS}</h4></div>
              <div class='box-body'>
                $chart3
              </div>
          </div>\n";
  return 1;
}
#**********************************************************
=head2 report_balance_by_status() - Shows table with statuses,users count and sum deposits

  Arguments:

  Returns:

=cut
#**********************************************************
sub report_balance_by_status {
  use Service;
  use Internet;
  my $Internet = Internet->new($db, $admin, \%conf);
  my $Service = Service->new( $db, $admin, \%conf );
  my $status_list = $Service->status_list({
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
    COLS_NAME => 1,
    SORT      => 'id',
    DESC      => 'ASC'
  });
  my $table = $html->table({
    width       => '100%',
    caption     => $lang{REPORT_BALANCE_BY_STATUS},
    title_plain => [
      $lang{STATUS},
      "$lang{COUNT} $lang{USERS}",
      $lang{BALANCE},
    ],
    qs          => $pages_qs,
    ID          => 'BALANCE_BY_STATUS'
  });
  foreach my $item (@$status_list) {
    my $report_data = $Internet->report_user_statuses({STATUS =>$item->{id}, COLS_NAME => 1});
    $table->addrow(
      $html->color_mark(_translate($item->{name}), $item->{color}),
      (defined $report_data->{status} && ($item->{id} eq $report_data->{status}))? $report_data->{COUNT}: 0,
      (defined $report_data->{status} && ($item->{id} eq $report_data->{status}))? sprintf("%0.2f", $report_data->{deposit}): 0,
    )
  }
  print $table->show();
  return 1;
}
1;