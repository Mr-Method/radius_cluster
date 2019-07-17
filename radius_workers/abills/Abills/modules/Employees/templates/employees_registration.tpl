<form action=$SELF_URL METHOD=POST class='form-horizontal'>

	<div class='box box-primary box-form'>
		<!-- head -->
	  <div class='box-header with-border'><h3 class='box-title'>_{EMPLOYEE_PROFILE}_</h3></div>
	  <!-- body -->
	  <div class='box-body'>

	  	<div class='form-group'>
	  	  <label class='col-md-3 control-element'>_{FIO}_</label>
	  	  <div class='col-md-9'>
	  	    <input required type='text' class='form-control' name='FIO' value='%FIO%'>
	  	  </div>
	  	</div>

	  	<div class='form-group'>
	  		<label class='col-md-3 control-element'>_{BIRTHDAY}_</label>
	  		<div class='col-md-9'>
	  	<input required name="DATE" value="%DATE%" class="form-control datepicker" id="DATE" type="text">
        <div class="input-group-addon"><i class="fa fa-calendar"></i></div>	  		
	  	</div>
	</div>

	  	<div class='form-group'>
	  		<label class='col-md-3 control-element'>_{PHONE}_</label>
	  		<div class='col-md-9'>
	  			<input  required type='text' class='form-control' name='PHONE' value='%PHONE%'>
	  		</div>
	  	</div>

	   <div class='form-group center-block'>
	  		<label class='col-md-3 control-element'>_{MAIL_BOX}_</label>
	  		<div class='col-md-9'>
	  			<input  required type='text' class='form-control' name='MAIL' value='%MAIL%'>
	  		</div>
	  	</div>

     	  	<div class='form-group'>
	  		<label class='col-md-3 control-element'>_{POSITION}_</label>
	  		<div class='col-md-9'>
                  %POSITIONS%
 	  		</div>
	  	</div>


	  </div>
	  <!-- footer -->
	  <div class='box-footer'>

	  	<p class='text-center'><input type='submit' class='btn btn-primary pull-center' name='NEXT_BUTTON' value='_{NEXT}_'></p>

	</div>

</form>
