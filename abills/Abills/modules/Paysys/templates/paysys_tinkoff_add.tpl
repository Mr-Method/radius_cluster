<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'/>
    <input type='hidden' name='SUM' value='$FORM{SUM}'/>
    <input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}'/>
    
<div class='box box-primary'>
    <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>Tinkoff Bank</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> $FORM{SUM} </label>
    </div>
</div>
    <div class='box-footer'>
        <input class='btn btn-primary' type='submit' value=_{PAY}_ name='Init'>
    </div>
</div> 

</form>