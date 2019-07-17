<form action=$SELF_URL METHOD=POST class='form-horizontal'>
	<input type='hidden' name=index value=$index>
	<input type='hidden' name=action value='%ACTION%'>
	<input type='hidden' name=id value='%ID%'>

	<div class='box box-theme box-form'>
		<!-- head -->
	  <div class='box-header with-border'>_{EMPLOYEES}_</div>
	  <!-- body -->
	  <div class='box-body'>

	  	<div class='form-group'>
	  	  <label class='col-md-3 control-element'>_{LOGIN}_</label>
	  	  <div class='col-md-9'>
	  	    <input type='text' class='form-control' name='LOGIN' value='%LOGIN%'>
	  	  </div>
	  	</div>

	  	<div class='form-group'>
	  		<label class='col-md-3 control-element'>_{FIO}_</label>
	  		<div class='col-md-9'>
	  			<input type='text' class='form-control' name='FIO' value='%FIO%'>
	  		</div>
	  	</div>

	  	<div class='form-group'>
	  		<label class='col-md-3 control-element'>_{POSITION}_</label>
	  		<div class='col-md-9'>
	  			%POSITIONS%
	  		</div>
	  	</div>

	  	<div class='form-group'>
	  		<label class='col-md-3 control-element'>_{PHONE}_</label>
	  		<div class='col-md-9'>
	  			<input type='text' class='form-control' name='PHONE' value='%PHONE%'>
	  		</div>
	  	</div>

	  </div>
	  <!-- footer -->
	  <div class='box-footer'>
	  	<input type='submit' class='btn btn-primary' name='BUTTON' value='%BUTTON_NAME%'>
	  </div>

	</div>

</form>