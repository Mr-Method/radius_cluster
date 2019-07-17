<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value='$index'>

<div class='box box-theme box-form'>
<div class='box-header with-border text-primary'>_{RULES_LIST}_</div>
<div class='box-body'>
        <div class='form-group'>
			<label class='col-md-3 control-label'>_{RULE}_</label>
			<div class='col-md-9'>
			    %RULE_SELECT%
			</div>
		</div>
</div>

<div class='box-footer'>
	<button type='submit' class='btn btn-primary'>_{SELECT}_</button>
</div>

</div>

</form>