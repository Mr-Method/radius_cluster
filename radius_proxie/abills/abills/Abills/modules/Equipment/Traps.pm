=head1 NAME

  SNMP TRAP Managment

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(ip2int mk_unique_value);
our(
  %lang,
  $Equipment,
  $html,
  %conf,
  $admin,
  $db
);

#**********************************************************
=head2 equipment_traps()

=cut
#**********************************************************
sub equipment_traps {
  my ($attr) = @_;
  if ($attr->{PAGE_ROWS}){
	  $LIST_PARAMS{PAGE_ROWS} = $attr->{PAGE_ROWS};
	  $LIST_PARAMS{MONIT} = 1;
  }
  if ($FORM{NAS_ID}){
    $LIST_PARAMS{NAS_ID} = $FORM{NAS_ID};
  }

  my $tcolors = $Equipment->trap_type_list( { NAME => '_SHOW', COLOR => '_SHOW', EVENT => '_SHOW', COLS_NAME    => 1,} );
  our %color_of;
  my @events_arr;
  foreach my $tcolor (@$tcolors) {
  	$color_of{$tcolor->{name}} = $tcolor->{color};
  	push @events_arr, $tcolor->{name} if ($tcolor->{event} == 1);
  }
  
  if ($FORM{EVENTS}){
    $LIST_PARAMS{TRAPOID} = join(",", @events_arr);
  }
  
 result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'trap_list',
    DEFAULT_FIELDS  => 'TRAPTIME, NAME, NAS_IP, EVENTNAME',
    #FUNCTION_FIELDS => 'equipment_traps:change:trap_id;&pg='.($FORM{pg}||''),
    HIDDEN_FIELDS   => 'NAS_ID,TRAPOID,VARBINDS',
    EXT_TITLES      => {
      traptime    => $lang{TIME},
      name        => $lang{NAME},
      eventname   => $lang{EVENTS},
      nas_ip      => "IP ".$lang{ADDRESS},
      varbinds    => $lang{VALUE},
      nas_id      => 'NAS ID',
    },
    SKIP_USER_TITLE => 1,
    FILTER_COLS  => {
      eventname => 'color_it::,VARBINDS,TRAPOID,TRAP_ID',
      name      => "search_link:equipment_info:,NAS_ID",
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{TRAPS}",
      header  => $html->button( "$lang{CONFIG} $lang{TRAPS}", "index=".get_function_index( 'equipment_traps_types' ), { class => 'change' } ),
      qs      => ($FORM{NAS_ID})? "$pages_qs&NAS_ID=$FORM{NAS_ID}" : $pages_qs,
      ID      => 'TRAPS_LIST',
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });
}


#********************************************************
=head2 color_it()

=cut
#********************************************************
sub color_it{
	my ($text, $attr) = @_;

	our %color_of;
	my $vr = JSON->new->utf8(0)->decode( $attr->{VALUES}->{VARBINDS} );
	my $color = $color_of{$attr->{VALUES}->{TRAPOID}} || '';
	$text  = ($color_of{$attr->{VALUES}->{TRAPOID}})? qq(<strong>$text</strong>) : $text;
	my @format;
	foreach my $k (sort keys %$vr) {
		push @format,label_w_text({ NAME => $k, TEXT => $vr->{$k}, CTRL => 1, RCOL => 8, LCOL=>4 })
	}
	my $modal = qq(
  	<div id="$attr->{VALUES}->{TRAP_ID}" class="modal fade" role="dialog">
  	  <div class="modal-dialog">
  	    <div class="modal-content">
  	      <div class="modal-header bg-$color">
  	        <button type="button" class="close" data-dismiss="modal">&times;</button>
  	        <h4 class="modal-title">$attr->{VALUES}->{TRAPOID}</h4>
  	      </div>
  	      <div class="modal-body">
  	        <form class='form-horizontal'>@format</form>
  	      </div>
  	    </div>
  	  </div>
  	</div>);
	my $link = qq(<a href="#$attr->{VALUES}->{TRAP_ID}" class="text-$color" data-toggle="modal" data-target="#$attr->{VALUES}->{TRAP_ID}">$text</a>);

	return $link.$modal;
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
=head2 label_w_text($attr); - return formated text with label

  Arguments:
    NAME - text of label
    TEXT 
    CTRL - for form with input control
    COLOR - color of label
    LCOL
    RCOL
      
  Returns:
    String with element

=cut
#**********************************************************
sub label_w_text {
	my ($attr) = @_;
	my @lable;
	push @lable, 'control-label' if (!$attr->{CTRL}) ;
	push @lable, "label-$attr->{COLOR}" if ($attr->{COLOR}) ;
	
	return "<div class='form-group'><label class='@lable col-sm-" . ($attr->{LCOL}||'2') . "'>".
				($attr->{NAME}||'') . "</label><div class='col-sm-" . ($attr->{RCOL}||'2') . "'>" . ($attr->{TEXT} || '') . "</div></div>";
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
	$Equipment->trap_type_change( { ID        => $FORM{ID},
								    NAME      => $FORM{NAME},
									OBJECT_ID => $FORM{OBJECT_ID},
								    TYPE      => $FORM{TYPE},
								    EVENT     => $FORM{EVENT} || 0,
									SKIP      => $FORM{SKIP} || 0,
								    COLOR     => $FORM{COLOR},
								    VARBIND   => $FORM{VARBIND},
							    } );
  } elsif ( !$FORM{ID} && $FORM{NAME} ) {
  	$Equipment->trap_type_add({ NAME      => $FORM{NAME},
								OBJECT_ID => $FORM{OBJECT_ID},
								TYPE      => $FORM{TYPE},
								EVENT     => $FORM{EVENT} || 0,
								SKIP      => $FORM{SKIP} || 0,
								COLOR     => $FORM{COLOR},
								VARBIND   => $FORM{VARBIND},
							});
  }

my $params = $Equipment->trap_type_list( {
  COLS_NAME    => 1,
  ID		   => $FORM{chg},
  NAME         => '_SHOW',
  OBJECT_ID    => '_SHOW',
  TYPE         => '_SHOW',
  SKIP         => '_SHOW',
  EVENT        => '_SHOW',
  COLOR        => '_SHOW',
  VARBIND      => '_SHOW',
} );
my %types = ( 0 => ' ',
			  1 => "ethernet",
			  2 => "power",
			  3 => "cpu",
			  4 => "memory",
			  5 => "mac_notif"
    		);
my $sel = $Equipment->trap_list( { 
	TRAPOID   => '_SHOW',
	EVENTNAME => '_SHOW',
	GROUP     => 'trapoid',
	COLS_NAME => 0,
	LIST2HASH => 'trapoid, eventname'
} );

if ( !$FORM{chg} && !$FORM{add}) {
  result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'trap_type_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'NAME,OBJECT_ID,TYPE,EVENT,SKIP,COLOR',
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
    					 skip  =>{ 0 => " ", 1 => " :glyphicon glyphicon-ok" },
						 type  => \%types,
						 name  => \%$sel
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
      		SEL_HASH  => \%$sel,
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
        	CONTENT =>  label_w_text({ NAME => $lang{NAME}, TEXT => $NAME_SEL, RCOL => 4 }).
        				label_w_text({ NAME => 'OBJECT_ID', TEXT => $html->form_input('OBJECT_ID', $params->[0]->{object_id}||undef )}).
						label_w_text({ NAME => $lang{TYPE}, TEXT => $TYPE_SEL }).
        				label_w_text({ NAME => $lang{EVENTS},
        							   TEXT => $html->form_input('EVENT', 1,
        							   { TYPE => 'checkbox', STATE => $params->[0]->{event}||undef }) }).
        				label_w_text({ NAME => $lang{COLOR}, TEXT => $COLOR_SEL }).
        				label_w_text({ NAME => 'Varbinds', TEXT => $html->form_input('VARBIND', $params->[0]->{varbind}||undef )}).
        				label_w_text({ NAME => 'Skip',
        							   TEXT => $html->form_input('SKIP', 1,
        							   { TYPE => 'checkbox', STATE => $params->[0]->{skip}||undef }) }).
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