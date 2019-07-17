package ChangeResponsible;

use strict;
use warnings FATAL => 'all';
# use parent 'Tasks::db::Tasks';

my $html;
my $lang;

#**********************************************************
=head2 new($Tasks, $html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $Tasks = shift;
  $html = shift;
  $lang = shift;
  
  my $self = {
    Tasks => $Tasks
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return "Разрешает ответственному передать задачу другому администратору.";
}

#**********************************************************
=head2 html_for_task_show
  return button for MyTasks->showTask window
=cut
#**********************************************************
sub html_for_task_show {
  my $self = shift;
  my ($attr) = @_;
  my $button = $html->button(
    $lang->{CHANGE_RESPONSIBLE},
    "index=$main::index&plugin=ChangeResponsible&fn=change_responsible&ID=$attr->{ID}&" . ($attr->{qs} || "" ),
    { class => 'btn btn-default btn-block' });
  return $button;
}


#**********************************************************
=head2 change_responsible

=cut
#**********************************************************
sub change_responsible {
  my $self = shift;
  my ($attr) = @_;
  if ($attr->{chg}) {
    $self->{Tasks}->chg($attr);
    $html->redirect("?index=$attr->{index}");
    return 'stop';
  }

  my $task_info = $self->{Tasks}->info({ ID => $attr->{ID} });

  my $submit_button = $html->form_input('chg', $lang->{CHANGE}, { TYPE => 'submit', OUTPUT2RETURN => 1} );
  my $responsible_select = $html->element(
    'div',
    $html->element('div', main::_responsible_select({SELECTED => $task_info->{RESPONSIBLE}}), {class => 'col-md-12'}),
    {class => 'form-group'}
  );
  # my $allow_change_responsible = $html->form_input('allow_change_responsible', 1,  { TYPE => 'checkbox', STATE => 1, OUTPUT2RETURN => 1} );
  my $hidden_inputs = $html->form_input('index',  $attr->{index},  { TYPE => 'hidden', OUTPUT2RETURN => 1} );
  $hidden_inputs   .= $html->form_input('plugin', $attr->{plugin}, { TYPE => 'hidden', OUTPUT2RETURN => 1} );
  $hidden_inputs   .= $html->form_input('fn',     $attr->{fn},     { TYPE => 'hidden', OUTPUT2RETURN => 1} );
  $hidden_inputs   .= $html->form_input('ID',     $attr->{ID},     { TYPE => 'hidden', OUTPUT2RETURN => 1} );

  my $output = $html->tpl_show('', { 
      BOX_TITLE     => $lang->{CHANGE_RESPONSIBLE},
      HIDDEN_INPUTS => $hidden_inputs,
      BOX_BODY      => "$responsible_select",
      BOX_FOOTER    => $submit_button,
    },
    { TPL => 'box', MODULE => 'Tasks' });

  return $output;
}
1;

__DATA__
<form class='form-horizontal' id='task_box_form'>
<input type="hidden" name="index" value="%index%" id="index">
<input type="hidden" name="plugin" value="%plugin%" id="plugin">
<input type="hidden" name="fn" value="%fn%" id="fn">
<input type="hidden" name="ID" value="%ID%" id="ID">
  <div class='box box-theme box-form'>
    <div class='box-header with-border'>
      <h3 class='box-title'>_{CHANGE_RESPONSIBLE}_</h3>
      <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
        <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='box-body' id='task_box_body'>
      <div class="form-group">
        <div class="col-md-12">
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type="submit" name="chg" value="_{CHANGE}_" class="btn btn-primary" id="chg">
    </div>
  </div>
</form>