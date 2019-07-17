<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message' class='form-horizontal' >
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='$FORM{chg}'/>
<input type='hidden' name='PROGRES_BAR' value='$FORM{PROGRES_BAR}'/>


<div class='box box-theme box-form'>
    <legend> _{PROGRES_BAR}_</legend>
<div class='box-body form form-horizontal'>

<div class='form-group'>
    <label class='control-label col-md-3'>_{STEP}_ _{NUM}_:</label>
	<div class='col-md-9'><input type=text name=STEP_NUM value='%STEP_NUM%' class='form-control'></div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3'>_{STEP}_ _{NAME}_:</label>
	<div class='col-md-9'><input type=text name=STEP_NAME value='%STEP_NAME%' class='form-control'></div>
</div>


<div class='form-group'>
    <label class='control-label col-md-3'>_{TIPS}_:</label>
	<div class='col-md-9'>
		<textarea name=STEP_TIP rows=6 cols=45 class='form-control'>%STEP_TIP%</textarea>
	</div>
</div>

 <div class='form-group'>
    <div class='checkbox'>
      <label class='col-md-3'></label>
    <label>
      <input type='checkbox' name='USER_NOTICE' %USER_NOTICE% >_{USER_NOTICE}_
    </label>
  </div>
  </div>

   <div class='form-group'>
    <div class='checkbox'>
      <label class='col-md-3'></label>
    <label>
      <input type='checkbox' name='RESPONSIBLE_NOTICE' %RESPONSIBLE_NOTICE% >_{RESPONSIBLE_NOTICE}_
    </label>
  </div>
  </div>

   <div class='form-group'>
    <div class='checkbox'>
      <label class='col-md-3'></label>
    <label >
      <input type='checkbox' name='FOLLOWER_NOTICE' %FOLLOWER_NOTICE%>_{FOLLOWER_NOTICE}_
    </label>
  </div>
  </div>

</div>
<div class='box-footer'>
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>
</div>

</form>
