<FORM action='$SELF_URL' METHOD='POST'  >
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='SURVEY_ID' value='$FORM{SURVEY_ID}'/>

<div class='box box-theme box-form'>
<div class='box-body form form-horizontal'>
    <legend>_{QUESTIONS}_</legend>
	<div class='form-group'>
        <label class='control-label col-md-3'>_{NUM}_:</label>
		<div class='col-md-9'>
			<input type=text name=NUM value='%NUM%' class='form-control'>
		</div>
	</div>
	<div class='form-group'>
        <label class='control-label col-md-3'>_{QUESTION}_:</label>
		<div class='col-md-9'>
			<input type=text name=QUESTION value='%QUESTION%' size=40 class='form-control'>
		</div>
	</div>
	<div class='form-group'>
        <label class='control-label col-md-3'>_{PARAMS}_ (;):</label>
		<div class='col-md-9'>
			<textarea name=PARAMS rows=6 cols=45 class='form-control'>%PARAMS%</textarea>
		</div>
	</div>
	<div class='form-group'>
        <label class='control-label col-md-3'>_{COMMENTS}_:</label>
		<div class='col-md-9'>
			<textarea name=COMMENTS rows=6 cols=45 class='form-control'>%COMMENTS%</textarea>
		</div>
	</div>
	<div class='from-group'>
        <label class='col-md-6' style='padding:0px;margin:0px;'>_{USER}_ _{COMMENTS}_:</label>
		<div class='col-md-1'><input type=checkbox name=USER_COMMENTS value=1 %USER_COMMENTS%></div>
        <label class='col-md-4'>_{DEFAULT}_:</label>
		<div class='col-md-1'><input type=checkbox name=FILL_DEFAULT value=1 %FILL_DEFAULT%></div>
	</div>
</div>
<div class='box-footer'>
	<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>
</div>
</form>
