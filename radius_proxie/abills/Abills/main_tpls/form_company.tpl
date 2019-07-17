<div class='box box-theme box-form'>
<div class='box-body'>

<form action='$SELF_URL' METHOD='POST' name='company' class='form-horizontal' enctype='multipart/form-data'>
<input type=hidden name='index' value='13'>
<input type=hidden name='ID' value='%ID%'>

<fieldset>
  <legend>_{COMPANY}_</legend>

  <div class='form-group'>
    <label for='COMPANY_NAME' class='control-label col-md-3'>_{NAME}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='NAME' placeholder='%NAME%' name='NAME' value='%NAME%'>
    </div>
  </div>
  
    <div class='form-group'>
    <label for='ADDRESS' class='control-label col-md-3'>_{ADDRESS}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='ADDRESS' placeholder='%ADDRESS%' name='ADDRESS' value='%ADDRESS%'>
    </div>
  </div>
  
  <div class='form-group'>
    <label for='PHONE' class='control-label col-md-3'>_{PHONE}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='PHONE' placeholder='%PHONE%' name='PHONE' value='%PHONE%'>
    </div>
  </div>
  
    <div class='form-group'>
    <label for='REPRESENTATIVE' class='control-label col-md-3'>_{REPRESENTATIVE}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='REPRESENTATIVE' placeholder='%REPRESENTATIVE%' name='REPRESENTATIVE' value='%REPRESENTATIVE%'>
    </div>
  </div>


   <div class='form-group'>
  <label class='control-label col-md-6' for='BILL_ID'>_{BILL}_:</label>
  <div class='col-md-2'>
  	<div class='input-group'>
      %BILL_ID%
     </div>
    </div>
   </div>
   
    <div class='form-group'>
  <label class='control-label col-md-6' for='DEPOSIT'>_{DEPOSIT}_:</label>
  <div class='col-md-2'>
  	<div class='input-group'>
      %DEPOSIT%
     </div>
    </div>
   </div>
   
%EXDATA%

<div class='form-group'>
    <label for='CREDIT' class='control-label col-md-3'>_{CREDIT}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT' value='%CREDIT%'>
    </div>
  </div>
  
  <div class='form-group'>
    <label for='CREDIT_DATE' class='control-label col-md-3'>_{DATE}_:</label>
    <div class='col-md-9'>
      <input class='datepicker form-control' id='CREDIT_DATE' placeholder='%CREDIT_DATE%' name='CREDIT_DATE' value='%CREDIT_DATE%'>
    </div>
  </div>
  
  <div class='form-group'>
    <label for='VAT' class='control-label col-md-3'>_{VAT}_ (%):</label>
    <div class='col-md-9'>
      <input class='form-control' id='VAT' placeholder='%VAT%' name='VAT' value='%VAT%'>
    </div>
  </div>
  
    <div class='form-group'>
    <label for='REGISTRATION' class='control-label col-md-3'>_{REGISTRATION}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='REGISTRATION' placeholder='%REGISTRATION%' name='REGISTRATION' value='%REGISTRATION%'>
    </div>
  </div>
  
  
  <legend>_{BANK_INFO}_</legend>
  
   <div class='form-group'>
    <label for='TAX_NUMBER' class='control-label col-md-3'>_{TAX_NUMBER}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='TAX_NUMBER' placeholder='%TAX_NUMBER%' name='TAX_NUMBER' value='%TAX_NUMBER%'>
    </div>
  </div>
   <div class='form-group'>
    <label for='BANK_ACCOUNT' class='control-label col-md-3'>_{ACCOUNT}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='BANK_ACCOUNT' placeholder='%BANK_ACCOUNT%' name='BANK_ACCOUNT' value='%BANK_ACCOUNT%'>
    </div>
  </div>
   <div class='form-group'>
    <label for='BANK_NAME' class='control-label col-md-3'>_{BANK}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='BANK_NAME' placeholder='%BANK_NAME%' name='BANK_NAME' value='%BANK_NAME%'>
    </div>
  </div>
   <div class='form-group'>
    <label for='COR_BANK_ACCOUNT' class='control-label col-md-3'>_{COR_BANK_ACCOUNT}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='COR_BANK_ACCOUNT' placeholder='%COR_BANK_ACCOUNT%' name='COR_BANK_ACCOUNT' value='%COR_BANK_ACCOUNT%'>
    </div>
  </div>
   <div class='form-group'>
    <label for='BANK_BIC' class='control-label col-md-3'>_{BANK_BIC}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='BANK_BIC' placeholder='%BANK_BIC%' name='BANK_BIC' value='%BANK_BIC%'>
    </div>
  </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='CONTRACT_ID'>_{CONTRACT_ID}_</label>
  <div class='col-sm-4'>
  	<div class='input-group'>
      <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' placeholder='%CONTRACT_ID%' class='form-control' type='text'>

      <div class='input-group-btn'>
        <button type='button' class='btn btn-default dropdown-toggle' data-toggle='dropdown' aria-expanded='false'><span class='caret'></span></button>
        <ul class='dropdown-menu dropdown-menu-right' role='menu'>
          <li><span class='input-group-addon'>%PRINT_CONTRACT%</span></li>
          <!-- <li><span class='input-group-addon'><a href='$SELF_URL?qindex=13&COMPANY_ID=%ID%&PRINT_CONTRACT=%CONTRACT_ID%&SEND_EMAIL=1&pdf=1' class='glyphicon glyphicon-envelope' target=_new></a></span></li> -->
        </ul>
      </div>
    </div>
    %CONTRACT_SUFIX%
  </div>

  <label class='control-label col-md-1' for='CONTRACT_DATE'>_{DATE}_</label>
  <div class='col-md-4'>
    <input id='CONTRACT_DATE' type='text' name='CONTRACT_DATE' value='%CONTRACT_DATE%' class='datepicker form-control'>
  </div>
</div>

%CONTRACT_TYPE%

  <div class='form-group'>
  <label class='control-label col-md-6' for='DISABLE'>_{DISABLE}_:</label>
  <div class='col-md-2'>
    <input id='DISABLE' name='DISABLE' value='1' %DISABLE%  type='checkbox'>
  </div>
   </div>
   
   %INFO_FIELDS%
   
   <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
   </fieldset>
</form>
