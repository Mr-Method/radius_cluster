<form action='$SELF_URL' METHOD=POST>

<input type='hidden' name='index' value='$index'>

<div class='box box-theme box-form form-horizontal'>
<div class='box-body'>

<div class='form-group'>
  <label class='col-md-3 control-label'>_{ADMIN}_</label>
  <div class='col-md-9'>
  %ADMIN_SELECT%
  </div>
</div>
<div class='form-group'>
  <label class='col-md-3 control-label'>_{DATE}_</label>
  <div class='col-md-9'>
  %DATE_RANGE%
  </div>
</div>

</div>
<div class='box-footer'>
<input type='submit' name='FILTER' value='_{SEARCH}_' class='btn btn-primary'>
</div>
</div>

</form>