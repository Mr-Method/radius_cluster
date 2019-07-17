<form action=$SELF_URL METHOD=POST class='form-horizontal'>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='OLD_PARAM' value='%OLD_PARAM%'/>

	<div class='box box-theme'>
		<!-- head -->
	  <div class='box-header with-border'><h3 class='box-title'>_{ORGANIZATION_INFO}_</h3></div>
	  <!-- body -->
	  <div class='box-body'>
 	<div class='form-group'>
	  		<label class='control-label col-xs-3 col-md-2'>_{TAGS}_</label>
	  		<div class='col-md-9'>
	  			%TAGS_PANEL%
	  		</div>
	  	</div>
	  			%ADDRESS_SEL%
	  	<div class='form-group'>
	  		<label class='control-label col-xs-3 col-md-2'>%LABEL% _{VALUE}_</label>
	  		<div class='col-md-9'>
	  			%VALUE_INPUT%
	  		</div>
	</div>

	  </div>
	  <!-- footer -->
	  <div class='box-footer'>

	  	<p class='text-center'><input type='submit' class='btn btn-primary pull-center' name='%BUTTON_NAME%' value='%ACTION%'></p>

	</div>

</form>
