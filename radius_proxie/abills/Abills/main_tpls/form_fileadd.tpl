<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='NAS_GID' value='$FORM{NAS_GID}'>

<fieldset>
<legend>_{ADD}_ _{FILE}_</legend>

<div class='form-group'>
  <label class='col-md-6 control-label' for='FILE_DATA'>_{FILE}_</label>
  <div class='col-md-2'>
    <input id='FILE_DATA' name='FILE_UPLOAD' value='%FILE_UPLOAD%' placeholder='%FILE_DATA%' class='input-file' type='file'>
  </div>
</div>

<input class='button' type='submit' name='UPLOAD' value='_{ADD}_'>

</fieldset>
</FORM>

