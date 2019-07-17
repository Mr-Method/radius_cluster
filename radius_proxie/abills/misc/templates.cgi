#!/usr/bin/perl
package Abills::Misc::Templates_generator;

use strict;
use feature 'state';

our ($begin_time, %conf);
use lib "../lib/";
use lib "../Abills/mysql/";

my $VERSION = 1.03;

use POSIX qw(strftime);
use Abills::HTML;
use Abills::Base;
use Abills::Misc;
use Time::HiRes qw/gettimeofday tv_interval/;
$begin_time = [ gettimeofday() ];

# Used to show error line
my $line_counter = 1;

# Parses %FORM
my $html = Abills::HTML->new(
  {
    CONF     => \%conf,
    NO_PRINT => 0,
    PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $conf{default_charset},
  }
);

print "Content-Type: text/html\n\n";

print << '[END]';
<!DOCTYPE HTML>
<HTML>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ABillS Form Generator</title>

  <!-- Bootstrap -->
  <link href="/styles/default_adm/css/bootstrap.min.css" rel="stylesheet">
  <link href="/styles/default_adm/css/style.css" rel="stylesheet">
  <style>
    .panel-form {
      max-width: 500px;

      margin-left: auto;
      margin-right: auto;
    }
  </style>

  <!-- jQuery -->
  <script src="/styles/default_adm/js/jquery.min.js"></script>
  <script src="/styles/default_adm/js/templates.js"></script>

</head>
<body>
<div class="modal fade" tabindex="-1" role="dialog" id="addNewFieldModal">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span
            aria-hidden="true">&times;</span></button>
        <h4 class="modal-title">Add new field</h4>
      </div>
      <div class="modal-body form form-horizontal" id="addNewFieldModalBody">

        <div class="form-group">
          <label for="TYPE" class="control-label col-md-3">Type</label>
          <div class="col-md-9">
            <select id="TYPE" name="TYPE" class="form-control">
              <option value="text">Text</option>
              <option value="hidden">Hidden</option>
              <option value="textarea">Textarea</option>
              <option value="checkbox">Checkbox</option>
              <option value="select">Select</option>
              <option value="collapse">Collapse start</option>
              <option value="collapse_">Collapse end</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="NAME" class="control-label col-md-3">Field name (uppercase)</label>
          <div class="col-md-9">
            <input type="text" class="form-control" id="NAME" name="NAME" value=""/>
          </div>
        </div>


        <div class="form-group">
          <label for="LABEL" class="control-label col-md-3">Lang name</label>
          <div class="col-md-9">
            <input type="text" class="form-control" id="LABEL" name="LABEL" value="_{...}_"/>
          </div>
        </div>

        <div class="form-group">
          <label for="PLACEHOLDER" class="control-label col-md-3">Placeholder</label>
          <div class="col-md-9">
            <input type="text" class="form-control" id="PLACEHOLDER" name="PLACEHOLDER" value=""/>
          </div>
        </div>

        <div class="checkbox text-center">
          <label for="REQUIRED">
            <input type="checkbox" id="REQUIRED" name="REQUIRED">
            <strong>Required</strong>
          </label>
        </div>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary" id="addButton">Add field</button>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
<div class='container'>
  <div class='row'>
    <div class='well'>
      <h3>Usage</h3>
      <p class='text-muted'>
        <b>Text input:</b> text:$label:$name:$placeholder:$required
        <br/>
        <b>Hidden input:</b> hidden:$name
        <br/>
        <b>Textarea:</b> textarea:$label:$name:$placeholder:$required
        <br/>
        <b>Checkbox: </b> checkbox:$label:$name:$checked:$required
        <br/>
        <b>Select: </b> select:$label:$name:$required
        <br/>
        <b>Start collapsing panel: </b> collapse:$label:$name
        <br/>
        <b>End collapsing panel: </b> collapse_end:
      </p>
      <div class='row'>
        <div class='col-md-6'>
          <div class='alert alert-info'>
            Pass empty (::) as false or skipped value
          </div>
        </div>
        <div class='col-md-6'>
          <div class='alert alert-warning'>
            <strong>Warning!</strong>
            $label and $name are required
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <button class="btn btn-success" id="addNewFieldButton">
        <span class="glyphicon glyphicon-plus"></span>
      </button>
    </div>
  </div>
[END]

ask_form();

if ( $FORM{GENERATE} ) {
  my $result = generate_form(\%FORM);
  
  print "<hr />" . '<h1>Preview</h1>' . $result . "<hr />" . '<div class="row"><div class="col-md-3"><h2>Code</h2></div>' . '<div class="col-md-9"><button class="btn btn-primary btn-lg js-textareacopybtn"><span class="glyphicon glyphicon-export"></span>Copy</button></div></div>';
  $result =~ s/textarea/ttextarea/g;
  print "<textarea class='form-control js-copytextarea' rows='" . num_of_lines($result) . "'>$result</textarea><br />";
}

if ( $begin_time != 0 ) {
  my $gen_time = tv_interval($begin_time, [ gettimeofday() ]);
  print "<hr><div class='row' id='footer'> Version: $VERSION (GT: " . sprintf("%.6f", $gen_time) . ")</div>";
}

print << '[FOOTER]';
  </div>
  <script src="/styles/default_adm/js/bootstrap.min.js"></script>
</body>
</html>
[FOOTER]

#**********************************************************

=head2 ask_form()

=cut

#**********************************************************
sub ask_form {
  
  my $in_panel = (defined $FORM{IN_PANEL} && $FORM{IN_PANEL} eq 'on') ? 'checked' : '';
  
  print << "[FORM]";
    <div class='row'>
    <div class='col-md-6 col-md-offset-3'>
      <form method='post' class='form form-horizontal'>
        <div class='panel panel-primary'>

          <div class='panel-heading text-center'><h4>Input</h4></div>
          <div class='panel-body'>

              <div class='form-group'>
                <label class='control-label col-md-3'>Form name</label>
                <div class='col-md-9'>
                  <input name='FORM_NAME' class='form-control' value='$FORM{FORM_NAME}'>
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3'>Input params</label>
                <div class='col-md-9'>
                  <textarea  name='FORM' id='INPUT' class='form-control' rows='12'>$FORM{FORM}</textarea>
                </div>
              </div>

              <div class='checkbox text-center'>
                <label>
                  <input type='checkbox' name='IN_PANEL' $in_panel>
                  <strong>In panel?</strong>
                </label>
              </div>

          </div>
          <div class='panel-footer text-center'>
            <input class='btn btn-primary' type='submit' name='GENERATE' value='Generate'>
          </div>

        </div>
      </form>
    </div>
    </div>

[FORM]
}

#**********************************************************

=head2 generate_form()

=cut

#**********************************************************
sub generate_form {
  my ($attr) = @_;
  
  my $in_panel = (defined $FORM{IN_PANEL} && $FORM{IN_PANEL} eq 'on');
  my $form_name = (defined $FORM{FORM_NAME} && !($FORM{FORM_NAME} eq '')) ? $FORM{FORM_NAME} : '%FORM_NAME%';
  
  my $input = $attr->{FORM};
  
  my @list = split('\n', $input);
  
  my $form = '';
  
  $form .= "    <form name='$form_name' id='form_$form_name' method='post' class='form form-horizontal'>\n";
  $form .= q{        <input type='hidden' name='index' value='$index' />} . "\n";
  $form .= q{        <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1' />} . "\n";
  
  for my $param ( @list ) {
    $form .= parse_element_row($param);
  }
  
  $form .= "    </form>\n";
  
  my $result;
  
  if ( $in_panel ) {
    $result = "
<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>%PANEL_HEADING%</h4></div>
  <div class='box-body'>
    $form
  </div>
  <div class='box-footer text-center'>
      <input type='submit' form='form_$form_name' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>\n
            ";
    
  }
  else {
    $result = $form;
  }
  
  return $result;
}

#**********************************************************
=head2 parse_element_row($attr)

=cut
#**********************************************************
sub parse_element_row {
  my ($attr) = @_;
  
  my @element = split(':', trim($attr));
  
  my $type = shift(@element);
  
  my $result = 'Error';
  
  if ( $type eq 'text' ) {
    $result = form_text_input_row(@element);
  }
  elsif ( $type eq 'checkbox' ) {
    $result = form_checkbox_input_row(@element);
  }
  elsif ( $type eq 'textarea' ) {
    $result = form_textarea_input_row(@element);
  }
  elsif ( $type eq 'select' ) {
    $result = form_select_row(@element);
  }
  elsif ( $type eq 'hidden' ) {
    $result = form_hidden_row(@element);
  }
  elsif ( $type eq 'collapse' ) {
    $result = start_collapse_panel(@element);
  }
  elsif ( $type eq 'collapse_end' ) {
    $result = close_collapse_panel();
  }
  else {
    print( "<script>alert('ERROR :Unknown element: $type at line [$line_counter]')</script>" );
    exit(1);
  }
  
  $line_counter++;
  
  return $result;
}

#**********************************************************

=head2 form_text_input_row($label, $name, $placeholder, $required)

=cut

#**********************************************************
sub form_text_input_row {
  my ($label, $name, $placeholder, $required) = @_;
  
  my $id = '';
  my $attr_id = '';
  my $attr_name = '';
  my $prop_required = '';
  
  $placeholder = to_attr('placeholder', $placeholder);
  
  if ( $name ne '' ) {
    $attr_name = to_attr('name', $name);
    $id = $name . "_ID";
    $attr_id = to_attr('id', $id);
  }
  
  #    show($required);
  if ( $required eq '1' ) {
    $prop_required = ' required';
  }
  
  my $element = "
      <div class='form-group'>
        <label class='control-label col-md-3$prop_required' for='$id'>$label</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%$name%' $prop_required$attr_name$attr_id$placeholder />
        </div>
      </div>\n";
  
  return $element;
  
}

#**********************************************************

=head2 form_checkbox_input_row($label, $name, $required)

=cut

#**********************************************************
sub form_checkbox_input_row {
  my ($label, $name, $required) = @_;
  
  my $prop_required = '';
  my $attr_id = to_attr('id', $name . '_ID');
  
  if ( $required eq '1' ) {
    $prop_required = 'required="required"';
  }
  
  my $element = "
      <div class='checkbox text-center'>
        <label>
            <input type='checkbox' data-return='1' data-checked='%$name%' name='$name' $prop_required $attr_id />
            <strong>$label</strong>
        </label>
      </div>\n";
  
  return $element;
}

#**********************************************************

=head2 form_select_row($label, $name, $required)

=cut

#**********************************************************
sub form_select_row {
  my ($label, $name, $required) = @_;
  
  my $prop_required = '';
  if ( $required eq '1' ) {
    $prop_required = ' required';
  }
  
  my $element = "
      <div class='form-group'>
        <label class='control-label col-md-3$prop_required' for='$name'>$label</label>
        <div class='col-md-9'>
            %$name\_SELECT%
        </div>
      </div>\n";
  
  return $element;
}

#**********************************************************

=head2 form_hidden_row($name)

=cut

#**********************************************************
sub form_hidden_row {
  my ($name) = @_;
  
  return "<input type='hidden' name='$name' value='%$name%' />
  ";
}

#**********************************************************

=head2 form_textarea_input_row($label, $name, $required)

=cut

#**********************************************************
sub form_textarea_input_row {
  my ($label, $name, $required) = @_;
  
  my $attr_rows = to_attr('rows', 5);
  
  my $id = $name . '_ID';
  
  my $prop_required = '';
  if ( $required eq '1' ) {
    $prop_required = ' required';
  }
  
  my $element = "
      <div class='form-group'>
          <label class='control-label col-md-3$prop_required' for='$id'>$label</label>
          <div class='col-md-9'>
              <textarea class='form-control col-md-9' $attr_rows$prop_required name='$name' id='$id'>%$name%</textarea>
          </div>
      </div>\n";
  
  return $element;
  
}

#**********************************************************

=head2 start_collapse_panel($label, $name)

=cut

#**********************************************************
sub start_collapse_panel {
  my ($label, $name) = @_;
  
  $name = trim($name);
  my $collapse_id = $name . "_collapse";
  my $heading_id = $name . "_heading";
  
  my $element = "
    <div class='form-group'>
      <div class='box box-theme'>
          <div class='box-header with-border' role='tab' id='$heading_id'>
            <h4 class='box-title text-center'>
              <a role='button' data-toggle='collapse' href='#$collapse_id' aria-expanded='true' aria-controls='$collapse_id'>
                $label
              </a>
            </h4>
          </div>
        <div id='$collapse_id' class='box-collapse collapse' role='tabpanel' aria-labelledby='$heading_id'>
        <div class='box-body'>
        ";
  
  return $element;
}

#**********************************************************

=head2 close_collapse_panel()

=cut

#**********************************************************
sub close_collapse_panel {
  return "       </div> <!-- end of collapse panel-body -->
      </div> <!-- end of collapse div -->
      </div> <!-- end of collapse panel -->
    </div> <!-- end of collapse form-group -->
";
}

#**********************************************************

=head2 to_attr($name, $value)

=cut

#**********************************************************
sub to_attr {
  my ($name, $value) = trim(@_);
  
  if ( $value ne '' ) {
    return " $name='" . $value . "' ";
  }
  
  return '';
}

#**********************************************************

=head2 trim(@input)

=cut

#**********************************************************
sub trim {
  my @out = @_;
  for ( @out ) {
    s/^\s+//;
    s/\s+$//;
    s/\n$//;
  }
  return wantarray ? @out : $out[0];
}

#**********************************************************

=head2 num_of_lines($text)

=cut

#**********************************************************
sub num_of_lines {
  my ($text) = @_;
  return scalar split /\n/, $text;
}

1;
