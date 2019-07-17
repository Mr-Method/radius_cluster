<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<input type='hidden' name='chg' value='%ID%'>

<div class='box box-form box-primary form-horizontal'>
<div class='box-header with-border'>_{DILLERS}_</div>
<div class='box-body'>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{TARIF_PLAN}_</label>
		<div class='col-md-9'>
			%TARIF_PLAN_SEL%
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{PERCENTAGE}_</label>
		<div class='col-md-9'>
			<input class='form-control' type='text' name='PERCENTAGE' value='%PERCENTAGE%'>
		</div>
	</div>
	<div class='form-group'>
		<div class='checkbox'>
    	<label>
      	<input type='checkbox' name='DISABLE' value='1' %DISABLE%><strong>_{DISABLE}_</strong>
    	</label>
  	</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{REGISTRATION}_</label>
		<div class='col-md-9'>
			%REGISTRATION%
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{COMMENTS}_</label>
		<div class='col-md-9'>
			<textarea class='form-control' name='COMMENTS' cols='60' rows='6'>%COMMENTS%</textarea>
		</div>
	</div>
</div>
<div class='box-footer'>
%DEL_BUTTON%
<input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
</div>

</div>

</form>