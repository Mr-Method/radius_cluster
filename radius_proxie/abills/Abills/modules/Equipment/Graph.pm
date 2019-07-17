#**********************************************************
=head1 NAME

  Equipment::Graph

=cut
#**********************************************************


use strict;
use warnings;
use Abills::Base qw(load_pmodule2);

our(
  $html,
  %lang,
  $var_dir
);

my $load_data = load_pmodule2('RRDTool::OO', { SHOW_RETURN => 1 });

#**********************************************************
=head2 add_graph($attr)
   Arguments:
     $attr
       NAS_ID  - Nas id
       PORT    - Port id
       TYPE    - Graph type: SPEED, SIGNAL, TEMPERATURE
       STEP    - Step: 60, 300 (default 300)
       DATA    - Data hash
=cut
#**********************************************************
sub add_graph {
  my ($attr) = @_;

  if ($load_data) {
    return 0;
  }

  my $rrd_dir = $var_dir . "db/rrd";

  if (!-d $var_dir . "db") {
    mkdir $var_dir . "db", 777;
    print "mkdir " . $var_dir . "db \n";
  }
  if (!-d $var_dir . "db/rrd") {
    mkdir $var_dir . "db/rrd", 777;
    print "mkdir " . $var_dir . "db/rrd \n";
  }

  my $archive = {
    60 => [
      archive => { rows => 3000, cpoints => 1, cfunc => 'AVERAGE' },
      archive => { rows => 700,  cpoints => 30, cfunc => 'AVERAGE' },
      archive => { rows => 775,  cpoints => 120, cfunc => 'AVERAGE' },
      archive => { rows => 797,  cpoints => 1440, cfunc => 'AVERAGE' },
      archive => { rows => 3000, cpoints => 1, cfunc => 'MAX' },
      archive => { rows => 700,  cpoints => 30, cfunc => 'MAX' },
      archive => { rows => 775,  cpoints => 120, cfunc => 'MAX' },
      archive => { rows => 797,  cpoints => 1440, cfunc => 'MAX' },
    ],
    300 => [
      archive => { rows => 600, cpoints => 1, cfunc => 'AVERAGE' },
      archive => { rows => 700, cpoints => 6, cfunc => 'AVERAGE' },
      archive => { rows => 775, cpoints => 24, cfunc => 'AVERAGE' },
      archive => { rows => 797, cpoints => 288, cfunc => 'AVERAGE' },
      archive => { rows => 600, cpoints => 1, cfunc => 'MAX' },
      archive => { rows => 700, cpoints => 6, cfunc => 'MAX' },
      archive => { rows => 775, cpoints => 24, cfunc => 'MAX' },
      archive => { rows => 797, cpoints => 288, cfunc => 'MAX' },
    ]
  };

  my $step = $attr->{STEP} || '300';
  my @datasource = ();
  my %values = ();
  my $rrdfile = $rrd_dir. "/" . $attr->{NAS_ID} . "_" . $attr->{PORT} . "_" . lc($attr->{TYPE}) . ".rrd";
  my $rrd = RRDTool::OO->new( file => $rrdfile );

  foreach my $line (@{$attr->{DATA}}) {
    push @datasource, ( data_source => { name => $line->{SOURCE} , type  => $line->{TYPE} } );
    $values{$line->{SOURCE}} =  $line->{DATA};
  }

  unless (-f $rrdfile) {
    $rrd->create(
      step => $step,
      @datasource,
      @{$archive->{$step}}
    );
  }

  $rrd->update( values => \%values );

  return 1;
}

#**********************************************************
=head2 get_graph_data($attr)

   Arguments:
     $attr
       NAS_ID   - Nas id
       PORT     - Port id
       TYPE     - Graph type: SPEED, SIGNAL, TEMPERATURE
       DS_NAMES - Array data source names

=cut
#**********************************************************
sub get_graph_data {
  my ($attr) = @_;

  if ($load_data) {
    print $load_data;
    return 0;
  }

  my $rrdfile = $var_dir."db/rrd/".$attr->{NAS_ID}."_".$attr->{PORT}."_".lc($attr->{TYPE}).".rrd";

  unless (-f $rrdfile) {
    $html->message( 'err', $lang{ERROR}, "Can't open file '$rrdfile' $!" );
    return 0;
  }

  my $rrd = RRDTool::OO->new( file => $rrdfile );
  my $ds_info = $rrd->info()->{ds};
  my @def = ();
  my @xport = ();

  foreach my $ds_name (@{ $attr->{DS_NAMES} }) {
    if ($ds_info->{$ds_name}) {
      push @def, {
          vname  => $ds_name."_vname",
          file   => $rrdfile,
          dsname => $ds_name,
          cfunc  => "MAX"
        };
      push @xport, {
          vname  => $ds_name."_vname",
          legend => $ds_name
        };
    }
  }

  my $start_time = $attr->{START_TIME} || time() - 24 * 3600;
  my $end_time = $attr->{END_TIME} || time();

  if (@def) {
    my $results = $rrd->xport(
      start => $start_time,
      end   => $end_time,
      def   => \@def,
      xport => \@xport
    );
    return $results;
  }

  return 0;
}


#**********************************************************
=head2 del_graph_data($attr)

   Arguments:
     $attr
       NAS_ID   - Nas id
       PORT     - Port id
       TYPE     - Graph type: SPEED, SIGNAL, TEMPERATURE

=cut
#**********************************************************
sub del_graph_data {
  my ($attr) = @_;
  my $rrdfile = $var_dir."db/rrd/".$attr->{NAS_ID}."_".$attr->{PORT}."_".lc($attr->{TYPE}).".rrd";
  
  unlink($rrdfile) or $html->message( 'err', $lang{ERROR}, "Can't delete file '$rrdfile' $!" );

  return 0;
}


1