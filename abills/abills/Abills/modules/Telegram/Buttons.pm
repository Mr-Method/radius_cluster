=head1 NAME

  Telegram button

=cut

use strict;
use warnings FATAL => 'all';

our (
  $base_dir,
  $db,
  %conf,
  $admin
);



#**********************************************************
=head2 buttons_list()
  
=cut
#**********************************************************
sub buttons_list {
  my ($attr) = @_;
  my @buttons_files = glob "$base_dir/Abills/modules/Telegram/buttons-enabled/*.pm";
  my %BUTTONS = ();
  foreach my $file (@buttons_files) {
    my (undef, $button) = $file =~ m/(.*)\/(.*)\.pm/;
    if (eval { require "buttons-enabled/$button.pm"; 1; }) {
      my $obj = $button->new($db, $admin, \%conf, $attr->{bot});
      if ($obj->can('btn_name')) {
        $BUTTONS{$button} = $obj->btn_name();
      }
    }
  }

  return \%BUTTONS;
}

#**********************************************************
=head2 _task_plugin_call($attr)
  button - button pm file
  fn     - button function
  
=cut
#**********************************************************
sub telegram_button_fn {
  my ($attr) = @_;
  my $ret = '';
  if (eval { require "buttons-enabled/$attr->{button}.pm"; 1; }) {
    my $obj = $attr->{button}->new($db, $admin, \%conf, $attr->{bot});
    my $fn = $attr->{fn};
    if ($obj->can($fn)) {
      $ret = $obj->$fn($attr);
    }
  }
  return $ret;
}

1;