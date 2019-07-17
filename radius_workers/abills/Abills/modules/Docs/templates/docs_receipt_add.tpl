<form action='$SELF_URL' method='post' name='invoice_add'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='DOC_ID' value='%DOC_ID%'>
<input type=hidden name='sid' value='$FORM{sid}'>
<input type=hidden name='step' value='$FORM{step}'>
<input type=hidden name='OP_SID' value='%OP_SID%'>
<input type=hidden name='VAT' value='%VAT%'>
<input type=hidden name='SEND_EMAIL' value='1'>
<input type=hidden name='ALL_SERVICES' value='1'>
    <div class='box box-theme'>
        <div class="box-header with-border">
            <h3 class="box-title">%CAPTION%</h3>
        </div>
        <div class='box-body form form-horizontal'>


<table class=form>
%FORM_ACCT_ID%
<tr><td>_{DATE}_:</td><td>%DATE%</td></tr>
<tr><td><b>_{CURENT_BILLING_PERIOD}_:</b></td><td><b>%CURENT_BILLING_PERIOD_START% - %CURENT_BILLING_PERIOD_STOP%</b></td></tr>
<tr><td>_{PERIOD}_:</td><td>_{FROM}_: %FROM_DATE% _{TO}_: %TO_DATE% </td></tr>
<tr><td>&nbsp;</td><td>
<input type=radio name=INCLUDE_CUR_BILLING_PERIOD value=0 checked> _{INCLUDE_CUR_BILLING_PERIOD}_ <br>
<input type=radio name=INCLUDE_CUR_BILLING_PERIOD value=1> _{NOT_INCLUDE_CUR_BILLING_PERIOD}_
</td></tr>


<tr><td>_{NEXT_PERIODS}_ (_{MONTH}_):</td><td><input type=text name=NEXT_PERIOD value='%NEXT_PERIOD=0%' size=5 class='form-control'></td></tr>
<tr><td>_{SEND}_ E-mail:</td><td><input type=checkbox name=SEND_EMAIL value=1 checked></td></tr>
<tr><td>_{INCLUDE_DEPOSIT}_:</td><td><input type=checkbox name=INCLUDE_DEPOSIT value=1 checked></td></tr>
<tr><td colspan=2>

%ORDERS%

</td></tr>
<!-- <tr><td>_{VAT}_:</td><td>%COMPANY_VAT%</td></tr> -->
<tr><td colspan=2>&nbsp;</td></tr>
<!-- <tr><td>_{PRE}_</td><td><input type=checkbox name=PREVIEW value='1'></td></tr> -->
<tr><th colspan=2 class='even'>
%BACK%
<input type=submit name=update value='_{REFRESH}_' class='btn btn-default'>
<input type=submit name=create value='_{CREATE}_' class='btn btn-primary'>
%NEXT%


</th></tr>
</table>
<!-- <input type=submit name=pre value='_{PRE}_'>  -->
        </div>
    </div>
</form>
