
=head1 NAME

  Templates functions

=cut

use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);
use Dv;
require Abills::Misc;

our ($html,
  %lang,
  $admin,
  %conf,
  $db
);

our Equipment $Equipment;
my $Dv = Dv->new( $db, $admin, \%conf );


#**********************************************************

=head2 equipment_tmpl_edit($attr)

=cut

#**********************************************************
sub equipment_tmpl_edit {
  my ($attr) = @_;

  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $FORM{ID} || $attr->{ID},
      SECTION   => '_SHOW'
    }
  );
  my %menu;
  if ($tmpl) {
    foreach my $key ( 0..@$tmpl ) {
      $menu{$key} = $tmpl->[$key]->{section};
    }

    $pages_qs .= ($FORM{ID}) ? "&ID=$FORM{ID}" : q{};

    my $buttons;
    foreach my $key (sort keys %menu) {
      my $value = $menu{$key};
      $buttons .= $html->li($html->button($value, "index=$index&PARAM=$key$pages_qs"), { class => (defined($FORM{PARAM}) && $FORM{PARAM} eq $key) ? 'active' : '' });
    }
    $buttons .= $html->li(
      $html->button(
        (
          $lang{CREATE}, "index=$index$pages_qs",

          {
            MESSAGE => "$lang{CREATE} $lang{NEW}?",
            TEXT    => $lang{CREATE},
            class   => 'add'
          }
        )
      )
    );

    if ($buttons) {
      my $model_select = $html->form_select(
        'ID',
        {
          SELECTED => $attr->{ID} || $FORM{ID},
          SEL_LIST  => $Equipment->model_list({ MODEL_NAME => '_SHOW', MODEL_ID => '_SHOW', COLS_NAME => 1, PAGE_ROWS => 10000 }),
          SEL_KEY   => 'id',
          SEL_VALUE => 'model_name',
          NO_ID     => 1,

          #MAIN_MENU      => get_function_index( 'equipment_info' ),
          MAIN_MENU_ARGV => "ID=" . ($FORM{ID} || '')
        }
      );

      my $model_select_form = $html->form_main(
        {
          CONTENT => $model_select . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'submit' }),
          HIDDEN  => {
            'index' => $index,
            'PARAM' => $FORM{PARAM} ||= 0,
          },
          NAME  => 'model_edit_panel',
          ID    => 'equipment_edit_panel',
          class => 'navbar-form navbar-right',
        }
      );

      my $buttons_list = $html->element('ul', $buttons, { class => 'nav navbar-nav' });

      my $menu = $html->element('div', $buttons_list . $model_select_form, { class => 'navbar navbar-default' });

      print $menu;
    }

    my $cur_tmpl = ($FORM{PARAM}) ? $tmpl->[ $FORM{PARAM} ]->{parameters} : $tmpl->[0]->{parameters};
    my $values   = ($cur_tmpl)    ? JSON->new->utf8(0)->decode($cur_tmpl) : [];

    if ($FORM{ADD} || $FORM{DEL}) {
      my $sect;
      if ($FORM{ADD}) {
        my @tmp_arr;
        if (ref $values eq 'ARRAY') {
          foreach my $n (1..@$values) {
            push @tmp_arr, [ split(',', $FORM{$n}) ];
          }
          if ($FORM{OIDS}) {
            push @tmp_arr, [ $FORM{OIDS}, $FORM{NAME}, $FORM{TYPE}, $FORM{REGULAR} ];
          }
          $cur_tmpl = JSON->new->encode(\@tmp_arr);
          $cur_tmpl =~ s/\s//g;
        }
        else {
          my %tmp_hash;
          foreach my $key (sort keys %$values) {
            $tmp_hash{$key} = [ split(',', $FORM{$key}) ];
          }
          $cur_tmpl = JSON->new->encode(\%tmp_hash);
          $cur_tmpl =~ s/\s//g;
        }
      }
      elsif ($FORM{DEL}) {
        splice(@$values, $FORM{DEL} - 1, 1);
        $cur_tmpl = JSON->new->encode($values);
      }
      $Equipment->snmp_tpl_add(
        {
          MODEL_ID   => $FORM{ID},
          SECTION    => $sect || $tmpl->[ $FORM{PARAM} ||= 0 ]->{section},
          PARAMETERS => $cur_tmpl
        }
      );
    }
    $values = ($cur_tmpl) ? JSON->new->utf8(0)->decode($cur_tmpl) : [];
    my $table;
    $table = $html->table(
      {
        width       => '100%',
        title_plain => [ 'OID', $lang{NAME}, $lang{TYPE}, 'regular' ],
      }
    );

    if (ref $values eq 'ARRAY') {
      my $i = 1;
      foreach my $var (@$values) {
        my @arr;
        foreach my $vr ( 1..@$var) {
          push @arr, ($html->form_input($i, $var->[ $vr - 1 ]));
        }
        $table->addrow(
          @arr,
          $html->button(
            '',
            "index=$index$pages_qs&PARAM=$FORM{PARAM}&DEL=$i",
            {
              ICON  => 'glyphicon glyphicon-trash text-danger',
              title => $lang{DEL},
            }
          )
        );
        $i++;
      }

      $table->addrow($html->form_input('OIDS', ''), $html->form_input('NAME', ''), $html->form_input('TYPE', ''), $html->form_input('REGULAR', ''),);
    }
    else {
      $table = $html->table(
        {
          width => '100%',

          #title_plain => [ 'OID', $lang{NAME}, $lang{TYPE}, 'regular' ],
        }
      );
      foreach my $key (sort keys %$values) {
        my @arr;
        push @arr, $key;
        foreach my $vr (@{ $values->{$key} }) {
          push @arr, $html->form_input($key, $vr);
        }
        $table->addrow(@arr);
      }
    }
    print $html->form_main(
      {
        CONTENT => $table->show() . $html->form_input('ADD', "$lang{CHANGE}\/$lang{ADD}", { TYPE => 'SUBMIT' }),
        METHOD  => 'GET',
        class   => 'form-inline',
        HIDDEN  => {
          'index' => $index,
          'PARAM' => $FORM{PARAM} ||= 0,
          'ID'    => $FORM{ID}

        },
      }
    );
  }
  else {
    print $html->form_main(
      {
        CONTENT => "For this device no templates. Create new?" . $html->form_input('OIDS', '') . $html->form_input('NAME', '') . $html->form_input('TYPE', '') . $html->form_input('REGULAR', '') . $html->form_input('CREATE', $lang{CREATE}, { TYPE => 'SUBMIT' }),
        METHOD  => 'GET',
        class   => 'form-inline',
        HIDDEN  => {
          'index' => $index,
          'ID'    => $FORM{ID}

        },
      }
    );
  }

  return 1;
}

#**********************************************************

=head2 equipment_stats_edit()

=cut

#**********************************************************
sub equipment_stats_edit {
 my ($attr) = @_;
 
 $pages_qs .= ($FORM{NAS_ID} && $FORM{PORT}) ? "&NAS_ID=$FORM{NAS_ID}&PORT=$FORM{PORT}" : q{};
 my $root_index = get_function_index('equipment_panel_new') . "&NAS_ID=$FORM{NAS_ID}&visual=PORTS";
  
  if ( $FORM{DEL} ) {
	$Equipment->graph_del( $FORM{DEL} );
	require Equipment::Graph;
	if ( $FORM{TOTAL} && $FORM{TOTAL} == 1 ){
    	del_graph_data({ NAS_ID => $FORM{NAS_ID},
    		             PORT   => $FORM{PORT},
    		             TYPE   => $FORM{TYPE}
    		        	});
    }
  }
  
  if ( $FORM{SAVE} && $FORM{ID} && $FORM{NAME} ) {
	$Equipment->graph_change( { ID           => $FORM{ID},
								PARAM        => $FORM{NAME},
								COMMENTS     => $FORM{COMMENTS},
								MEASURE_TYPE => $FORM{TYPE},
							 } );
  } elsif ( !$FORM{ID} && $FORM{NAME} ) {
  	$Equipment->graph_add({ NAS_ID       => $FORM{NAS_ID},
							PORT         => $FORM{PORT},
							COMMENTS     => $FORM{COMMENTS},
							PARAM        => $FORM{NAME},
							MEASURE_TYPE => $FORM{TYPE},
							});
  }
  my $params = $Equipment->graph_list( {
    COLS_NAME    => 1,
    ID			 => $FORM{EDIT} ||  '_SHOW',
    NAS_ID       => $attr->{NAS_ID} || $FORM{NAS_ID},
    PORT         => $attr->{PORT} || $FORM{PORT} || '_SHOW',
    PARAM        => '_SHOW',
    MEASURE_TYPE => '_SHOW',
    COMMENTS     => '_SHOW',
    TOTAL        => 1
  } );
  
  if ( !$FORM{ADD} && !$FORM{EDIT}) {
  	my $size = ($params)? @$params : 0;
  	my $table = $html->table(
    		{
      			width       => '100%',
      			caption		=> "NAS ID: $FORM{NAS_ID}  $lang{PORT}: $FORM{PORT}",
      			MENU		=> "$lang{BACK}:index=$root_index:fees;$lang{ADD}:index=$index$pages_qs&ADD=1:add",
      			title_plain => [ $lang{NAME}, $lang{TYPE}, $lang{COMMENTS} ],
      			ID          => "STATS_EDIT",
      			HAS_FUNCTION_FIELDS => 1
    		}
    	);
  	foreach my $var (@$params) {
  		$table->addrow( $var->{param}, $var->{measure_type},$var->{comments},
    					$html->button('', "index=$index$pages_qs&EDIT=$var->{id}",
      							{
    								ICON  => 'glyphicon glyphicon-pencil text-info',
    								title => $lang{DEL},
      							}
      						).
    					$html->button('', "index=$index$pages_qs&TYPE=$var->{measure_type}&DEL=$var->{id}&TOTAL=$size",
      							{
    								ICON  => 'glyphicon glyphicon-trash text-danger',
    								title => $lang{DEL},
      							}
      						)
    				  );
  	}
  	print $table->show();
  } else {
	my $FIELDS_SEL = $html->form_select(
    'TYPE',
    	{
    	  SELECTED  => ( $FORM{EDIT} )?  $params->[0]->{measure_type}: $FORM{TYPE} ,
	      SEL_ARRAY => ['COUNTER', 'GAUGE', 'DERIVE'],
    	}
    );
	$html->message( 'warning', "NAS ID: $FORM{NAS_ID}  $lang{PORT}: $FORM{PORT} <span class='fa fa-cog fa-spin'> </span> " );
	
	print $html->form_main(
	  	{
        	CONTENT =>  label_w_text({ NAME => $lang{NAME},
        							   TEXT => $html->form_input('NAME', ( $FORM{EDIT} )?  $params->[0]->{param}:'') }).
        				label_w_text({ NAME => $lang{TYPE}, TEXT => $FIELDS_SEL }).
        				label_w_text({ NAME => $lang{COMMENTS},
        							   TEXT => $html->form_input('COMMENTS', ( $FORM{EDIT} )?  $params->[0]->{comments}:'') }).
    					label_w_text({ TEXT =>	$html->form_input( 'SAVE',
    															   ( $FORM{EDIT} )? $lang{CHANGE} : $lang{CREATE},
    															   { TYPE => 'SUBMIT' } ) . "	".
    											$html->button($lang{CANCEL}, "index=$index$pages_qs", {class =>"btn btn-default"})
    								  }),
    	    METHOD  => 'GET',
        	#class   => 'form-vertical',
        	HIDDEN  => {
          				'index' => $index,
          				'ID'    => $FORM{EDIT},
          				'NAS_ID'=> $FORM{NAS_ID},
          				'PORT'  => $FORM{PORT}
        				},
      	} );
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_vlan_data()

=cut

#**********************************************************
sub equipment_snmp_vlan_data {

  #my ($attr) = @_;
  #my @newarr;
  # $Equipment->{debug}=1;

  my $info = $Equipment->info_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      SECTION   => 'VLAN',
      RESULT    => '_SHOW'
    }
  );

  if ($info) {
    my $vars = JSON->new->utf8(0)->decode($info->[0]->{result});

    my $table = $html->table(
      {
        width => '100%',
        title => [ 'VID', 'Vlan Name', 'UntaggedPorts', 'EgressPorts' ],
        cols_align => [ 'left', 'left', 'left' ],
        ID         => 'EQUIPMENT_VLAN',
      }
    );
    foreach my $key (sort { $a <=> $b } keys %$vars) {
      $table->addrow("<b>$key</b>", "<b>$vars->{$key}->[0]</b>", join(", ", @{ $vars->{$key}->[1] }), join(", ", @{ $vars->{$key}->[2] }));
    }

    print $table->show();
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_port_data()

=cut

#**********************************************************
sub equipment_snmp_port_data {
  my ($attr) = @_;
  my @newarr;

  my $port_index =
  ($attr->{PORT})
  ? get_function_index('equipment_snmp_user_data') . "&UID=$attr->{UID}"
  : get_function_index('equipment_panel_new') . "&visual=PORTS";
  my $stats_index = get_function_index('equipment_stats_edit');

  my $info = $Equipment->info_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $attr->{NAS_ID} || $FORM{NAS_ID},
      NAS_IP    => '_SHOW',
      SECTION   => $attr->{SECT},
      RESULT    => '_SHOW'
    }
  );
  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $info->[0]->{model_id},
      SECTION   => $attr->{SECT}
    }
  );

  if ($info) {
    if ($FORM{test}) {
      my ($result, $status) = cable_test(
        {
          PORT     => $FORM{test},
          NAS_IP   => $info->[0]->{nas_ip},
          MODEL_ID => $info->[0]->{model_id}
        }
      );
      $html->message('info', "$lang{CABLE_TEST}: $lang{PORT} $FORM{test} <span class='fa fa-cog fa-spin'> </span> $status", "$result");
    }
    if ($tmpl && $info->[0]->{result}) {
      my $tit  = JSON->new->utf8(0)->decode($tmpl->[0]->{parameters});
      my $vars = JSON->new->utf8(0)->decode($info->[0]->{result});

      foreach my $key (@$tit) {
        push @newarr, $key->[1] || $key->[0];
      }

      my $table = $html->table(
        {
          width      => '100%',
          title      => [ '#', @newarr ],
          cols_align => [ 'left', 'left', 'left', 'left' ],
          ID         => 'EQUIPMENT_SNMP_PORTS_DATA',
        }
      );
      my %tmphash;
      foreach my $key (sort { $a <=> $b } keys %$vars) {
        if ($attr->{PORT}) {
          $tmphash{ $attr->{PORT} } = \@{ $vars->{ $attr->{PORT} } };
        }
        else {
          $tmphash{$key} = \@{ $vars->{$key} };
        }
      }
      foreach my $key (sort { $a <=> $b } keys %tmphash) {
        $table->addrow(
          $key,
          @{ $tmphash{$key} },
          $html->button(
            "$lang{CABLE_TEST}: $lang{PORT} $key",
            "index=$port_index&NAS_ID=$attr->{NAS_ID}&test=$key",
            {
              ICON  => 'glyphicon glyphicon-eye-open',
              title => "$lang{INFO}Port $key"
            }
          )
          . $html->button(
            "$lang{STATS}: $lang{PORT} $key",
            "index=$stats_index&NAS_ID=$attr->{NAS_ID}&PORT=$key",
            {
              ICON  => 'glyphicon glyphicon-pencil',
              title => "$lang{INFO}Port $key"
            }
          )
        );
      }
      print $table->show();
    }

  }
  else {
    print $html->form_main(
      {
        CONTENT => "No Data. Check Your Settings",
        class   => 'navbar-form navbar-centr',
      }
    );
  }

  return 1;
}

#********************************************************

=head2 equipment_panel_new()

=cut

#********************************************************
sub equipment_panel_new {
  my ($attr) = @_;

  $pages_qs .= ($FORM{NAS_ID}) ? "&NAS_ID=$FORM{NAS_ID}" : q{};

  my $traps_index = get_function_index('equipment_traps');
  my $edit_index  = get_function_index('equipment_info');
  $index = get_function_index('equipment_panel_new');
  if (!$FORM{NAS_ID} || $attr->{UID}) {
    my $equip = $Equipment->_list(
      {
        NAS_NAME     => '_SHOW',
        NAS_IP       => $FORM{nas_ip} || '_SHOW',
        NAS_ID       => $attr->{NAS_ID} || '_SHOW',
        COLS_NAME    => 1,
        PAGE_ROWS    => 1000,
        TYPE_NAME    => '_SHOW',
        MODEL_NAME   => '_SHOW',
        ADDRESS_FULL => '_SHOW',
        %LIST_PARAMS
      }
    );

    my $table = $html->table(
      {
        width => '100%',
        title => [ 'NAS_ID', $lang{NAME}, 'NAS_IP', $lang{TYPE}, $lang{MODEL}, $lang{ADDRESS} ],
        cols_align => [ 'left', 'left' ],
        ID         => 'EQUIPMENT_LIST',
        qs         => $pages_qs,
        HAS_FUNCTION_FIELDS => 1
      }
    );
    foreach my $key (@$equip) {
      $table->addrow(
        $key->{nas_id}, $html->button($key->{nas_name}, "index=$index&NAS_ID=$key->{nas_id}"),
        $key->{nas_ip}, $key->{type_name}, $key->{model_name}, $key->{address_full},
        $html->button($lang{TRAPS}, "index=$traps_index&NAS_IP=$key->{nas_ip}", { ICON => 'fa fa-table', }).
        $html->button($lang{EDIT},  "index=$edit_index&NAS_ID=$key->{nas_id}",  { ICON => 'fa fa-pencil-square-o', })
      );
    }
    print $html->element('div', $table->show(),);
    if (!$attr->{UID}) {
      print '<script>$(function () {
  			var $table = $(\'#EQUIPMENT_LIST_\');
  			var correct = ($table.find(\'tbody\').find(\'tr\').first().find(\'td\').length - $table.find(\'thead th\').length );
  			for (var i = 0; i < correct; i++) {
    		$table.find(\'thead th:last-child\').after(\'<th></th>\');
  			}
    		var dataTable = $table
      			.DataTable({
        			"language": {
          			paginate: {
              			first:    "«",
              			previous: "‹",
              			next:     "›",
              			last:     "»",
          			},
          			"zeroRecords":    "' . $lang{NOT_EXIST} . '",
          			"lengthMenu":     "' . $lang{SHOW} . ' _MENU_",
          			"search":         "' . $lang{SEARCH} . ':",
          			"info":           "' . $lang{SHOWING} . ' _START_ - _END_ ' . $lang{OF} . ' _TOTAL_ ",
          			"infoEmpty":      "' . $lang{SHOWING} . ' 0",
          			"infoFiltered":   "(' . $lang{TOTAL} . ' _MAX_)",
        			},
        			"ordering": false,
        			"lengthMenu": [[25, 50, -1], [25, 50, "' . $lang{ALL} . '"]]
      			});
            var column = dataTable.column("0");
            // Toggle the visibility
            column.visible( ! column.visible() );
    		});</script>';
    }

  }
  else {

    my $tmpl = $Equipment->info_list(
      {
        COLS_NAME => 1,
        NAS_ID    => $FORM{NAS_ID} || $attr->{NAS_ID},
        SECTION   => '_SHOW'
      }
    );
    if ($Equipment->mac_log_list({ NAS_ID => $FORM{NAS_ID} || $attr->{NAS_ID} })) {
      push @$tmpl, ({ section => 'FDB' });
    }
    if ($Equipment->graph_list({ NAS_ID => $FORM{NAS_ID} || $attr->{NAS_ID} })) {
      push @$tmpl, ({ section => 'STATS' });
    }

    if ($tmpl) {

      my $buttons;
      foreach my $key (@$tmpl) {
        $buttons .= $html->li($html->button($key->{section}, "index=$index&visual=$key->{section}$pages_qs"), { class => (defined($FORM{visual}) && $FORM{visual} eq $key->{section}) ? 'active' : '' });
      }

      if ($buttons) {
        my $nas_select = $html->form_select(
          'NAS_ID',
          {
            SELECTED => $attr->{NAS_ID} || $FORM{NAS_ID},
            SEL_LIST => $Equipment->_list(
              {
                NAS_NAME  => '_SHOW',
                NAS_IP    => '_SHOW',
                COLS_NAME => 1,
                PAGE_ROWS => 10000
              }
            ),
            SEL_KEY        => 'nas_id',
            SEL_VALUE      => 'nas_ip,nas_name',
            NO_ID          => 1,
            MAIN_MENU      => get_function_index('equipment_info'),
            MAIN_MENU_ARGV => "NAS_ID=" . ($FORM{NAS_ID} || '')
          }
        );

        my $nas_select_form = $html->form_main(
          {
            CONTENT => $nas_select . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'submit' }),
            HIDDEN  => {
              'index'  => $index,
              'visual' => $FORM{visual} || 0,
            },
            NAME  => 'equipment_nas_panel',
            ID    => 'equipment_nas_panel',
            class => 'navbar-form navbar-right',
          }
        );

        my $buttons_list = $html->element('ul', $buttons, { class => 'nav navbar-nav' });

        print $html->element('div', $buttons_list . $nas_select_form, { class => 'navbar navbar-default' });
      }

    }
    else {
      $html->message('info', "No object for NAS: $FORM{NAS_ID}<span class='fa fa-cog fa-spin'> </span>", "Plz,  configure template");
    }

    my $visual = $FORM{visual} || 'INFO';
    if ($visual eq 'INFO') {
      equipment_snmp_data($FORM{NAS_ID});
    }
    elsif ($visual eq 'VLAN') {
      equipment_snmp_vlan_data($FORM{NAS_ID});
    }
    elsif ($visual eq 'PORTS') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PORTS' });
    }
    elsif ($visual eq 'FDB') {
      equipment_fdb_data($FORM{NAS_ID});
    }
    elsif ($visual eq 'STATS') {
      equipment_snmp_stats({ NAS_ID => $attr->{NAS_ID} || $FORM{NAS_ID} });
    }

    # Pon ports information
    elsif ($visual eq 'PON') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PON' });
    }

    # Pon ports setting
    elsif ($visual eq 'PON_OLT') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PON_OLT' });
    }

    # Pon ONU if setting
    elsif ($visual eq 'PON_IF') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PON_IF' });
    }

  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_user_data()

=cut

#**********************************************************
sub equipment_snmp_user_data {

  my $mac = $Dv->list({ COLS_NAME => 1, UID => $FORM{UID}, CID => '_SHOW' });

  if ($mac->[0]->{cid}) {
    my $ports = $Equipment->mac_log_list(
      {
        COLS_NAME => 1,
        NAS_ID    => $FORM{NAS_ID} || '_SHOW',
        MAC       => $mac->[0]->{cid},
        PORT      => $FORM{test} || '_SHOW'
      }
    );
    foreach my $port (@$ports) {
      equipment_panel_new({ UID => $FORM{UID}, NAS_ID => $port->{nas_id} });
      equipment_snmp_port_data({ UID => $FORM{UID}, NAS_ID => $port->{nas_id}, PORT => $port->{port} });
      equipment_snmp_stats({ UID => $FORM{UID}, NAS_ID => $port->{nas_id}, PORT => $port->{port} });
    }
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_data()

=cut

#**********************************************************
sub equipment_snmp_data {

  #my ($attr) = @_;
  #my @newarr;

  my $equipment = $Equipment->_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID}
    }
  );

  my $info = $Equipment->info_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      SECTION   => 'INFO',
      RESULT    => '_SHOW',
      INFOTIME  => '_SHOW'
    }
  );

  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $equipment->[0]->{id},
      SECTION   => 'INFO'
    }
  );

  if ($tmpl && $info) {
    my $tit  = JSON->new->utf8(0)->decode($tmpl->[0]->{parameters});
    my $vars = JSON->new->utf8(0)->decode($info->[0]->{result});

    my $table = $html->table(
      {
        caption     => "$lang{LAST_UPDATE}: $info->[0]->{info_time}",
        width       => '100%',
        title_plain => [ $lang{PARAMS}, $lang{VALUE} ],
        cols_align  => [ 'left', 'left' ],
        ID          => 'EQUIPMENT_TEST',
      }
    );

    my $edit = $html->button($lang{EDIT}, "index=$index&edit=1", { ICON => 'fa fa-pencil-square-o', });

    my $rows_count = 0;
    foreach my $key (@$tit) {
      $table->addrow($html->b($key->[1] || $key->[0]), $vars->{0}->[$rows_count], $edit);
      $rows_count++;
    }
    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 cable_test()

=cut
#**********************************************************
sub cable_test {
  my ($attr) = @_;
  my $mod = $Equipment->snmp_tpl_list(
    {
      COLS_NAME  => 1,
      MODEL_ID   => $attr->{MODEL_ID},
      SECTION    => 'CABLE',
      PARAMETERS => '_SHOW'
    }
  );

  my $oids = JSON->new->utf8(0)->decode($mod->[0]->{parameters});
  my @get = split(',', $oids->{get}->[1] || 0);
  my @pair_vals;
  my $snmp_community = "$conf{EQUIPMENT_SNMP_COMMUNITY_RW}\@$attr->{NAS_IP}";
  my @arr = ("OK", "open", "short", "open-short", "crosstalk", "unknown", "count", "no-cable", "other");

  my %colors = (
    0 => [ 'success', 'The pair or cable has no error.' ],
    1 => [ 'primary', 'The cable in the error pair does not have a connection at the specified position.' ],
    2 => [ 'warning', 'The cable in the error pair has a short problem at the specified position.' ],
    3 => [ 'warning', 'The cable in the error pair has a short problem at the specified position.' ],
    4 => [ 'danger',  'The cable in the error pair has a crosstalk problem at the specified position.' ],
    5 => [ 'link',    'Unknown' ],
    6 => [ 'link',    'count' ],
    7 => [ 'link',    'The port does not have any cable connected to the remote partner.' ],
    8 => [ 'default', 'other' ]
  );

  my $test = snmpset($snmp_community, $oids->{set}->[0] . $attr->{PORT}, 'integer', '1');
  sleep(3);
  if ($test != 2) {
    my @arrn;
    foreach my $key (@get) {
      my $pr = ($key != 0) ? "$key.$attr->{PORT}" : $attr->{PORT};
      push @arrn, "$oids->{get}->[0]$pr";
    }
    @pair_vals = snmpget($snmp_community, @arrn);
  }
  my $block;
  my $status;
  if (@get > 1) {
    my $link_status = ($pair_vals[0] == 0) ? "default'> $lang{HANGUPED}" : "success'> $lang{ACTIV}";
    $status = "<span class='label label-large label-$link_status</span>";
    my @pair_butt;
    my $color = 'default';
    foreach my $key (1 .. 4) {
      $color = $colors{ $pair_vals[$key] }[0] || 'default';
      my $detail = $colors{ $pair_vals[$key] }[1] || 'oops';
      push @pair_butt, "<button type='button' data-toggle='tooltip' title='$detail' class='btn btn-$color'>$lang{PAIR} $key <span class='badge'>$pair_vals[$key+4]</span></button>";
    }
    $block = $html->element('list-group', "@pair_butt", { class => 'list-group-item list-group-item-success' });
  }
  else {
    $status = '_';
    $block = $html->element('list-group', "@pair_vals", { class => 'list-group-item list-group-item-success' });
  }

  return ($block, $status);
}

#**********************************************************

=head2 equipment_fdb_data()

=cut

#**********************************************************
sub equipment_fdb_data {

  #my ($attr) = @_;

  if ($FORM{del}) {
    $Equipment->mac_log_del({ ID => $FORM{del} });
    if (!$Equipment->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED} : $FORM{del}");
    }
    else {
      $html->message('err', "MAC", "$lang{NOT} $lang{DELETED}");
    }
  }

  my $fdb = $Equipment->mac_log_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      ID        => '_SHOW',
      MAC       => '_SHOW',
      VLAN      => '_SHOW',
      PORT      => '_SHOW',
      DATETIME  => '_SHOW',
      REM_TIME  => '_SHOW',
      SORT      => 'port'
    }
  );

  my $fdb_index = get_function_index('equipment_panel_new');
  my $table     = $html->table(
    {
      width => '100%',
      title => [ $lang{PORT}, 'MAC', 'VID', $lang{LOGIN}, $lang{DATE} . "-" . $lang{ENABLE}, $lang{DATE} . "-" . $lang{DISABLED} ],
      cols_align => [ 'left', 'left' ],
      ID         => 'EQUIPMENT_TEST',
    }
  );
  foreach my $key (@$fdb) {
    my $login = $Dv->list({ COLS_NAME => 1, LOGIN => '_SHOW', CID => $key->{mac} });
    $table->addrow(
      $key->{port},
      $key->{mac},
      $key->{vlan},
      $login ? $html->button($login->[0]->{login}, "index=15&UID=$login->[0]->{uid}") : 'Unknown',
      $key->{datetime},
      $key->{rem_time},
      $html->button(
        '',
        "index=$fdb_index&visual=FDB&NAS_ID=$FORM{NAS_ID}&del=$key->{id}",
        {
          ICON    => 'glyphicon glyphicon-trash text-danger',
          MESSAGE => "$lang{DEL} $key->{mac}"
        }
      )
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************

=head2 equipment_snmp_stats()

=cut

#**********************************************************
sub equipment_snmp_stats {
  my ($attr) = @_;

  my $params = $Equipment->graph_list(
    {
      COLS_NAME    => 1,
      NAS_ID       => $attr->{NAS_ID} || $FORM{NAS_ID},
      PORT         => $attr->{PORT} || $FORM{FILTER_PORT} || '_SHOW',
      PARAM        => '_SHOW',
      MEASURE_TYPE => '_SHOW'
    }
  );

  my $PERIODS_SEL = $html->form_select(
    'PERIODS_FIELD',
    {
      SELECTED  => $FORM{PERIODS_FIELD},
      SEL_LIST  => [ { name => 'Hourly', val => 1 }, { name => '6 Hourly', val => 6 }, { name => '12 Hourly', val => 12 }, { name => 'Daily', val => 24 }, { name => 'Week', val => 168 }, ],
      SEL_KEY   => 'val',
      SEL_VALUE => 'name',
      NO_ID     => 1
    }
  );

  my %ports;
  foreach my $vr (@$params) {
    push(@{ $ports{ $vr->{port} } }, $vr->{param});
  }

  my $FIELDS_SEL = $html->form_select(
    'FILTER_PORT',
    {
      SELECTED  => $FORM{FILTER_PORT},
      SEL_ARRAY => \@{ [ sort { $a <=> $b } keys %ports ] },
      NO_ID     => 1
    }
  );

  print $html->form_main(
    {
      CONTENT => "$lang{PERIOD}: " . $PERIODS_SEL . " $lang{PORT}: " . $FIELDS_SEL . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'SUBMIT' }),
      METHOD  => 'GET',
      class   => 'form-inline',
      HIDDEN  => {
        index  => "$index",
        visual => 'STATS',
        NAS_ID => $attr->{NAS_ID} || $FORM{NAS_ID},
      },
    }
  );

  require Equipment::Graph;
  my $stt = ($FORM{PERIODS_FIELD}) ? time() - $FORM{PERIODS_FIELD} * 3600 : '';
  foreach my $port (sort { $a <=> $b } keys %ports) {
    my $graph_hash = get_graph_data(
      {
        NAS_ID     => $FORM{NAS_ID},
        PORT       => $port,
        DS_NAMES   => $ports{$port},
        START_TIME => $stt,
        TYPE       => 'counter'
      }
    );

    my @data    = ();
    my @data1   = ();
    my @timearr = ();
    foreach my $val (@{ $graph_hash->{data} }) {
      push @timearr, strftime("%b %d %H:%M", localtime($val->[0]));
      $val->[1] = sprintf("%.2f", $val->[1] / (1024 * 1024) * 8) if ($val->[1]);
      push @data, $val->[1];
      $val->[2] = sprintf("%.2f", $val->[2] / (1024 * 1024) * 8) if ($val->[2]);
      push @data1, $val->[2];
    }

    my %graph = ();

    $graph{ $graph_hash->{meta}->{legend}->[0] } = \@data;
    $graph{ $graph_hash->{meta}->{legend}->[1] } = \@data1 if ($graph_hash->{meta}->{legend}->[1]);

    print $html->make_charts2(
      {
        TITLE         => "GRAPH FOR PORT " . $port,
        DIMENSION     => 'Mb/s',
        Y_TITLE       => "$lang{PORT} $port",
        GRAPH_ID      => $port,
        TRANSITION    => 1,
        X_TEXT        => \@timearr,
        DATA          => \%graph,
        OUTPUT2RETURN => 1
      }
    );
    _error_show($Equipment);
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_json_data()

=cut

#**********************************************************
sub equipment_snmp_json_data {

  #my ($attr) = @_;
  #my @newarr;

  my $equipment = $Equipment->_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
    }
  );

  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $equipment->[0]->{id},
      SECTION   => 'PORTS'
    }
  );

  my $tit = JSON->new->utf8(0)->decode($tmpl->[0]->{parameters});
  foreach my $key (0 .. @$tit) {

    #push @newarr, $key->[0];
    my $info = $Equipment->info_port(
      {
        COLS_NAME => 1,
        NAS_ID    => $FORM{NAS_ID},
        SECTION   => 'PORTS',
        NUM       => $key,
        NAME      => $tit->[$key]->[0],
        PORT      => 5
      }
    );

    print Dumper $info;
  }
  print Dumper $tit;

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
