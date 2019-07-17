<form action='https://paymaster.ru/Payment/Init' method='POST'>

<input type='hidden' name='LMI_MERCHANT_ID'    value='%LMI_MERCHANT_ID%'>
<input type='hidden' name='LMI_PAYMENT_AMOUNT' value='%SUM%'>
<input type='hidden' name='LMI_CURRENCY'       value='%CURRENCY%'>
<input type='hidden' name='LMI_PAYMENT_NO'     value='%ORDER_ID%'>
<input type='hidden' name='LMI_SIM_MODE'       value='%SIM_MOD%'>
<input type='hidden' name='LMI_PAYMENT_DESC'   value='Internet'>
<input type='hidden' name='LMI_PAYMENT_NOTIFICATION_URL'   value='%NOTIFICATION_URL%'>
<input type='hidden' name='LMI_SUCCESS_URL'   value='%SUCCESS_URL%'>
<input type='hidden' name='LMI_FAILURE_URL'   value='%FAILURE_URL%'>
<input type='hidden' name='USER'               value='%USER%'>

  
<div class='box box-primary'>
    <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>%ORDER_ID%</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>Paymaster Ru</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> %SUM% </label>
    </div>
  %Checkbox%
</div>
    <div class='box-footer'>
        <input class='btn btn-primary' type=submit value='_{PAY}_'>
    </div>
</div>    

</form>