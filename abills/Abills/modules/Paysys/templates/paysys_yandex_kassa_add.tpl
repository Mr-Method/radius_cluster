<form action='%YANDEX_ACTION%' method='post'>
    <input type='hidden' name='shopId'         value='%SHOP_ID%'  />
    <input type='hidden' name='scid'           value='%SCID%'     />
    <input type='hidden' name='sum'            value='$FORM{SUM}' >
    <input type='hidden' name='orderNumber'    value='$FORM{OPERATION_ID}' />
    <input type='hidden' name='customerNumber' value='%CUSTOMER%'           />
    <input type='hidden' name='paymentType'    value=''           />
    <!-- <input name='orderNumber' value='abc1111111' type='hidden'/>
    <input name='cps_phone' value='79110000000' type='hidden'/>
    <input name='cps_email' value='user@domain.com' type='hidden'/>
    <input type='submit' value='Заплатить'/> -->

<div class='box box-primary'>
    <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>Yandex Kassa</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> $FORM{SUM} </label>
    </div>
</div>
    <div class='box-footer text-center'>
        <input class='btn btn-primary' type=submit value=_{PAY}_>
    </div>
</div> 

</form>