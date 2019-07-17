<form action=$SELF_URL METHOD=POST >
<input type='hidden' name='index' value=$index>
  
<div class='box box-theme box-form form-horizontal'>
  
<div class='box-heading with-border text-primary'><h4 class='box-title'>_{FILTERS}_</h4></div>

<div class='box-body'>
  <div class='form-group' data-visible='%STATUS_VISIBILITY%'>
    <label class='control-label col-md-3'>_{STATUS}_</label>
    <div class='col-md-9'>
      %STATUS_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{ADMIN}_</label>
    <div class='col-md-9'>
      %ADMINS_SELECT%
    </div>
  </div>
    <div class='form-group'>
    <label class='control-label col-md-3 '>_{DATE}_ _{BEGIN}_</label>
    <div class='col-md-9'>
      <input type='text' name='DATE_START'  value='%DATE_START%' placeholder='%TIME_START%' class='form-control datepicker' >
   </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-3 '>_{DATE}_ _{END}_</label>
    <div class='col-md-9'>
      <input type='text' name='DATE_END'  value='%DATE_END%' placeholder='%TIME_END%' class='form-control datepicker' >
   </div>
  </div>
</div>

<div class='box-footer'>
  <button type='submit' class='btn btn-primary'>_{FILTER}_</button>
  <a href='$SELF_URL?index=$index&refresh=1'  type='button' class='btn btn-success' data-tooltip='_{FILLING_DATA}_' data-visible='%REFRESH_VISIBILITY%'>
    <span class='glyphicon glyphicon-refresh' aria-hidden='true'></span>
  </a>
</div>
</div>
</form>

%CHART%