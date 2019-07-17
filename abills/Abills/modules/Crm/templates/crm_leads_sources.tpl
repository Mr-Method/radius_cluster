<form name='CRM_LEADS_SOURCES' id='form_CRM_LEADS_SOURCES' method='post' class='form form-horizontal'>

  <input type='hidden' name='index' value='$index' />
  <input type='hidden' name='ID' value='%ID%' />

<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{SOURCE}_</h4></div>
  <div class='box-body'>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{NAME}_</label>
      <div class='col-md-9'>
        <input type='text' class='form-control' name='NAME' VALUE='%NAME%'>
      </div>
    </div>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{COMMENTS}_</label>
      <div class='col-md-9'>
        <textarea name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
      </div>
    </div>
  </div>
  <div class='box-footer'>
    <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
  </div>
</div>  

</form>