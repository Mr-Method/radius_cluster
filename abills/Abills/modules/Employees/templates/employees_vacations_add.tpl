<form action='$SELF_URL' METHOD=POST class='form form-horizontal'>

<input type='hidden' name='index' value=$index>

<div class='box box-form box-primary'>
  
<div class='box-header with-border'><h4>_{VACATIONS}_</h4></div>

<div class='box-body'>
  <div class='form-group'>
  <label class='control-label col-md-3'>_{EMPLOYEE}_</label>
  <div class='col-md-9'>
    %ADMIN_SELECT%
  </div>
  </div>
  <div class='form-group'>
  <label class='control-label col-md-3'>_{DATE}_ _{START}_</label>
  <div class='col-md-9'>
    <input type='text' name='DATE_START' value='%DATE_START%' class='form-control datepicker'>
  </div>
  </div>
  <div class='form-group'>
  <label class='control-label col-md-3'>_{DATE}_ _{END}_</label>
  <div class='col-md-9'>
    <input type='text' name='DATE_END' value='%DATE_END%' class='form-control datepicker'>
  </div>
  </div>
</div>

<div class='box-footer'>
  <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
</div>

</div>

</form>