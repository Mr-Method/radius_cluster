<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index'  value='$index'>
<input type='hidden' name='action' value='filter'>
<input type='hidden' name='rule'   value='$FORM{ID}'>

<div class='box box-primary'>
<div class='box-header with-border text-primary'>_{SEARCH}_ _{USERS}_</div>

<div class='box-body'>
	<div class='col-md-6'>
		<div class='box box-theme'>
		<div class='box-header with-border text-default'>_{USER}_</div>

		<div class='box-body'>

			<div class='form-group'>
				<label class='col-md-3 control-label'>_{LOGIN}_:</label>
				<div class='col-md-9'><input name='LOGIN' type='text' class='form-control'></div>
			</div>

			<div class='form-group'>
				<label class='control-label col-md-3'>_{PERIOD}_:</label>
				<div class='col-md-4'>
					<input class='form-control datepicker' placeholder='0000-00-00' name='FROM_DATE' value='%DATE%'>
				</div>
				<div class='col-md-1'>
				-
				</div>
				<div class='col-md-4'>
					<input class='form-control datepicker' placeholder='0000-00-00' name='FROM_DATE' value='%DATE%'>
				</div>
			</div>

			<div class='form-group'>
				<label class='col-md-3 control-label'>_{DEPOSIT}_<br>(>, <):</label>
				<div class='col-md-9'><input name='DEPOSIT' value type='text' class='form-control'></div>
			</div>

			<div class='form-group'>
				<label class='col-md-3 control-label'>_{CREDIT}_<br>(>, <):</label>
				<div class='col-md-9'><input name='CREDIT' value type='text' class='form-control'></div>
			</div>

			<div class='form-group'>
				<label class='col-md-3 control-label'>_{GROUP}_:</label>
				<div class='col-md-9'>%GROUPS%</div>
			</div>

		</div>

		</div>
	</div>

    <div class='col-md-6'>
		<div class='box box-theme'>
		<div class='box-header with-border text-default'>_{TAGS}_</div>
			<div class='box-body'>
				%TAGS%
			</div>
		</div>
	</div>

	<div class='col-md-6'>
	<div class='box box-theme'>
		<div class='box-header with-border text-default'>_{ADDRESS}_</div>
		<div class='box-body'>
		%ADDRESS_FORM%
		</div>
	</div>
	</div>

</div>

<div class='box-footer'>
	<button type='submit' class='btn btn-primary'>_{SEARCH}_</button>
</div>

</div>

</form>