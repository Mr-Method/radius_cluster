<form class='form-horizontal' action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data'>
<input type='hidden' name='index' value='$index'>

<div class='box box-theme box-form'>
<div class='box-body'>


<fieldset>
    <legend>_{IMPORT}_</legend>

<div class='form-group'>
    <label class='col-md-3 control-label' for='FILE_DATA'>_{FILE}_</label>
  <div class='col-md-9'>
    <input id='FILE_DATA' name='FILE_DATA' value='%FILE_DATA%' placeholder='%FILE_DATA%' class='input-file' type='file'>
  </div>
</div>

<div class='form-group'>
    <label class='col-md-3 control-label' for='IMPORT_TYPE'>_{FROM}_</label>
  <div class='col-md-9'>
    %IMPORT_TYPE_SEL%
  </div>
</div>

<div class='form-group'>
    <label class='col-md-3 control-label' for='DATE'>_{DATE}_</label>
  <div class='col-md-9'>
    <input id='DATE' name='DATE' value='%DATE%' placeholder='%DATE%' class='form-control' type='text'>
  </div>
</div>


<div class='form-group'>
    <label class='col-md-3 control-label' for='PAYMENT_METHOD'>_{PAYMENT_METHOD}_</label>
  <div class='col-md-9'>
    %METHOD%
  </div>
</div>

<div class='form-group'>
    <label class='col-md-3 control-label' for='ENCODE'>_{ENCODE}_</label>
  <div class='col-md-9'>
    %ENCODE_SEL%
  </div>
</div>

%FORM_ER%

<div class='form-group'>
    <label class='col-md-3 control-label' for='DEBUG'>_{DEBUG}_</label>
    <div class='col-md-9'>
      <input name='DEBUG' id='DEBUG' value='1' type='checkbox'>
    </div>
</div>

<input type=submit name=IMPORT value='IMPORT' class='btn btn-default btn-primary'>

</fieldset>

</div>
</div>

</form>

