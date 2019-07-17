<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='action' value='%ACTION%'>
<input type='hidden' name='ID' value='%ID%'>
<input type='hidden' name='sid' value='$sid'>

  <div class='box box-primary form-horizontal'>
  <div class='box-header with-border'><h4 class='box-title'>_{PUBLIC_UTILITIES}_</h4></div>
  <div class='box-body'>
    <div class='form-group'>
      <label class='col-md-3 control-label required'>_{DATE}_</label>
      <div class='col-md-9'>
        <input type='text' name='DATE' VALUE='%DATE%' class='form-control datepicker' required='required'>
      </div>
    </div>
    <hr>
    <div class='form-group'>
      <label class='col-md-3 control-label required'>_{LIGHT}_, _{KWT}_</label>
      <div class='col-md-9'>
        <input type='text' class='form-control' name='LIGHT' value='%LIGHT%' required='required' placeholder='_{INPUT_COUNTER}_'>
      </div>
    </div>
    <div class='form-group'>
      <label class='col-md-3 control-label required'>_{GAS}_, _{M3}_</label>
      <div class='col-md-9'>
      <input type='text' class='form-control' name='GAS' value='%GAS%' required='required' placeholder='_{INPUT_COUNTER}_'>
      </div>
    </div>
    <div class='form-group'>
      <label class='col-md-3 control-label required'>_{WATER}_, _{M3}_</label>
      <div class='col-md-9'>
      <input type='text' class='form-control' name='WATER' value='%WATER%' required='required' placeholder='_{INPUT_COUNTER}_'>
      </div>
    </div>
    <div class='form-group'>
      <div class='checkbox col-md-12 text-center'>
      <label class='control-element'>
        <input type='checkbox' name='CALC_COST'>_{CALC_COST}_
      </label>
      </div>`
    </div>
    <div class='form-group'>
      <label class='col-md-3 control-label required'>_{COMMUNAL}_, _{GRN}_</label>
      <div class='col-md-9'>
      <input type='text' class='form-control' name='COMMUNAL' value='%COMMUNAL%' required='required' placeholder='_{INPUT_MONEY}_'>
      </div>
    </div>
    <hr>
    <div class='form-group'>
      <label class='col-md-3 control-label'>_{COMMENTS}_</label>
      <div class='col-md-9'>
      <textarea class='form-control' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
      </div>
    </div>
  </div>
  <div class='box-footer'>
    <input  type='submit' class='btn btn-primary' value='%BTN_NAME%'>
  </div>
  </div>

</form>
