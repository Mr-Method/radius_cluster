<FORM action='$SELF_URL' METHOD='POST'  class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>
<fieldset>

<div class='box box-theme box-form'>
<legend>_{BOXES}_</legend>

<div class='box-body'>

<div class='form-group'>
  <label class='control-label col-md-3' for='SERIAL'>_{SERIAL}_</label>
  <div class='col-md-9'>
    <input type=text class='form-control' id='SERIAL' placeholder='%SERIAL%' name='SERIAL' value='%SERIAL%'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='TYPE'>_{TYPE}_:</label>
  <div class='col-md-9'>
    %TYPE_SEL%
  </div>
</div>

</div>

<div class='box-footer'>
	<input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>

</div>
</fieldset>
</FORM>

