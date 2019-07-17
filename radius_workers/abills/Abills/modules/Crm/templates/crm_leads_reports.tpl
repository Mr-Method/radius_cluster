<form action='$SELF_URL' METHOD=POST>

<input type='hidden' name='index' value='$index'>

<div class='box box-form box-primary form-horizontal'>
  
<div class='box-header with-border'>_{FILTER}_</div>

<div class='box-body'>
  <div class='form-group'>
  <label class='col-md-3 control-label'>_{DATE}_ </label>
  <div class='col-md-9'>
  %DATE_RANGE%
  </div>
  </div>

  <div class='form-group' style='display: %HIDE_SOURCE_SELECT%'>
  <label class='col-md-3 control-label'>_{SOURCE}_</label>
  <div class='col-md-9'>
  %SOURCE_SELECT%
  </div>
  </div>
</div>

<div class='box-footer'>
  <input type='submit' class='btn btn-primary' value='_{FILTER_LEADS}_' name='filter'>
</div>

</div>

</form>