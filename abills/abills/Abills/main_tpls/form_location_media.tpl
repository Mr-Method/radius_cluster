<form action='$SELF_URL' class='form-horizontal' METHOD='post' enctype='multipart/form-data' name=add_district>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='chg' value='$FORM{chg}'/>
<input type='hidden' name='BUILDS' value='$FORM{BUILDS}'/>
<input type='hidden' name='media' value='1'/>

<div class='box box-theme box-form'>
  <div class='box-body'>

<fieldset>
	<legend>_{MEDIA}_</legend>
	
<div class='form-group'>
  <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
  <div class='col-md-9'>
      <input id='COMMENTS' name='COMMENTS' value='%COMMENTS%' placeholder='%COMMENTS%' class='form-control' type='text'>
  </div>  
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='FILE'>_{FILE}_:</label>
  <div class='col-md-9'>
      <input id='FILE' name='FILE' value='%FILE%' placeholder='%FILE%' class='form-control' type='file'>
  </div>  
</div>
   
<input type=submit class='btn btn-primary' name='add' value='_{ADD}_'>
	
</fieldset>

</div>
</div>

</form>
