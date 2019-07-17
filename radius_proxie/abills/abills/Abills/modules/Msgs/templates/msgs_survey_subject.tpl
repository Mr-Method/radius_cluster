<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message' class='form-horizontal' >
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='$FORM{chg}'/>

<div class='box box-theme box-form'>
    <legend> _{TEMPLATES}_ (_{QUESTIONS}_)</legend>
<div class='box-body form form-horizontal'>

<div class='form-group'>
    <label class='control-label col-md-3'>_{NAME}_ (_{SUBJECT}_):</label>
	<div class='col-md-9'><input type=text name=NAME value='%NAME%' class='form-control' required></div>
</div>

<div class='form-group'>
    <label class='control-label col-sm-3' for='TPL'>_{TEXT}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' id='TPL' name='TPL' rows='3' class='form-control' >%TPL%</textarea>
    </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3'>_{COMMENTS}_:</label>
	<div class='col-md-9'>
		<textarea name=COMMENTS rows=6 cols=45 class='form-control'>%COMMENTS%</textarea>
	</div>
</div>

<div class='form-group'>
    <label class='control-label col-sm-3' for='FILE_UPLOAD_1'>_{ATTACHMENT}_ 1</label>
	  <div class='col-sm-6'>
  	  <input type='file' name='FILE_UPLOAD_1' ID='FILE_UPLOAD_1' value='%FILE_UPLOAD%' placeholder='%FILE_UPLOAD%' class='form-control' >
  	  %FILENAME%
  	</div>
</div>

<div class='form-group'>
    <label class='control-label col-sm-3' for='STATUS'>_{STATUS}_</label>
	  <div class='col-sm-6'>
  	  %STATUS_SEL%
  	</div>
</div>


</div>
<div class='box-footer'>
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>
</div>

</form>
