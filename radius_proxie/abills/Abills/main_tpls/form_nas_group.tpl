<form class='form-horizontal'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='$FORM{chg}'/>

<legend>_{NAS}_ - _{GROUPS}_</legend>

<div class='form-group'>
  <label class='col-md-4 control-label' for='NAME'>_{NAME}_</label>
  <div class='col-md-4'>
  <input id='NAME' value='%NAME%' name='NAME' placeholder='%NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='col-md-4 control-label' for='DISABLE'>_{DISABLE}_</label>
  <div class='col-md-4'>
  <input id='DISABLE' value='1' name='DISABLE' class='form-control' type='checkbox' %DISABLE%>
  </div>
</div>

<div class='form-group'>
  <label class='col-md-4 control-label' for='COMMENTS'>_{COMMENTS}_</label>
  <div class='col-md-4'>                     
    <textarea class='form-control' id='COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
  </div>
</div>

<div class='form-group'>
  <div class='col-sm-offset-2 col-sm-8'>
    <input type='submit' class='btn btn-default' name='%ACTION%' value='%LNG_ACTION%'>
  </div>
</div>

</fieldset>

</form>
