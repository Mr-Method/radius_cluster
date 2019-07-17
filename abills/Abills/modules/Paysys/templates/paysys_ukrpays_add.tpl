<!-- UKRPAYS START -->

<FORM ACTION='$conf{PAYSYS_UKRPAYS_URL}' method='POST'>
<INPUT TYPE='HIDDEN' NAME='OPERATION_ID' VALUE='$FORM{OPERATION_ID}'>

<input type='hidden' name='charset' value='UTF-8' />
<input type='hidden' name='order' value='%UID%'> 
<input type='hidden' name='login' value='%UID%'>
<input type='hidden' name='sus_url' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1&index=$index&PAYMENT_SYSTEM=46&OPERATION_ID=$FORM{OPERATION_ID}&TP_ID=$FORM{TP_ID}&DOMAIN_ID=$FORM{DOMAIN_ID}%SUS_URL_PARAMS%'>
<input type='hidden' name='lang' value='%LANG%'>
<input type='hidden' name='fio' value='%FIO%'>
<input type='hidden' name='note' value='$FORM{OPERATION_ID}'>
<input type='hidden' name='service_id' value='$conf{PAYSYS_UKRPAYS_SERVICE_ID}'>
<input type='hidden' name='amount' value='%AMOUNT%'>

<div class='box box-primary'>
<div class='box-header with-border text-center'>Visa / Mastercard (Ukrpays)</div>
<div class='box-body'>
	<div class='form-group text-center'>
	<img src='https://ukrpays.com/img/logo.gif'>
	<a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>
	<img src='/img/mastercard-sc.gif' width=140 height=75 border=0>
	</a>	
	</div>
	<div class='form-group'>
        <label class='col-md-6 text-right'>_{SUM}_:</label>
		<label class='col-md-6 control-label text-left'>%AMOUNT%</label>
	</div>

</div>
<div class='box-footer text-center'>
    <input class='btn btn-primary' type='submit' name='pay' value='_{PAY}_'>
</div>

</div>
</FORM>

<!-- UKRPAYS END -->
