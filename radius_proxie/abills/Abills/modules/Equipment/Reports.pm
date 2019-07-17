#!perl

=head1 NAME

  Reports

  Error ID: 4xx

=cut

use strict;
use warnings FATAL => 'all';
use POSIX qw/strftime/;
use Equipment;
use Abills::Base qw(in_array int2byte ip2int mk_unique_value
  load_pmodule date_format _bp int2ip);
use Abills::Filters qw(_mac_former dec2hex);
use Nas;
#hjfjhgjg
our (
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  $var_dir,
  $DATE,
  $TIME,
  %permissions,
);

load_pmodule("JSON");

our $Equipment = Equipment->new($db, $admin, \%conf);

#*******************************************************************
=head2 equipment_start_page() 

=cut
#*******************************************************************
sub equipment_start_page {
  my ($attr) = @_;

  my %START_PAGE_F = ('equipment_count_report' => $lang{REPORT_EQUIPMENT}, 
                      'equipment_pon_report' => $lang{REPORT_PON} );

  return \%START_PAGE_F;
}
#*******************************************************************
=head2 equipment_count_report() - Show equipment info

=cut
#*******************************************************************
sub equipment_count_report {

  $Equipment->_list();
  my $total_count = $Equipment->{TOTAL} || '0';
  $Equipment->_list({STATUS => 0});
  my $active_count = $Equipment->{TOTAL} || '0';
  $Equipment->_list({STATUS => 1});
  my $inactive_count = $Equipment->{TOTAL} || '0';
  $Equipment->mac_log_list({MAC_UNIQ_COUNT => '_SHOW', COLS_NAME => 1});
  my $mac_uniq_count = $Equipment->{MAC_UNIQ_COUNT} || '0';

  my $table = $html->table(
      {
        width      => '100%',
        caption    => $html->button($lang{REPORT_EQUIPMENT}, "index=".get_function_index('equipment_list')),
        ID         => 'EQUIPMENT_INFO',
        rows       => [
          [ $lang{TOTAL_COUNT},    $total_count   ],
          [ $lang{ACTIVE_COUNT},   $active_count  ],
          [ $lang{PING_COUNT},     '-'            ],
          [ $lang{SNMP_COUNT},     '-'            ],
          [ $lang{INACTIVE_COUNT}, $inactive_count],
          [ $lang{UNIQ_MAC_COUNT}, $mac_uniq_count],
        ]
      }
    );
    
  my $report_equipment .= $table->show();
    
  return $report_equipment;

}
#*******************************************************************
=head2 equipment_pon_report() - Show pon info

=cut
#*******************************************************************
sub equipment_pon_report {
  my $onu_count = 0;
  my $inactive_onu_count = 0;
  $Equipment->_list({TYPE_ID => '4'});
  my $pon_count = $Equipment->{TOTAL} || '0';
  $Equipment->onu_list();
  $onu_count = $Equipment->{TOTAL} || '0';
  $Equipment->onu_list();
  my $branch_count = $Equipment->{TOTAL} || '0';
  $Equipment->onu_list({STATUS => 1});
  my $active_onu_count = $Equipment->{TOTAL} || '0'; 
  $Equipment->onu_list({STATUS => '3;2'});
  $inactive_onu_count = $Equipment->{TOTAL} || '0';
  $Equipment->onu_list({STATUS => '2'});
  my $notreg_onu = $Equipment->{TOTAL} || '0';
  my $bad_onu = $onu_count - $inactive_onu_count;

  my $table = $html->table(
      {
        width      => '100%',
        caption    => $html->button($lang{REPORT_PON}, "index=".get_function_index('equipment_pon_form')),
        ID         => 'PON_INFO',
        rows       => [
          [ $lang{OLT_COUNT},              $pon_count ],
          [ $lang{BRANCH_COUNT},           $branch_count      ],
          [ $lang{ONU_COUNT},              $onu_count  ],
          [ $lang{ACTIVE_ONU_COUNT},       $active_onu_count    ],
          [ $lang{INACTIVE_ONU_COUNT},     $inactive_onu_count  ],
          [ $lang{BAD_ONU_COUNT},          $bad_onu ],
          [ $lang{NOTREGISTRED_ONU_COUNT}, $notreg_onu ],

        ]
      }
    );
    
  my $report_onu .= $table->show();
    
  return $report_onu;

}

1;