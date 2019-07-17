<form action='$SELF_URL' method='post' class='form-horizontal'>
<div class='box box-theme box-form'>
<div class='box-header with-border'>Tags</div>
<div class='box-body'>
  <input type='hidden' name='index' value='$index' />
  <input type='hidden' name='ID' value='$FORM{chg}' /> 
<fieldset>
    <div class='form-group'>
      <label for='NAME' class='control-label col-md-3'>_{NAME}_:</label>
      <div class='col-md-9'>
        <input type='text' class='form-control' name='NAME' value='%NAME%' />
      </div>
    </div>

    <div class='form-group'>
      <label for='PRIORITY' class='control-label col-md-3'>_{PRIORITY}_:</label>
      <div class='col-md-9'>
        %PRIORITY_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label for='NAME' class='control-label col-md-3'>_{COMMENTS}_:</label>
      <div class='col-md-9'>
        <textarea rows=4 name=COMMENTS class='form-control'>%COMMENTS%</textarea>
      </div>
    </div>
</fieldset>

</div>
  <div class='box-footer'>
  <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary' />
  </div>
</div>
</form>