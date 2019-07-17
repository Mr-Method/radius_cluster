<form action="https://wl.walletone.com/checkout/checkout/Index" method='post'>

<input type='hidden' name='WMI_MERCHANT_ID' value=%WMI_MERCHANT_ID%>
<input type='hidden' name='WMI_PAYMENT_AMOUNT' value=%WMI_PAYMENT_AMOUNT%>
<input type='hidden' name='WMI_CURRENCY_ID' value=%WMI_CURRENCY_ID%>
<input type='hidden' name='WMI_PAYMENT_NO' value=%WMI_PAYMENT_NO%>
<input type='hidden' name='WMI_DESCRIPTION' value=%WMI_DESCRIPTION%>
<input type='hidden' name='WMI_SUCCESS_URL' value=%WMI_SUCCESS_URL%>
<input type='hidden' name='WMI_FAIL_URL' value=%WMI_FAIL_URL%>
<input type='hidden' name='WMI_SIGNATURE' value=%WMI_SIGNATURE%>
<input type='hidden' name='UID' value=%UID%>

<div class='box box-primary'>
    <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>WALLETONE</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> $FORM{SUM}</label>
    </div>
</div>
    <div class='box-footer text-center'>
        <input class='btn btn-primary' type=submit value=_{PAY}_>
    </div>
</div>   

</form>