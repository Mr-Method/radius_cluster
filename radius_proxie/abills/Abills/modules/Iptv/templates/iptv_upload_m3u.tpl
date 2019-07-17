<form name='UPLOAD_M3U' id='form_UPLOAD_M3U' method='post' class='form form-horizontal' enctype=multipart/form-data>

    <input type='hidden' name='index' value='$index' />


<div class='box box-theme box-form'>
<div class='box-header with-border text-center'> <h4>%PANEL_HEADING% m3u</h4> </div>
<div class='box-body'>

  <div class='form-group'>
    <label class='col-md-3 control-label'> _{OPTIONS}_ </label>
    <div class='col-md-9'> %VARIANTS% </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'> _{FILE}_ </label>
    <div class='col-md-9'> <input type='file' name='FILE' class='form-control'> </div>
  </div>


</div>
<div class='box-footer text-center'>
  <button type='submit' class='btn btn-primary'>%SUBMIT_BTN_NAME%</button>
</div>
</div>

</form>