<form action='%PP_LINK%' method='post'> 
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='sid' value='$sid'>
<input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}'>
<input type='hidden' name='FULL_SUM' value='$FORM{FULL_SUM}'>
<input type='hidden' name='SUM' value='$FORM{SUM}'>
<input type='hidden' name='DESCRIBE' value='$FORM{DESCRIBE}'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='STEP' value='1'>

<table width=400 border=0>
<tr><th class='form_title' colspan=2>PayPal</th></tr>
<tr><td colspan=2 align=center><img src='https://www.paypal.com/en_US/i/logo/paypal_logo.gif'></td></tr>
    <tr>
        <td>_{TRANSACTION}_ #:</td>
        <td>$FORM{OPERATION_ID}</td>
    </tr>
    <tr>
        <td>_{SUM}_:</td>
        <td>$FORM{SUM}</td>
    </tr>
    <tr>
        <td>_{FEES}_:</td>
        <td>$FORM{COMMISION}</td>
    </tr>
    <tr>
        <td>_{DESCRIBE}_:</td>
        <td>$FORM{DESCRIBE}</td>
    </tr>
    <tr>
        <th colspan=2><input type='submit' value='_{PAY}_'>



</table>
</form>





