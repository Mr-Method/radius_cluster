<form class='form-horizontal' action='$SELF_URL' METHOD='POST' role='form'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='chg'   value='$FORM{chg}'> 

<fieldset>
<legend>_{EXCHANGE_RATE}_</legend>

<div class='form-group'>
    <label for='ER_NAME' class='control-label col-sm-6'>_{MONEY}_</label>
    <div class='col-sm-2'>
      <input class='form-control' id='ER_NAME' placeholder='ER_NAME' name='ER_NAME' value='%ER_NAME%'>
    </div>
</div>

<div class='form-group'>
    <label for='ER_SHORT_NAME' class='control-label col-sm-6'>_{SHORT_NAME}_</label>
    <div class='col-sm-2'>
      <input class='form-control' id='ER_SHORT_NAME' placeholder='ER_SHORT_NAME' name='ER_SHORT_NAME' value='%ER_SHORT_NAME%'>
    </div>
</div>

<div class='form-group'>
    <label for='ISO' class='control-label col-sm-6'>ISO</label>
    <div class='col-sm-2'>
      <input class='form-control' id='ISO' placeholder='ISO' name='ISO' value='%ISO%'>
    </div>
  </div>

<div class='form-group'>
    <label for='ER_RATE' class='control-label col-sm-6'>_{EXCHANGE_RATE}_</label>
    <div class='col-sm-2'>
      <input class='form-control' id='ER_RATE' placeholder='ER_RATE' name='ER_RATE' value='%ER_RATE%'>
    </div>
  </div>

<div class='form-group'>
    <label for='ISO' class='control-label col-sm-6'>_{CHANGED}_</label>
    <div class='col-sm-2'>
      <label for='ISO' class='col-sm-3 control-label'>%CHANGED%</label>
    </div>
  </div>

  <div class='form-group'>
    <div class='col-sm-offset-2 col-sm-8'>
      <input type='submit' class='btn btn-default' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</fieldset>

<!-- 
<table class=form>
<tr><th colspan=2 class=form_title>_{EXCHANGE_RATE}_</th></tr>
<tr><td>_{MONEY}_:</td><td><input type=text name=ER_NAME value='%ER_NAME%'></td></tr>
<tr><td>_{SHORT_NAME}_:</td><td><input type=text name=ER_SHORT_NAME value='%ER_SHORT_NAME%'></td></tr>
<tr><td>ISO:</td><td><input type=text name=ISO value='%ISO%'></td></tr>
<tr><td>_{EXCHANGE_RATE}_:</td><td><input type=text name=ER_RATE value='%ER_RATE%'></td></tr>
<tr><td>_{CHANGED}_:</td><td>%CHANGED%</td></tr>
<tr><th colspan=2 class=even><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>
-->

</form>
