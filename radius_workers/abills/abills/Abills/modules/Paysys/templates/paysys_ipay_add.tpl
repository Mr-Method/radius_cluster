<form id=pay name=pay method='POST' action='%IPAY_URL%'>


<div class='box box-primary'>
    <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>%ORDER_ID%</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>IPAY</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> %SUM% </label>
    </div>
</div>
    <div class='box-footer'>
        <input class='btn btn-primary' type=submit value='_{PAY}_'>
    </div>
</div>  

</form>

<!--



<input type='hidden' name='good' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=%IPAY_PAYMENT_NO%'>
<input type='hidden' name='bad' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=FALSE&trans_num=%IPAY_PAYMENT_NO%'>
<input type='hidden' name='IPAY_PAYMENT_NO' value='%IPAY_PAYMENT_NO%'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='id' value='$conf{PAYSYS_IPAY_MERCHANT_ID}'>
<input type='hidden' name='amount' value='%amount%'>
<input type='hidden' name='desc' value='%desc%'>
<table width=300 class=form>
<tr><th colspan='2' class='form_title'>Ipay</th></tr>
<tr>
	<td>ID:</td>
	<td>%IPAY_PAYMENT_NO%</td>
</tr>
<tr>
	<td>_{SUM}_:</td>
	<td>%amount_with_point%</td>
</tr>
<tr>
	<td>_{DESCRIBE}_:</td>
	<td>%desc%</td>
</tr>
<tr>
	<th colspan=2><a href=https://ipay.ua/ua/menu/questions_and_answers/>_{HELP}_</a>&nbsp;</th>
</tr>
<tr>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
<tr><th colspan='2' class='even'><input type='submit' value='_{ADD}_'></th></tr>
</table>

</form>
-->
