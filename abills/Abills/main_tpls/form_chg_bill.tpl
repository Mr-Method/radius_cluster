<form action='$SELF_URL'>
<input type=hidden name='index' value='$index'/>
<input type=hidden name='UID' value='%UID%'/>
<input type=hidden name='COMPANY_ID' value='$FORM{COMPANY_ID}'/>

<div class='box box-form box-primary form-horizontal'>
<div class='box-header with-border'>_{BILL}_: %BILL_TYPE%</div>
<div class='box-body'>
  <div class='form-group'>
    <label class='col-md-4 control-label'>_{BILL}_:</label>
    <div class='col-md-8'>%BILL_ID%:%LOGIN%</div>
  </div>
  <div class='form-group'>
      <label class='col-md-4 control-label'>_{CREATE}_:</label>
      <div class=col-md-8'>
      <input type='checkbox' name='%CREATE_BILL_TYPE%' value='1' %CREATE_BILL% checked />
      </div>
  </div>
  <div class='form-group'>
    <label class='col-md-4 control-label'>_{TO}_:</label>
    <div class='col-md-8'>
      %SEL_BILLS%
    </div>
  </div>
</div>
<div class='box-footer'>
<input type='submit' class='btn btn-primary' name='change' value='_{CHANGE}_' class='button'/>
</div>
</div>
</form>
