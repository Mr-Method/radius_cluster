=head1 NAME

  INternet base functions

=cut

use strict;
use warnings FATAL => 'all';
use Tariffs;

our(
  $db,
  $admin,
  %conf,
  $html,
  %lang,
);


#**********************************************************
=head sel_tp($tp_id)

  Arguments:
    MODULE
    TP_ID    - SHow tp name for tp_id
    SELECT   - Select element
    SKIP_TP  - Skip show tp
    SHOW_ALL - Show all tps
    SEL_OPTIONS - Extra sel options (items)
    EX_PARAMS   - Extra sell options

  Returns:
    \%tp_hash (tp_id => name)

=cut
#**********************************************************
sub sel_tp {
  my ($attr) = @_;

  my $Tariffs = Tariffs->new($db, \%conf, $admin);
  my %params = ( MODULE => 'Dv;Internet' );
  if ($attr->{MODULE}) {
    $params{MODULE} = $attr->{MODULE};
  }

  if($attr->{TP_ID}) {
    if($attr->{TP_ID} =~ /:(\d+)/) {
      $attr->{TP_ID} = $1;
    }

    if(! $attr->{SHOW_ALL}) {
      $params{INNER_TP_ID} = $attr->{TP_ID};
    }
  }

  my $list = $Tariffs->list({
    NEW_MODEL_TP => 1,
    DOMAIN_ID    => $users->{DOMAIN_ID},
    COLS_NAME    => 1,
    %params
  });

  if($attr->{TP_ID} && ! $attr->{EX_PARAMS}) {
    if($Tariffs->{TOTAL}) {
      return "$list->[0]->{id} : $list->[0]->{name}";
    }

    return $attr->{TP_ID};
  }

  my %tp_list = ();

  foreach my $line (@$list) {
    if($attr->{SKIP_TP} && $attr->{SKIP_TP} == $line->{tp_id}) {
      next;
    }
    $tp_list{$line->{tp_id}} = $line->{id} .' : '. $line->{name};
  }

  if($attr->{SELECT}) {
    my %EX_PARAMS = ();

    my $element_name = $attr->{SELECT};
    my %extra_options = ('' => '--');
    if($attr->{SEL_OPTIONS}) {
      %extra_options = %{ $attr->{SEL_OPTIONS} };
    }

    if($attr->{EX_PARAMS}) {
      %EX_PARAMS = ( EX_PARAMS => $attr->{EX_PARAMS} );
    }

    return $html->form_select(
      $element_name,
      {
        SELECTED    => $attr->{$element_name} || $FORM{$element_name},
        SEL_HASH    => \%tp_list,
        SEL_OPTIONS => \%extra_options,
        NO_ID       => 1,
        %EX_PARAMS
      }
    );
  }

  return \%tp_list;
}

#**********************************************************
=head get_services($user_info)

  Arguments:
    $user_info

  Returns:
    \%services
       list
         SERVICE_NAME
         SERVICE_DESC
         SUM
       total_sum

=cut
#**********************************************************
sub get_services {
  my ($user_info) = @_;

  my $result;

  my $cross_modules_return = cross_modules_call('_docs', {
    UID          => $user_info->{UID},
    REDUCTION    => $user_info->{REDUCTION},
    #PAYMENT_TYPE => 0
  });

  foreach my $module (sort keys %$cross_modules_return) {
    if (ref $cross_modules_return->{$module} eq 'ARRAY') {
      next if ($#{$cross_modules_return->{$module}} == -1);
      foreach my $module_return (@{$cross_modules_return->{$module}}) {
        my ($service_name, $service_desc, $sum) = split(/\|/, $module_return);
        #$table->addrow($line->{LOGIN}, $serv_name, $serv_desc, $sum);
        push @{ $result->{list} }, {
          MODULE       => $module,
          SERVICE_NAME => $service_name,
          SERVICE_DESC => $service_desc,
          SUM          => $sum
        };
        $result->{total_sum} += $sum;
      }
    }
  }

  return $result;
}

1;