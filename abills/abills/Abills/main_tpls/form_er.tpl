<form class='form-horizontal' action='$SELF_URL' METHOD='POST' role='form'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='chg'   value='$FORM{chg}'> 

<fieldset>
    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4 class='box-title'>_{EXCHANGE_RATE}_</h4></div>
        <div class='box-body'>

<div class='form-group'>
    <label for='ER_NAME' class='control-label col-sm-4'>_{MONEY}_</label>
    <div class='col-sm-8'>
      <input class='form-control' id='ER_NAME' placeholder='ER_NAME' name='ER_NAME' value='%ER_NAME%'>
    </div>
</div>

<div class='form-group'>
    <label for='ER_SHORT_NAME' class='control-label col-sm-4'>_{SHORT_NAME}_</label>
    <div class='col-sm-8'>
      <input class='form-control' id='ER_SHORT_NAME' placeholder='ER_SHORT_NAME' name='ER_SHORT_NAME' value='%ER_SHORT_NAME%'>
    </div>
</div>

<div class='form-group'>
    <label for='ISO' class='control-label col-sm-4'>ISO</label>
    <div class='col-sm-8'>
      <input class='form-control' id='ISO' placeholder='ISO' name='ISO' value='%ISO%'>
    </div>
  </div>

<div class='form-group'>
    <label for='ER_RATE' class='control-label col-sm-4'>_{EXCHANGE_RATE}_</label>
    <div class='col-sm-8'>
      <input class='form-control' id='ER_RATE' placeholder='ER_RATE' name='ER_RATE' value='%ER_RATE%'>
    </div>
  </div>

<div class='form-group'>
    <label for='ISO' class='control-label col-sm-4'>_{CHANGED}_</label>
    <div class='col-sm-8'>
      <label for='ISO' class='col-sm-3 control-label'>%CHANGED%</label>
    </div>
  </div>
</div>

  <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
  </div>

    </div>

</fieldset>


</form>
