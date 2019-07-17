#!/usr/bin/perl -w
=head1 NAME

  charts.cgi

=head2 SYNOPSIS

  This CGI is used to see a traffic by severous types.

  Traffic type can be one of:
    * NAS
    * UID (Login)
    * Tags
    * Group
    * Tarrif plans

=cut

use strict;
use warnings 'FATAL' => 'all';

our ($libpath, %lang, $conf);

BEGIN {
  $libpath = '../';

  our $begin_time = 0;
  eval {
    require Time::HiRes;
  };

  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = Time::HiRes::gettimeofday();
  }
}


use lib $libpath . 'lib/';
use lib $libpath . 'libexec/';
use lib $libpath;
use lib $libpath . 'Abills/';
use lib $libpath . "Abills/mysql/";

my $VERSION = 0.23;

eval { require "libexec/config.pl" };
if ( $@ ){
  print "Content-Type: text/html\n\n";
  print "Can't load config file 'config.pl' <br>";
  print "Check ABillS config file /usr/abills/libexec/config.pl";
  die;
}

use POSIX qw(strftime);
use Abills::Defs;
use Abills::Base qw ( in_array days_in_month convert gen_time _bp );
use Abills::SQL;
use Abills::HTML;
use Time::Local qw/timelocal/;

use Admins;

require Abills::Misc;

my $db = Abills::SQL->connect( @conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef } );
my $admin = Admins->new( $db, \%conf );

my $debug = 0;
my $log = '';

#$is_ipn is global flag, that gets up if no traffic in `s_detail` table or NAS_TYPE matches listed below types
my $is_ipn = 0;

my $chartCounter = 0;
my $chart_number = 0;
my $ipn_module_enabled = 0;

$FORM{session_id} = '';

#Flag for showing 'all' of the type
my $multi_sel = 0;

my $html = Abills::HTML->new(
  {
    CONF     => \%conf,
    NO_PRINT => 0,
    PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $conf{default_charset},
  }
);

$html->{language} = $FORM{language} if (defined( $FORM{language} ) && $FORM{language} =~ /[a-z_]/);
if($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

do $libpath . "/language/$html->{language}.pl";

#Count of graphics
my %ids = ();

my @charts = ();
my $type = '';

my %traffic_classes = ();

my $DAILY_PERIOD = 86400;
my $WEEKLY_PERIOD = 7 * $DAILY_PERIOD;
my $MONTHLY_PERIOD = 30 * $DAILY_PERIOD;

my $named_period = '';
my $explicit_period = 0;
my $explicit_date = '';

my @periods = ();

my %type_names_for = ();

$lang{RECV}  = $lang{RECV} || 'Received';
$lang{SENT}  = $lang{SENT} || 'Sent';
$lang{LOCAL} = $lang{LOCAL} || 'Local';

my $RECV_TRAFF_NAME_GLOBAL = $lang{RECV};
my $SENT_TRAFF_NAME_GLOBAL = $lang{SENT};
my $RECV_TRAFF_NAME_LOCAL  = "$lang{RECV} $lang{LOCAL}";
my $SENT_TRAFF_NAME_LOCAL  = "$lang{SENT} $lang{LOCAL}";

#begin
print "Content-Type: text/html\n\n";

load_pmodule( 'JSON' );
load_pmodule( 'Time::Local' );

if ( scalar ( keys %FORM ) > 0 ){

  #Read debug from $FORM
  $debug = $FORM{DEBUG} || $debug;

  #Enable DB debug if debug level is higher or equal 2
  $admin->{debug} = $debug >= 2;

  #check if Ipn module enabled
  $ipn_module_enabled = in_array( 'Ipn', \@MODULES );

  #Default chart type is bits
  $FORM{type} = 'bits' if (!$FORM{type});

  #Transform from old period type
  if ( $FORM{period} && $FORM{period} ne 'all' ){
    $FORM{$FORM{period}} = 1;
  }

  if ( $FORM{DAILY} || $FORM{MONTHLY} || $FORM{WEEKLY} ){
    if ( $FORM{DAILY} ){
      $named_period = $lang{DAY};
      $explicit_period = $DAILY_PERIOD;
    }
    elsif ( $FORM{MONTHLY} ){
      $named_period = $lang{MONTH};
      $explicit_period = $MONTHLY_PERIOD;
    }
    elsif ( $FORM{WEEKLY} ){
      $named_period = $lang{WEEK};
      $explicit_period = $WEEKLY_PERIOD
    }
  }
  elsif ( $FORM{periods} ){
    #Use tabbed view
    @periods = (1, 2, 3);
  }

  if ( $FORM{DATE} && $FORM{DATE} ne '' && $FORM{DATE} =~ /\d{4}-\d{2}-\d{2}/ ){
    my ($year, $mon, $mday) = split( /-/, $FORM{DATE} );
    ($year, $mon, $mday) = map { int( $_ ) }($year, $mon, $mday);
    my $time = timelocal( 1, 0, 0, $mday, $mon - 1, $year );

    $explicit_date = $time;
  }

  if ( scalar @periods > 0 ){
    print_head();
    build_graphics( \%FORM );
    print_footer();
    exit( 0 );
  }

  build_graphics( \%FORM );

  if ( $FORM{SHOW_GRAPH} && $FORM{SHOW_GRAPH} == 1 ){
    print_head();
    print $charts[0];
    print_footer();
    exit( 0 );
  }
  else{
    show_page();
  }

}
else{
  print_head();
  $html->message( 'err', 'Incorrect parameters' );
  #  print_select_form();
}

#**********************************************************
=head2  build_graphics($attr) Parse input and make charts

=cut
#**********************************************************
sub build_graphics{
  my ($attr) = @_;

  my $period = $explicit_period || $DAILY_PERIOD;
  my $WHERE = '';
  my $bind_values = [];
  my $GROUP_BY = '';
  my $AS_5MIN = '';
  my $CAPTION = '';
  my $EXT_TABLE = '';
  
  $is_ipn = ( (exists $conf{CHARTS_BOTH_SCHEMES} && !$conf{CHARTS_BOTH_SCHEMES}) || is_ipn() );

  if ( $attr->{'ACCT_SESSION_ID'} ){
    $WHERE = "acct_session_id= ?";
    push(@{$bind_values}, $attr->{ACCT_SESSION_ID});
    $CAPTION = "ACCT_SESSION_ID";
    %ids = ($attr->{'ACCT_SESSION_ID'} => $attr->{'ACCT_SESSION_ID'});
  }

  ################## LOGIN #########################
  elsif ( $attr->{'LOGIN'} ){

    $type = $lang{USER};

    my @arr = split( /,/, $attr->{'LOGIN'} );
    my $logins = join( "' ,  '", @arr );

    $CAPTION = "LOGIN";
    %ids = ($attr->{'LOGIN'} => $logins);
    $WHERE = "u.id in (?)";
    push(@{$bind_values}, $logins);
    $EXT_TABLE = "INNER JOIN users u ON (u.id=l.id) ";

    if ( $conf{DV_LOGIN} ){

      $admin->query2( "SELECT id FROM users u WHERE u.uid IN (SELECT uid FROM dv_main WHERE dv_login in ( '$logins' ))" );
      unless ( $admin->{errno} ){
        my $users_list = $admin->{list};

        if ( defined $users_list && scalar @{$users_list} > 0 ){
          $logins = @{$users_list}[0]->[0];
          $WHERE = " d.user_name in (?)";
          push(@{$bind_values}, $logins);
          $EXT_TABLE = " INNER JOIN dv_calls d ON (d.user_name=l.id) ";
        }
      }
    }

  }

  ################## UID #########################
  elsif ( $attr->{'UID'} ){

    $type = $lang{USER};
    if ( $attr->{'UID'} eq 'all' ){
      $multi_sel = 1;

      my $login_list = get_login_list();
      foreach my $line ( @{ $login_list } ){
        $ids{ $line->[0] } = convert( $line->[1], { win2utf8 => 1 } );
      }
    }
    else{
      %ids = ($attr->{'UID'} => $attr->{'UID'});
    }
    $WHERE = "u.uid=?";
    push(@{$bind_values}, $attr->{UID});
    $CAPTION = "USER UID";

    $EXT_TABLE = "INNER JOIN users u ON (u.uid=l.uid) ";
  }

  ################## NAS_ID #########################
  elsif ( $attr->{'NAS_ID'} ){
    $CAPTION = "NAS_ID";

    $type = 'NAS';
    if ( $attr->{'NAS_ID'} eq 'all' ){
      $multi_sel = 1;

      my $nas_list = get_nas_list();
      foreach my $line ( @{ $nas_list } ){
        $ids{ $line->[0] } = convert( $line->[1], { win2utf8 => 1 } );
      }
    }
    else{
      %ids = ($attr->{'NAS_ID'} => $attr->{'NAS_ID'});
    }
    $WHERE = "l.nas_id=?";
    push(@{$bind_values}, $attr->{'NAS_ID'});
    $GROUP_BY = "";
    $AS_5MIN = ", last_update DIV 300 AS 5min";
  }

  ################## TP_ID #########################
  elsif ( $attr->{'TP_ID'} ){
    $type = 'TP';
    $CAPTION = "TP_ID";
    if ( $attr->{'TP_ID'} eq 'all' ){
      $multi_sel = 1;

      my $tp_list = get_tp_list();
      foreach my $line ( @{ $tp_list } ){
        $ids{ $line->[0] } = convert( $line->[1], { win2utf8 => 1 } );
      }
    }
    else{
      %ids = ($attr->{'TP_ID'} => $attr->{'TP_ID'});
    }

    $WHERE = "dv.tp_id= ?";
    push(@{$bind_values}, $attr->{TP_ID});
  
    $EXT_TABLE = "INNER JOIN users u ON (u.id=l.id)
      INNER JOIN dv_main dv ON (dv.uid=u.uid) ";
  }

  ################## GID #########################
  elsif ( $attr->{'GID'} ){
    $type = 'Group';
    $CAPTION = "GROUP ID";

    if ( $attr->{'GID'} eq 'all' ){
      $multi_sel = 1;

      my $g_list = get_group_list();
      foreach my $line ( @{ $g_list } ){
        $ids{ $line->[0] } = convert( $line->[1], { win2utf8 => 1 } );
      }
    }
    else{
      %ids = ($attr->{'GID'} => $attr->{'GID'});
    }
    $WHERE = "u.gid=?";
    push(@{$bind_values}, $attr->{GID});
  
    $EXT_TABLE = "INNER JOIN users u ON (u.id=l.id) ";
  }

  ################## TAGS #########################
  elsif ( $attr->{'TAG_ID'} ){

    $type = 'Tag';
    $CAPTION = $lang{TAGS};

    %ids = ($attr->{'TAG_ID'} => $attr->{'TAG_ID'});

    $WHERE = "tu.tag_id= ?";
    push(@{$bind_values}, $attr->{TAG_ID});
  
    $EXT_TABLE = "INNER JOIN tags_users tu ON (tu.uid=l.id) ";
  }
  else{
    print_head();

    $html->message( 'warn', $lang{ERR_WRONG_DATA},
      "<a href=charts.cgi class='btn btn-lg btn-primary'>$lang{RETURN_TO_START_PAGE}</a>" );

    print_footer();
    exit( 0 );
  }

  if ( $admin->{errno} ){
    $html->message( 'danger', 'SQL Error', $admin->{errstr} )
  }

  my $i = 0;
  foreach my $key ( sort keys %ids ){
    $i++;

    if ( $multi_sel ){
      my $search_key = $WHERE;
      $search_key =~ s/=.*$//g;
      $WHERE = "$search_key='$key'";
    }

    if ( $attr->{NAS_ID} ){
      $admin->query2( "SELECT nas_type FROM nas WHERE id= ? ;", undef, { Bind => [ $key ] } );
      $attr->{NAS_TYPE} = $admin->{list}[0][0];
    }

    if ( $period == $explicit_period ){
      my $start = $explicit_date || time();
      make_chart_for_period( $AS_5MIN, $EXT_TABLE, $WHERE, $bind_values, $period, $GROUP_BY, $CAPTION, $key, $start - $period,
        $start );
    }
    elsif ( scalar @periods > 0 ){
      my $charts_for_period = { };
      my $period_name = '';

      for ( my $p = 1; $p <= 3; $p++ ){
        my @bounds;
        if ( $p == 1 ){
          if ( $explicit_date ){
            @bounds = get_day_boundary( $explicit_date )
          }
          else{
            @bounds = get_day_boundary()
          }
          $period_name = $lang{DAY};
          $period = $DAILY_PERIOD;
        }
        elsif ( $p == 2 ){
          if ( $explicit_date ){
            @bounds = get_week_boundary( $explicit_date )
          }
          else{
            @bounds = get_week_boundary()
          }
          $period_name = $lang{WEEK};
          $period = $WEEKLY_PERIOD;
        }
        elsif ( $p == 3 ){
          if ( $explicit_date ){
            @bounds = get_month_boundary( $explicit_date )
          }
          else{
            @bounds = get_month_boundary()
          }
          $period_name = $lang{MONTH};
          $period = $MONTHLY_PERIOD;
        }

        $charts_for_period->{$p} = make_chart_for_period( $EXT_TABLE, $WHERE, $bind_values, $period,
          "$period_name $type", $key, $bounds[0], $bounds[1], 1 );
      }

      print "<br/><h4>$period_name $type <b>" . get_name_for( $key ) . "</b> ($key) </h4>";
      show_tabbed( $charts_for_period );
    }
    else{
      my @day_bounds;
      my @week_bounds;
      my @month_bounds;

      if ( $explicit_date ){
        @day_bounds = get_day_boundary( $explicit_date );
        @week_bounds = get_week_boundary( $explicit_date );
        @month_bounds = get_month_boundary( $explicit_date );
      }
      else{
        @day_bounds = get_day_boundary();
        @week_bounds = get_week_boundary();
        @month_bounds = get_month_boundary();
      }

      make_chart_for_period( $EXT_TABLE, $WHERE, $bind_values, $DAILY_PERIOD, "$lang{DAY} $type", $key, $day_bounds[0], $day_bounds[1] );
      make_chart_for_period( $EXT_TABLE, $WHERE, $bind_values, $WEEKLY_PERIOD, "$lang{WEEK} $type", $key, $week_bounds[0], $week_bounds[1] );
      make_chart_for_period( $EXT_TABLE, $WHERE, $bind_values, $MONTHLY_PERIOD, "$lang{MONTH} $type", $key, $month_bounds[0], $month_bounds[1] );
    }
  }

  return 1;
}

#**********************************************************
=head2 is_ipn()

 This function is used to toggle dv/ipn logic.

=cut
#**********************************************************
sub is_ipn{
  return $is_ipn || ($FORM{NAS_TYPE} && ($FORM{NAS_TYPE} eq 'ipcad' || $FORM{NAS_TYPE} eq 'mikrotik_dhcp' || $FORM{NAS_TYPE} eq 'dhcp' ));
}


#**********************************************************
=head2 get_traffic($EXT_TABLE, $WHERE, $start, $period)

=cut
#**********************************************************
sub get_traffic{
  my ($EXT_TABLE, $WHERE, $bind_values, $start, $period ) = @_;
  
  my $multiply_for_bytes = ( $FORM{type} ne 'bytes' )
                             ? ' * 8 '
                             : '';
  
  my $end_time = $start + $period;
  
  my $list;
  if ( exists $conf{CHARTS_BOTH_SCHEMES} && $conf{CHARTS_BOTH_SCHEMES} ) {
    $list = [
      @{get_ipn_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, \@{$bind_values}, $start, $end_time)},
      @{get_pppoe_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, \@{$bind_values}, $start, $end_time)},
    ];
  }
  elsif ( $is_ipn ){
    $list = get_ipn_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, \@{$bind_values}, $start, $end_time);
  }
  else {
    $list = get_pppoe_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, \@{$bind_values}, $start, $end_time);
  }

#  _bp("Called by", [ caller ], {HEADER => 0, EXIT => 0, TO_CONSOLE => 0});
#  _bp('', [ 'scalar', scalar @{$list} ]);
  
  return $list;

}

#**********************************************************
=head2 get_ipn_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start_time, $end_time)

=cut
#**********************************************************
sub get_ipn_traffic {
  my ($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start_time, $end_time) = @_;
  
  my $traffic_classes = get_traffic_classes();
  
  #form query for each traffic class
  my $select_query_traffic_classes = '';
  my @traffic_classes_ids = sort (keys(%{$traffic_classes}));
  for ( my ($i, $len) = (0, scalar @traffic_classes_ids); $i < $len; $i++ ){
    $select_query_traffic_classes .= "SUM(IF(traffic_class=$i, l.traffic_in, 0)) $multiply_for_bytes, \n";
    $select_query_traffic_classes .= "SUM(IF(traffic_class=$i, l.traffic_out, 0)) $multiply_for_bytes";
    $select_query_traffic_classes .= ($i != $len - 1) ? ",\n" : '';
  }
  
  if ( $FORM{'LOGIN'} ){
    
    if ($conf{DV_LOGIN}){
      $admin->query2( "SELECT uid FROM dv_main WHERE dv_login= ? ;", undef, { Bind => [ $FORM{LOGIN} ] } );
    }
    else {
      $admin->query2( "SELECT uid FROM users WHERE id= ? ;", undef, { Bind => [ $FORM{LOGIN} ] } );
    }
    
    $WHERE = "l.uid=?";
    %ids = ($FORM{'LOGIN'} => $FORM{'LOGIN'});
    $EXT_TABLE = "INNER JOIN users u ON (u.uid=l.uid) ";
  }
  
  elsif ( $FORM{UID} ){
    $WHERE = "l.uid=?";
    %ids = ($FORM{UID} => $FORM{UID});
    $EXT_TABLE = '';
  }
  else{
    $EXT_TABLE =~ s/l\.id/l\.uid/g
  }
  
  $admin->query2( "SELECT UNIX_TIMESTAMP(l.start),
      $select_query_traffic_classes
      FROM ipn_log l
      $EXT_TABLE
      WHERE $WHERE and UNIX_TIMESTAMP(l.start) > $start_time and UNIX_TIMESTAMP(l.start) < ($end_time)
      GROUP BY 1
      ORDER BY l.start;",
     undef,
    { Bind => $bind_values }
    
  );
  
  _error_show($admin);
  
  return $admin->{list} || [];
}

#**********************************************************
=head2 get_pppoe_traffic()

=cut
#**********************************************************
sub get_pppoe_traffic {
  my ($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start_time, $end_time) = @_;
  
  $admin->query2( "SELECT l.last_update,
      SUM(l.recv1) $multiply_for_bytes,
      SUM(l.sent1) $multiply_for_bytes,
      SUM(l.recv2) $multiply_for_bytes,
      SUM(l.sent2) $multiply_for_bytes
      FROM s_detail l
      $EXT_TABLE
      WHERE $WHERE and l.last_update > $start_time and l.last_update < $end_time
      GROUP BY 1
      ORDER BY l.last_update;", undef
      , { Bind => $bind_values  }
  );
  _error_show($admin);
  
  return $admin->{list} || [];
}


#**********************************************************
=head2 make_chart_for_period - Get traffic for period and make chart

  Arguments:

    $AS_5MIN - SQL statement argument
    $EXT_TABLE - SQL statement argument
    $WHERE - SQL statement argument
    $period - SQL statement argument
    $GROUP_BY - SQL statement argument

    $CAPTION -  Caption for chart

    $key - ID of current Chart type

    $start - timestamp
    $end - timestamp
    OUTPUT2RETURN

=cut
#**********************************************************
sub make_chart_for_period{
  my ($EXT_TABLE, $WHERE, $bind_values, $period, $CAPTION, $key, $start, $end, $OUTPUT2RETURN) = @_;
  
  my $traffic_list = get_traffic( $EXT_TABLE, $WHERE, $bind_values, $start, $period);

  my $name  = get_name_for( $key ) || '';
  my $title = "$CAPTION: '$name' ($key) ";
  my $chart = make_chart( $traffic_list, $title, $start, $end );

  unless ( $OUTPUT2RETURN ){
    push @charts, $chart;
    return 1;
  }

  return $chart;
}


#**********************************************************
=head2 make_chart($list, $title, $start, $end) - Convert list to chart

=cut
#**********************************************************
sub make_chart{
  my ($list, $title, $start, $end) = @_;
  
  if ( $debug >= 1 ){
    log_debug( "make chart $title. Start: ", "$start  ;" . localtime( $start ), 3 ) if ($debug >= 3);
    log_debug( "make chart $title. End: ", "$end  ;" . localtime( $end ), 3 )  if ($debug >= 3);
    log_debug( "make chart DAYS:", ( $end - $start ) / $DAILY_PERIOD, 3 )  if ($debug >= 3);
    print "<hr><b>$title</b>";
  }

  my $series = form_chart_series( {
      LIST           => $list,
        NAMES        => (is_ipn()) ? get_traffic_classes_names() : [
          $RECV_TRAFF_NAME_GLOBAL,
          $SENT_TRAFF_NAME_GLOBAL,
          $RECV_TRAFF_NAME_LOCAL,
          $SENT_TRAFF_NAME_LOCAL
        ],
        PERIOD_START => $start,
        PERIOD_END   => $end
    } );

  #check for errors
  unless ( ref $series eq 'ARRAY' ){
    if ( $series eq "No data" ){

      my $named_start = POSIX::strftime "%Y-%m-%d", localtime( $start );
      my $named_end = POSIX::strftime "%Y-%m-%d", localtime( $end );

      return "<br> <b>$title</b>: <b>$named_start - $named_end </b> : $lang{NO_RECORD} <br>";
    }
    return $series;
  }

  my $chart_type = $FORM{type} || 'bits';

  my $chart = get_highchart(
    {
      TITLE     => "$named_period $title",
      Y_TITLE => "$lang{SPEED}, $chart_type",
      TYPE    => 'area',
      SERIES  => $series,
      HEIGHT  => $FORM{height},
      WIDTH   => $FORM{width},
    }
  );

  $is_ipn = 0;

  return $chart;
}

#**********************************************************
=head2 get_highchart($attr) - Build chart HTML from chart series

  Returns:
    HTML code
=cut
#**********************************************************
sub get_highchart{
  my ($attr) = @_;

  my $json = JSON->new->utf8( 0 );

  my $chartDivId = $attr->{CONTAINER} || "CHART_CONTAINER_" . $chartCounter++;
  my $chartType = $attr->{TYPE} || 'bar';
  my $series = $attr->{SERIES};
  my $chartTitle = $attr->{TITLE};
  my $chartYAxisTitle = $attr->{Y_TITLE} || 'null';

  my $chartSeries = $json->encode( $series );

  my $dimensions = '; width : 700px';
  if ( $attr->{HEIGHT} ){
    $dimensions = "; height : $attr->{HEIGHT}";
    if ( $attr->{WIDTH} ){
      $dimensions .= "; width : $attr->{WIDTH}";
    }
  }

  log_debug( "Dimensions", $dimensions, 1 ) if ($debug >= 1);

  my $result = qq{
   <div id='$chartDivId' style='margin: 5px auto; border: 1px solid silver $dimensions'></div>
    <script>
    jQuery(function () {

      Highcharts.setOptions({

        global: {
          timezoneOffset: (new Date).getTimezoneOffset()
        }

      });

      jQuery('#$chartDivId').highcharts({
        chart : { type: '$chartType', zoomType: 'x' },
        plotOptions: { series : { softTreshold : true, turboThreshold: 0, allowPointSelect: true } },
        title : { text: "$chartTitle"},
        series: $chartSeries,
        xAxis : { type : 'datetime' },
        yAxis : { title: { text: '$chartYAxisTitle' }},
        tooltip : {formatter : labelFormatter }
      });
    });
    </script>
};

  return $result;
}

#**********************************************************
=head2 form_chart_series($attr) - forms chart series from DB list

  Each line of list must be represented as [ timestamp, recv1, sent1, ..., recvN, sentN ]

  Counts speed

  Arguments:
    $attr
      LIST - Array ref list from db
      NAMES - Array ref with names of lines. MUST contain (LIST->[0]->length-1) elements

      PERIOD_START - timestamp
      PERIOD_END   - timestamp

  Returns:
    \@series

=cut
#**********************************************************
sub form_chart_series{
  my ($attr) = @_;

  unless ( defined $attr->{LIST} && ref $attr->{LIST} eq 'ARRAY' && defined $attr->{LIST}[0] && defined $attr->{NAMES} ){
    return "No data";
  }
  unless ( defined $attr->{PERIOD_START} && defined $attr->{PERIOD_END} ){
    return "Wrong input parameters.\n PERIOD_START and PERIOD_END are mandatory.";
  }

  my @traffic_list = @{ $attr->{LIST} };
  my @names = @{ $attr->{NAMES} };

  my $start = $attr->{PERIOD_START};
  my $end = $attr->{PERIOD_END};
  
  #check input params
  my $list_length = scalar @{ $traffic_list[0] } || 0;
  my $names_length = scalar @names || 0;

  my $series_count = $list_length - 1;

  if ( $names_length != $series_count && !$conf{CHARTS_BOTH_SCHEMES} ){

    unless ( $list_length ){
      return "No data";
    }
    return "Wrong input parameters.\n Count of \@lines ($series_count) MUST be equal to count of \@names($names_length).";

  };

  #init
  my @result_data_array = ();
  my @previous_row = (0);

  for ( my $i = 1; $i <= $series_count; $i++ ){
    push ( @previous_row, 0 );
    # Start data array from timestamp that equal to period_start
    # Multiplying to 1000 because JavaScript timestamp uses milliseconds
    $result_data_array[$i] = [ { x => +( $start * 1000 ), y => undef } ];
  }

  log_debug ( "series_count", "$series_count", 1 ) if ($debug);
  log_debug ( "names_length", "$names_length", 1 ) if ($debug);

  my $timestamp = 0;
  my $pause = 1;

  foreach my $line ( @traffic_list ){
    $timestamp = +( $line->[0] );
    $pause = ( $timestamp - $previous_row[0] ) || 1;

    # Ignore periods with more than 5 min pause
    if (($previous_row[0] && $pause > 600) && !$conf{CHARTS_LONG_PAUSE}){
      for ( my $i = 1; $i <= $series_count; $i++ ){
        push (@{$result_data_array[$i]},
          { x => +( $previous_row[0] * 1000 + 2 ), y => undef },
          { x => +( $timestamp * 1000 - 2 ), y => undef }
        );
      }
    }
    else{
      my ($traffic_delta, $speed) = (0, undef);
      for ( my $i = 1; $i <= $series_count; $i++ ){

        if ( $line->[$i] ){
          if ( $is_ipn ){
            $traffic_delta = $line->[$i];
          }
          # Ignore negative speed values
          elsif ( $previous_row[$i] && ( $line->[$i] >= $previous_row[$i]) ) {
            $traffic_delta = +( $line->[$i] - $previous_row[$i] );
          }
        }

        $speed = $traffic_delta / $pause;
        push ( @{$result_data_array[$i]}, { x => $timestamp * 1000, y => +( $speed ) } );
      }
    }

    @previous_row = @{ $line };
  }

  my @series = ();
  for ( my $i = 1; $i <= $series_count; $i++ ){
    # Finish data array with timestamp that corresponds to period end
    push @{$result_data_array[$i]}, { x => $end * 1000, y => undef };
    
    # Highcharts needs data to be sorted
    @{$result_data_array[$i]} = sort { $a->{x} <=> $b->{x} } @{$result_data_array[$i]};
    
    push @series, { name => $names[$i - 1], data => $result_data_array[$i] };
  }
  
  
  return \@series;
}


#**********************************************************
=head2 get_traffic_classes()

  If %traffic_classes are not filled, gots list from DB and fills %traffic_classes

  Returns
   hash_ref \%traffic_classes

=cut
#**********************************************************
sub get_traffic_classes{

  if ( scalar keys %traffic_classes <= 0 ){
    $admin->query2( "SELECT id, name FROM traffic_classes ORDER BY id", undef, { COLS_NAME => 1 } );

    foreach my $traffic_class ( @{ $admin->{list} } ){
      $traffic_classes{$traffic_class->{id}} = $traffic_class->{name};
    }
  }

  return \%traffic_classes;
}

#**********************************************************
=head2 get_traffic_classes_names()

  Returns list of traffic_names

=cut
#**********************************************************
sub get_traffic_classes_names{

  my $traffic_classes = get_traffic_classes();

  my @traffic_names = ();

  foreach my $traffic_class_id ( sort keys %{$traffic_classes} ){
    my $name = $traffic_classes->{$traffic_class_id};
    push @traffic_names, "$name $lang{RECV}";
    push @traffic_names, "$name $lang{SENT}";
  }

  return \@traffic_names;
}


#**********************************************************
=head2 get_day_boundary($set_day_time)

=cut
#**********************************************************
sub get_day_boundary{
  my ($set_day_time) = @_;

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

  if ( $set_day_time ){
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime( $set_day_time );
  }
  else{
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  }

  my $day_start_time = timelocal( 1, 0, 0, $mday, $mon, $year );
  my $day_end_time = timelocal( 59, 59, 23, $mday, $mon, $year );

  return ($day_start_time, $day_end_time);
}

#**********************************************************
=head2 msgs_get_week_boundary($set_day_time, $days_count)

  Arguments:
    $set_day_time - timestamp for day of week for which calculate boundary, if undefined returns current week bounds

  Return:
    \@week - array_ref with monthdays for week

=cut
#**********************************************************
sub get_week_boundary{
  my ($set_day_time) = @_;

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

  if ( $set_day_time ){
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime( $set_day_time );
  }
  else{
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  }

  my $week_start_day = ($mday > 7 ) ? $mday - $wday + 1 : 1;

  my $week_start_day_time = timelocal( 0, 0, 0, $week_start_day, $mon, $year );

  my $week_end_day_time = $week_start_day_time + $WEEKLY_PERIOD;

  return ($week_start_day_time, $week_end_day_time);
}


#**********************************************************
=head2 msgs_get_month_boundary($set_day_time, $days_count)

ARGUMENTS
  $set_day_time - timestamp for day of month for which calculate boundary, if undefined returns current month bounds
  $days_count   - num of days to display, if undefined is set to count of days in  month defined by  $set_day_time

RETURNS
  \@month - array_ref with start end end days

=cut
#**********************************************************
sub get_month_boundary{

  my ($set_day_time) = @_;

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
  if ( $set_day_time ){
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime( $set_day_time );
  }
  else{
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  }

  my $month_start_day_time = timelocal( 1, 0, 2, 1, $mon, $year );
  my $month_end_day_time = timelocal( 0, 0, 0, days_in_month( { DATE => $year + 1900 . '-' . ($mon + 1) . '-' . 1 } ),
    $mon, $year );

  log_debug( 'month_start_day_time', "$month_start_day_time  " . localtime( $month_start_day_time )) if ($debug >= 3);
  log_debug( 'month_end_day_time', "$month_end_day_time  " . localtime( $month_end_day_time ) ) if ($debug >= 3);

  return ($month_start_day_time, $month_end_day_time);
}

#**********************************************************
=head2 get_name_for($key)

=cut
#**********************************************************
sub get_name_for{
  my ($key) = @_;

  if ( !$type_names_for{$key} ){
    if ( $type eq 'TP' ){
      $type_names_for{$key} = @{ get_tp_list( $key ) }[0]->[1];
    }
    elsif ( $type eq 'NAS' ){
      $type_names_for{$key} = @{ get_nas_list( $key ) }[0]->[1];
    }
    elsif ( $type eq 'Group' ){
      $type_names_for{$key} = @{ get_group_list( $key ) }[0]->[1];
    }
    elsif ( $type eq 'Login' ){
      $type_names_for{$key} = @{ get_login_list( $key ) }[0]->[1];
    }
    elsif ( $type eq 'Tag' ){
      $type_names_for{$key} = @{ get_tags_list( $key ) }[0]->[1];
    }
    elsif ($type eq $lang{USER}) {
      $type_names_for{$key} = @{ get_uid_list( $key ) }[0]->[1] || do {
        print "$lang{USER} $lang{ERR_NOT_EXISTS}";
        exit 1;
      };
    }
    else{
      $type_names_for{$key} = '';
    }
  }

  return $type_names_for{$key};
}


sub show_tabbed{
  my ($charts_period) = @_;

  $chart_number++;
  my $tab_controls = qq{
    <!-- Nav tabs -->
    <ul class="nav nav-tabs" role="tablist">
      <li role="presentation" class="active"><a href="#tab_day_$chart_number" aria-controls="#tab_day_$chart_number" role="tab" data-toggle="tab">$lang{DAY}</a></li>
      <li role="presentation"><a href="#tab_week_$chart_number" aria-controls="#tab_week_$chart_number" role="tab" data-toggle="tab">$lang{WEEK}</a></li>
      <li role="presentation"><a href="#tab_month_$chart_number" aria-controls="#tab_month_$chart_number" role="tab" data-toggle="tab">$lang{MONTH}</a></li>
    </ul>
    };

  my $tabs = qq{
   <!-- Tab panes -->
    <div class="tab-content">
      <div role="tabpanel" class="tab-pane active" id="tab_day_$chart_number">
        $charts_period->{1}
      </div>
      <div role="tabpanel" class="tab-pane" id="tab_week_$chart_number">
        $charts_period->{2}
      </div>
      <div role="tabpanel" class="tab-pane" id="tab_month_$chart_number">
        $charts_period->{3}
      </div>
    </div>
    };

  print $tab_controls . $tabs;
}

#**********************************************************
#
#**********************************************************
sub get_tp_list{
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  if ( $id && $id ne '' ){
    $WHERE = "id=?";
    push @BIND_VALUES, $id;
  }

  $admin->query2( "SELECT id, name FROM tarif_plans $WHERE ORDER BY id;", undef , { Bind => \@BIND_VALUES }  );

  return $admin->{list} || [[0, 0]];
}

#**********************************************************
#
#**********************************************************
sub get_nas_list{
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  
  if ( $id && $id ne '' ){
    $WHERE = "id= ?  AND";
    push @BIND_VALUES, $id;
  }

  $admin->query2( "SELECT id, name FROM nas WHERE $WHERE disable=0 ORDER BY id;", undef , { Bind => \@BIND_VALUES }  );

  return $admin->{list} || [[0, 0]];
}

#**********************************************************
#
#**********************************************************
sub get_group_list{
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();

  if ( $id && $id ne '' ){
    $WHERE = "WHERE gid=?";
    push @BIND_VALUES, $id;
  }

  $admin->query2( "SELECT gid, name FROM groups $WHERE ORDER BY gid;", undef , { Bind => \@BIND_VALUES }  );

  return $admin->{list} || [[0, 0]];
}

#**********************************************************
#
#**********************************************************
sub get_login_list{
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  if ( $id && $id ne '' ){
    $WHERE = "id=? AND";
    push @BIND_VALUES, $id;
  }

  $admin->query2( "SELECT uid, id FROM users WHERE $WHERE disable=0 and deleted=0 ORDER BY id;", undef , { Bind => \@BIND_VALUES } );

  return $admin->{list} || [[0, 0]];
}

sub get_uid_list{
  my ($uid) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  if ( $uid && $uid ne '' ){
    $WHERE = "uid= ? AND";
    push @BIND_VALUES, $uid;
  }
  
  $admin->query2( "SELECT uid, id FROM users WHERE $WHERE disable=0 and deleted=0 ORDER BY uid;", undef , { Bind => \@BIND_VALUES } );

  return $admin->{list} || [[0, 0]];
}

#**********************************************************
#
#**********************************************************
sub get_tags_list{
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  if ( $id && $id ne '' ){
    $WHERE = "WHERE id= ?";
    push @BIND_VALUES, $id;
  }

  $admin->query2( "SELECT id, name FROM tags $WHERE ORDER BY name;", undef , { Bind => \@BIND_VALUES }  );

  return $admin->{list} || [[0, 0]];
}

#**********************************************************
=head2 print_head()

=cut
#**********************************************************
sub print_head{
  print << '[END]';
<!DOCTYPE HTML>
<HTML>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <meta http-equiv="Cache-Control" content="no-cache" />
    <meta http-equiv="Pragma" content="no-cache" />

    <link href="favicon.ico" rel="shortcut icon" />

    <!-- CSS -->
    <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/bootstrap.min.css' >

    <!-- Bootstrap -->
    <script src='/styles/default_adm/js/jquery.min.js'></script>
    <script src='/styles/default_adm/js/bootstrap.min.js'></script>

    <script src='/styles/default_adm/js/functions.js' type='text/javascript' language='javascript'></script>

    <script src="/styles/default_adm/js/charts/highcharts.js"></script>

    <title>ABillS Users Traffic</title>

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
</head>
<body>
<div class='container'>
<div class='row'>
<noscript> JavaScript required </noscript>
[END]

  return 1;
}

#**********************************************************
=head2 print_footer()

=cut
#**********************************************************
sub print_footer{

  my $traffic_type_html = '';

  unless ( $FORM{SHOW_GRAPH} && $FORM{SHOW_GRAPH} ne '' ){
    foreach my $name ( 'bits', 'bytes' ){
      if ( $FORM{type} && $FORM{type} eq "$name" ){
        $traffic_type_html .= $html->b( $name ) . ' ';
      }
      else{
        $ENV{QUERY_STRING} =~ s/\&type=\S+//g;
        $traffic_type_html .= "<a href='$SELF_URL?$ENV{QUERY_STRING}&type=$name' class='btn btn-default'>$name</a> \n";
      }
    }

    if ( $begin_time > 0 ){
      my $gen_time = gen_time( $begin_time );
      print "<hr><div class='row' id='footer'>" . "Version: $VERSION ( $gen_time )</div>";
    }
  }

  print << "[FOOTER]";
    <div id='type' class='col-md-4 pull-right'>  $traffic_type_html </div>

  </div> <!--row-->
  <script>
  function labelFormatter(){

      var trafficAmount = this.y;

      var result = '';
      var type = '';

      if (trafficAmount > 1000000000) {
        result = trafficAmount / (1024 * 1024 * 1024);
        type = 'G';
      }
      else if (trafficAmount > 1000000) {
        result = trafficAmount / (1024 * 1024);
        type = 'M';
      }
      else if (trafficAmount > 1000) {
        result = trafficAmount / 1024;
        type = 'K';
      }
      else {
        result = trafficAmount;
      }

      type+='$FORM{type}';

      var time = new Date(this.x);
       time = '<b>' + time.getUTCFullYear() + '/' + ensureLength(time.getUTCMonth()+1) + '/' + ensureLength(time.getUTCDay()) + '</b> ' +
            ensureLength(time.getHours()) + ':' + ensureLength(time.getMinutes());

      result = result.toFixed(2);

      return "<b>$lang{SPEED}</b> " + result + type + '/s' + '<br>';

    }
  function ensureLength(digit){
    return (new String(digit).length == 2) ? digit : ('0' + digit);
  }
  </script>
<div id='debug'> $log </div>
</div> <!--container-->
</body>
</html>
[FOOTER]

  return 1;
}


#**********************************************************
=head2 show_page() - Show charts

=cut
#**********************************************************
sub show_page{

  print_head();

  my %page_header = ();
  my $name = $lang{ALL};

  if ( $FORM{LOGIN} ){
    $page_header{HEADER_NAME} = $lang{USER};
    $page_header{VALUE} = "<a href='index.cgi?LOGIN_EXPR=$FORM{LOGIN}'>$FORM{LOGIN}</a>";
  }
  if ( $FORM{UID} ){
    if ($FORM{UID} ne 'all'){
      $name = get_name_for($FORM{UID});
    }
    $page_header{HEADER_NAME} = $lang{USER};
    $page_header{HEADER_VALUE} = $name;
  }
  elsif ( $FORM{SESSION_ID} ){
    if ( $FORM{SESSION_ID} ne 'all' ){
      $name = get_name_for( $FORM{SESSION_ID} )
    }
    $page_header{HEADER_NAME}='Session_id';
    $page_header{HEADER_VALUE}=$name;
  }
  elsif ( $FORM{TP_ID} ){
    if ( $FORM{TP_ID} ne 'all' ){
      $name = get_name_for( $FORM{TP_ID} )
    }
    $page_header{HEADER_NAME} = $lang{TARIF_PLAN};
    $page_header{HEADER_VALUE}= $name;
  }
  elsif ( $FORM{NAS_ID} ){
    if ( $FORM{NAS_ID} ne 'all' ){
      $name = get_name_for( $FORM{NAS_ID} )
    }
    $page_header{HEADER_NAME} = $lang{NAS};
    $page_header{HEADER_VALUE} = $name;

  }
  elsif ( $FORM{GID} ){
    if ( $FORM{GID} ne 'all' ){
      $name = get_name_for( $FORM{GID} )
    }
    $page_header{HEADER_NAME}=$lang{GROUP};
    $page_header{HEADER_VALUE}=$name;
  }
  elsif ( $FORM{TAG_ID} ){
    if ( $FORM{TAG_ID} ne 'all' ){
      $name = get_name_for( $FORM{TAG_ID} )
    }
    $page_header{HEADER_NAME}=$lang{TAGS};
    $page_header{HEADER_VALUE}=$name;
  }

  my $date_to_show = $FORM{DATE} || $DATE;

  print "<div class='page-header'><h3>$page_header{HEADER_NAME}: $page_header{HEADER_VALUE}</h3></div>";
  print "<h5><b>$lang{DATE}:</b> $date_to_show </h5><br>";

  foreach my $chart ( @charts ){
    print $chart;
  }

  print_footer();

  return 1;
}

#**********************************************************
=head2 log_debug($name, $str, $level) - saves debug information if log level is lower or equal to $level

  Debug information is showed after main page

=cut
#**********************************************************
sub log_debug{

  my ($name, $str) = @_;

  if ( ref $str eq 'ARRAY' ){
    $str = join ", ", @{$str};
  }

  $log .= "<hr><h4>$name</h4>$str";
  return 1;
}

1
