<form name='CRM_PROGRESSBAR_STEP_ADD' id='form_CRM_PROGRESSBAR_STEP_ADD' method='post' class='form form-horizontal'>

  <input type='hidden' name='index' value='$index' />
  <input type='hidden' name='ID' value='%ID%' />

<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{STEP}_</h4></div>
  <div class='box-body'>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{NUMBER}_</label>
      <div class='col-md-9'>
        <input type='number' class='form-control' name='STEP_NUMBER' VALUE='%STEP_NUMBER%'>
      </div>
    </div>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{NAME}_</label>
      <div class='col-md-9'>
        <input type='text' class='form-control' name='NAME' VALUE='%NAME%'>
      </div>
    </div>
    <div class='form-group'>
      <label class='control-label col-md-3' for='COLOR'>_{COLOR}_:</label>
      <div class='col-md-9'>
        <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%' />
      </div>
    </div>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{DESCRIBE}_</label>
      <div class='col-md-9'>
        <textarea name='DESCRIPTION' class='form-control'>%DESCRIPTION%</textarea>
      </div>
    </div>
  </div>
  <div class='box-footer'>
    <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
  </div>
</div>  

</form>