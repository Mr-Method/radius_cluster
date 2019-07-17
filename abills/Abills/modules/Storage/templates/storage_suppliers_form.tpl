<form action=$SELF_URL?index=$index&splid=%ID% name='suppliers_form' method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>

<fieldset>
<div class='box box-theme box-form'>
<div class='box-body form form-horizontal'>
	
  <div class='form-group'><label class='col-md-12'> _{SUPPLIERS}_</label></div>
<!-- 
  <tr>
    <td>TESTING:</td>
    <td>%WND%</td>
  </tr>
-->
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_:</label>
    <div class='col-md-9'><input class='form-control' name='NAME' type='text' value='%NAME%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{DATE}_:</label>
    <div class='col-md-9'><input class='tcal form-control datepickerActive' name='DATE' type='text' value='%DATE%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{OKPO_EDRPOY}_:</label>
    <div class='col-md-9'><input class='form-control' name='OKPO' type='text' value='%OKPO%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-7'>_{INDIVIDUAL_TAX_NUMBER}_:</label>
    <div class='col-md-5'><input class='form-control' name='INN' type='text' value='%INN%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-7'>_{CERTIFICATE_OF_INDIVIDUAL_TAX_NUMBER}_:</label>
    <div class='col-md-5'><input class='form-control' name='INN_SVID' type='text' value='%INN_SVID%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-12'>_{BANK_ESSENTIAL}_:</label>
  </div>
  <div class='form-group'>
    <label class='col-md-3  control-label'>_{NAME_OF_BANK}_:</label>
    <div class='col-md-9'><input class='form-control' name='BANK_NAME' type='text' value='%BANK_NAME%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{MFO}_:</label>
    <div class='col-md-9'><input class='form-control' name='MFO' type='text' value='%MFO%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ACCOUNT}_:</label>
    <div class='col-md-9'><input class='form-control' name='ACCOUNT' type='text' value='%ACCOUNT%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-12'>_{CONTACTS}_:</label>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{PHONE}_ 1:</label>
    <div class='col-md-9'><input class='form-control' name='PHONE' type='text' value='%PHONE%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{PHONE}_ 2:</label>
    <div class='col-md-9'><input class='form-control' name='PHONE2' type='text' value='%PHONE2%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{FAX}_:</label>
    <div class='col-md-9'><input class='form-control' name='FAX' type='text' value='%FAX%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{WEBSITE}_:</label>
    <div class='col-md-9'><input class='form-control' name='URL' type='text' value='%URL%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>E-mail:</label>
    <div class='col-md-9'><input class='form-control' name='EMAIL' type='text' value='%EMAIL%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>ICQ:</label>
    <div class='col-md-9'><input class='form-control' name='ICQ' type='text' value='%ICQ%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-12'>_{GUIDANCE}_:</label>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{POSITION_MANAGER}_:</label>
    <div class='col-md-9'><input class='form-control' name='ACCOUNTANT' type='text' value='%ACCOUNTANT%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{MANAGER}_:</label>
    <div class='col-md-9'><input class='form-control' name='DIRECTOR' type='text' value='%DIRECTOR%' /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ACCOUNTANT}_:</label>
    <div class='col-md-9'><input class='form-control' name='MANAGMENT' type='text' value='%MANAGMENT%' /></div>
  </div>
  
</div>
<div class='box-footer'>
	<th colspan=2 class=even><input type=submit name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'></th>
</div>
</div>  
</fieldset>

</form>