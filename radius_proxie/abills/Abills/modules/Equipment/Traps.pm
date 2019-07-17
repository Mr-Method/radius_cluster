=head1 NAME

  SNMP TRAP Maagment

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(ip2int mk_unique_value);
$conf{EQUIP_NEW}=1;
our(
  %lang,
  $Equipment,
  $html,
  $admin
);

#**********************************************************
=head2 equipment_traps()

=cut
#**********************************************************
sub equipment_traps {
  my ($attr) = @_;

  $LIST_PARAMS{PAGE_ROWS} = $attr->{PAGE_ROWS};
#  $pages_qs .= ($FORM{FILTER_FIELD}) ? "&FILTER_FIELD=$FORM{FILTER_FIELD}" : q{};
  my $panel = ($conf{EQUIP_NEW})? 'equipment_panel_new':'equipment_panel';

  my $tcolors = $Equipment->trap_type_list( { NAME => '_SHOW', EVENT => '_SHOW'} );
  our %color_of;
  my @events_arr;
  foreach my $tcolor (@$tcolors) {
  	$color_of{$tcolor->[0]} = $tcolor->[2];
  	push @events_arr, $tcolor->[0] if ($tcolor->[1] == 1);
  }
  
  if ($FORM{EVENTS}){
    $LIST_PARAMS{EVENTNAME} = join(",", @events_arr);
  }
  
  if ($FORM{TRAP_ID}){
    my $trap = $Equipment->trap_list({ COLS_NAME => 1,
    								   TRAP_ID   => $FORM{TRAP_ID},
    								   VARBINDS  => '_SHOW',
    								   TRAPTIME  => '_SHOW',
    								   NAME      => '_SHOW',
    								   NAS_IP    => '_SHOW',
    								   EVENTNAME => '_SHOW',
    								   TRAPOID   => '_SHOW',
    								    })->[0];
    my $vr = JSON->new->utf8(0)->decode( $trap->{varbinds} );
    my @format;
    foreach my $k (sort keys %$vr) {
    	push @format,label_w_text({ NAME => $k, TEXT => $vr->{$k}, CTRL =>1 })
    }
    $html->message( $color_of{$trap->{eventname}} || 'info',
    				"$trap->{name} ~ $trap->{nas_ip} ~ $trap->{traptime} ~ $trap->{trapoid}",
    				);
    print "<form class='form-horizontal'>@format</form>"
  }
  
  sub color_it{
    my ($text) = @_;
    return ($color_of{$text})? "<b class='text-$color_of{$text}'>$text</b>" : $text;
  }

 result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'trap_list',
    BASE_FIELDS     => -1,
    DEFAULT_FIELDS  => 'TRAPTIME, NAME, NAS_IP, EVENTNAME, NAS_ID',
    FUNCTION_FIELDS => 'equipment_traps:change:trap_id;&pg='.($FORM{pg}||''),
    EXT_TITLES      => {
      traptime    => $lang{TIME},
      name        => $lang{NAME},
      eventname   => $lang{EVENTS},
      nas_ip      => "IP ".$lang{ADDRESS},
     },
    SKIP_USER_TITLE => 1,
    FILTER_COLS  => {
      eventname => 'color_it',
      name      => "search_link:$panel:,NAS_ID",
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{TRAPS}",
      header  => $html->button( "$lang{CONFIG} $lang{TRAPS}", "index=".get_function_index( 'equipment_traps_types' ), { class => 'change' } ),
      qs      => $pages_qs,
      ID      => 'TRAPS_LIST',
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

}

#********************************************************
=head2 equipment_traps_clean()

=cut
#********************************************************
sub equipment_traps_clean{
  $Equipment->traps_del({ PERIOD => $conf{TRAPS_CLEAN_PERIOD} || 30 });
}

#**********************************************************
=head2 equipment_monitor()

=cut
#**********************************************************
sub equipment_monitor {
  my $traps_pg_rows = $FORM{FILTER} || 10;

  my $equipment = $Equipment->_list( {
    COLS_NAME => 1,
    NAS_IP    => '_SHOW',
    STATUS    => '_SHOW',
    NAS_NAME  => '_SHOW',
    PAGE_ROWS => '10000'
  } );

  #my $traps =
  $Equipment->trap_list( {
    NAS_IP    => '_SHOW',
    DOMAIN_ID => $admin->{DOMAIN_ID} || undef,
    PAGE_ROWS => '10000'
  } );

  my @not_avail = ();
  my @handling = ();
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $html->color_mark("Offline Hosts", 'red'),
      title      => [ $lang{'NAME'}, 'IP', 'NAS_ID' ],
      cols_align => [ 'left', 'left', 'left', 'left' ],
      ID         => 'EQUIPMENT_TEST',
    }
  );

  my $rows_count = 0;
  foreach my $key (@$equipment) {
    if ($key->{status} == 1) {
      push @not_avail, $key->{nas_ip};
      #Use $html->color_mark
      $table->addrow( $html->color_mark( $key->{nas_name}, "bg-danger" ), $key->{nas_ip}, $key->{nas_id}, );
      $rows_count++;
    }
    if ($key->{status} == 4) {
      push @handling, $key->{nas_ip};
    }
  }

  my @deskpan = ({
    ID     => mk_unique_value( 11 ),
    NUMBER => ($equipment) ? scalar @$equipment : 0,
    ICON   => 'stats',
    TEXT   => $html->button( $lang{TOTAL}, "index=".get_function_index( 'equipment_list' ) ),
    COLOR  => 'green',
    SIZE   => 3
  });

  if (@handling) {
    push @deskpan, {
        ID     => mk_unique_value( 11 ),
        NUMBER => scalar @handling,
          ICON   => 'list',
          TEXT   => $html->button( "Maintenance", "index=".get_function_index( 'equipment_list' ) ),
          COLOR  => 'blue',
          SIZE   => 3
      };
  }

  if (@not_avail) {
    push @deskpan, {
        ID     => mk_unique_value( 11 ),
        NUMBER => scalar @not_avail,
          ICON   => 'remove',
          TEXT   => $html->button( "Offline", "index=".get_function_index( 'equipment_list' ) ),
          COLOR  => 'red',
          SIZE   => 3
      };
  }

  $html->short_info_panels_row( \@deskpan );

  if (@not_avail) {
    print $table->show();
  }

  equipment_traps( {PAGE_ROWS => $traps_pg_rows, } );

  print $html->form_main(
    {
      CONTENT => 
        "Only with events ".$html->form_input( 'EVENTS', 1, { TYPE => 'checkbox', STATE => $FORM{EVENTS} || undef }).
        " $lang{TRAPS}: ".$html->form_input( 'FILTER', int( $FORM{FILTER} || 10 ), { SIZE => 4 } ).
        " $lang{REFRESH} (sec): ".$html->form_input( 'REFRESH', int( $FORM{REFRESH} || 60 ), { SIZE => 4 } ).
        $html->form_input( 'SHOW', $lang{SHOW}, { TYPE => 'SUBMIT' } ),
      METHOD  => 'GET',
      class   => 'form-inline',
      HIDDEN  => { index => "$index" },
    } );

  return 1;
}

#**********************************************************
=head2 equipment_traps_types() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub equipment_traps_types {

if ( $FORM{del} ) {
	$Equipment->trap_type_del( $FORM{del} );
  }

if ( $FORM{SAVE} && $FORM{ID} && $FORM{NAME} ) {
	$Equipment->trap_type_change( { ID    => $FORM{ID},
								    NAME  => $FORM{NAME},
								    TYPE  => $FORM{TYPE},
								    EVENT => $FORM{EVENT} || 0,
								    COLOR => $FORM{COLOR},
								    VARBIND => $FORM{VARBIND},
							    } );
  } elsif ( !$FORM{ID} && $FORM{NAME} ) {
  	$Equipment->trap_type_add({ NAME => $FORM{NAME},
								TYPE  => $FORM{TYPE},
								EVENT => $FORM{EVENT} || 0,
								COLOR => $FORM{COLOR},
								VARBIND => $FORM{VARBIND},
							});
  }

my $params = $Equipment->trap_type_list( {
  COLS_NAME    => 1,
  ID		   => $FORM{chg} ||  '_SHOW',
  NAME         => '_SHOW',
  TYPE         => '_SHOW',
  EVENT        => '_SHOW',
  COLOR        => '_SHOW',
  VARBIND      => '_SHOW',
} );
my %types = ( 0 => ' ',
			  1 => "ethernet",
			  2 => "power",
			  3 => "cpu",
			  4 => "memory"
    		);

if ( !$FORM{chg} && !$FORM{add}) {
  result_former({
    INPUT_DATA      => $Equipment,
    LIST            => $params,
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,TYPE,EVENT,COLOR',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id          => '#',
      name        => $lang{NAME},
      type        => $lang{TYPE},
      event       => $lang{EVENTS},
      color       => $lang{COLOR},
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => { event =>{ 0 => " ", 1 => " :glyphicon glyphicon-ok" },
    					 type => \%types
    				   },
    FILTER_COLS  => {
      name => '_translate'
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{TRAPS}",
      qs      => $pages_qs,
      ID      => 'TRAP_TYPE_LIST',
      MENU		=> "$lang{ADD}:index=$index$pages_qs&add=1:add",
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });
} else {
	my $NAME_SEL = $html->form_select(
    'NAME',
    	{
      		SELECTED  => $params->[0]->{name}|| '',
      		SEL_LIST  => $Equipment->trap_list( { COLS_NAME => 1, EVENTNAME => '_SHOW', GROUP => 'eventname' } ),
      		SEL_KEY   => 'eventname',
      		SEL_VALUE => 'eventname',
      		NO_ID     => 1
    	}
    );
    my $COLOR_SEL = $html->form_select(
    'COLOR',
    	{
    	  SELECTED  => $params->[0]->{color}|| '',
	      SEL_ARRAY => ['','success', 'warning', 'danger', 'info'],
    	}
    );

    my $TYPE_SEL = $html->form_select(
    'TYPE',
    	{
    	  SELECTED => $params->[0]->{type},
	      SEL_HASH => \%types,
	      NO_ID    => 1
    	}
    );
	$html->message( 'warning', (($FORM{chg})? $lang{CHANGE} : $lang{CREATE}) ."  <span class='fa fa-cog fa-spin'></span>" );
	
	print $html->form_main(
	  	{
        	CONTENT =>  label_w_text({ NAME => $lang{NAME}, TEXT => $NAME_SEL }).
        				label_w_text({ NAME => $lang{TYPE},
        							   TEXT => $TYPE_SEL }).
        				label_w_text({ NAME => $lang{EVENTS},
        							   TEXT => $html->form_input('EVENT', 1,
        							   { TYPE => 'checkbox', STATE => $params->[0]->{event}||undef }) }).
        				label_w_text({ NAME => $lang{COLOR}, TEXT => $COLOR_SEL }).
        				label_w_text({ NAME => 'Varbinds', TEXT => $html->form_input('VARBIND', $params->[0]->{varbind}||undef )}).
    					label_w_text({ RCOL => 3,
    					               TEXT => $html->form_input( 'SAVE', ( $FORM{chg} )? $lang{CHANGE} : $lang{CREATE}, { TYPE => 'SUBMIT' } ) . "	".
    											$html->button($lang{CANCEL}, "index=$index$pages_qs", {class =>"btn btn-default"})
    								  }),
    	    METHOD  => 'GET',
        	HIDDEN  => {
          				'index' => $index,
          				'ID'    => $FORM{chg},
        				},
      	} );
}

  return 1;
}


1;