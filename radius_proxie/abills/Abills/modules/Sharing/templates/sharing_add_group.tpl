<form method='POST'>

<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='%ID%'>

<div class='box box-theme box-form form-horizontal'>

<div class='box-header with-border'>_{ADD}_ _{GROUP}_</div>

<div class='box-body'>
  <div class='form-group'>
  <label class='col-md-3 control-label'>_{NAME}_</label>
    <div class='col-md-9'>
      <input type='text' name='NAME' value='%NAME%' class='form-control'>
    </div>
  </div>
  <div class='form-group'>
  <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='COMMENT'>%COMMENT%</textarea>
    </div>
  </div>
</div>

<div class='box-footer'>
  <input type='submit' name='%BTN_NAME%' value='%BTN_VALUE%' class='btn btn-primary'>
</div>

</div>

</form>