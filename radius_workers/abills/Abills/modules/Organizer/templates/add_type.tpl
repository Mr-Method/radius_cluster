<form ction=$SELF_URL METHOD=POST>
<input type='hidden' name='index' value='$index'>
  <div class='box box-theme box-form form-horizontal'>
  <div class='box-header with-border'><h4 class='box-title'>_{TYPE}_</h4></div>
  <div class='box-body'>
    <div class='form-group'>
      <label class='col-md-3 control-label'>_{NAME}_</label>
      <div class='col-md-9'>
      <input type='text' class='form-control' name='TYPE' value='%TYPE%'>
      </div>
    </div>
    <div class='radio'>
    <label>
      <input type='radio' name='DATA_TYPE' id='optionsRadios1' value='1' required='required' %COUNTER%> Показетель счетчика
    </label>
    <label>
      <input type='radio' name='DATA_TYPE' id='optionsRadios2' value='2' %MONEY%> Деньги
    </label>
  </div>
  </div>
  <div class='box-footer text-center'>
    <input  type='submit' class='btn btn-primary' value='%BTN_NAME%'>
  </div>
  </div>
</form>