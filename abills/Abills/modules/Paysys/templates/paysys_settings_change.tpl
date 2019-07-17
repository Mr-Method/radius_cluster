<form name='PAYSYS_SETTINGS' id='form_PAYSYS_SETTINGS' method='post' class='form form-horizontal'>

<input type='hidden' name='PAYMENT_SYSTEM' value='%PAYSYS_NAME%'>
<input type='hidden' name='index' value='%index%' >

<div class='box box-primary'>
  <div class='box-header with-border'>%PAYSYS_NAME%</div>
  <div class='box-body'>
  	<div class='form-group'>
        <label class='control-label col-md-6' style='text-align: right'>_{VERSION}_</label>
  		<label class='control-label col-md-6' style='text-align: left'>%VERSION%</label>
  	</div>
  	%INPUT%
  </div>
  <div class='box-footer'>
      <input type='submit' form='form_PAYSYS_SETTINGS' class='btn btn-primary' name='action' value='_{CHANGE}_'>
  </div>
</div>

</form>