<form ction=$SELF_URL METHOD=POST>
<input type='hidden' name='index' value='$index'>
  <div class='box box-theme box-form form-horizontal'>
  <div class='box-header with-border'><h4 class='box-title'>_{SERVICE}_</h4></div>
  <div class='box-body'>
    <div class='form-group'>
    <label class='control-label col-md-3'>_{LIGHT}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='LIGHT' value='%LIGHT%'> _{FOR}_ > 0 и < 100 _{KWT}_
    </div>
    </div>

    <div class='form-group'>
    <label class='control-label col-md-3'>_{LIGHT}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='LIGHT' value='%LIGHT%'> _{FOR}_ >100 _{KWT}_
    </div>
    </div>

    <div class='form-group'>
    <label class='control-label col-md-3'>_{GAS}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='GAS' value='%GAS%'> _{FOR}_ 1 _{M3}_
    </div>
    </div>

    <div class='form-group'>
    <label class='control-label col-md-3'>_{WATER}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='WATER' value='%WATER%'> _{FOR}_ 1 _{M3}_
    </div>
    </div>
  </div>
  <div class='box-footer'>
    <input  type='submit' class='btn btn-primary' value='%BTN_NAME%'>
  </div>
  </div>
</form>