<FORM ACTION='https://www.portmone.com.ua/gateway/' method='POST' >
<INPUT TYPE='HIDDEN' NAME='PAYEE_ID' VALUE='$conf{PAYSYS_PORTMONE_PAYEE_ID}' />
<INPUT TYPE='HIDDEN' NAME='PAYEE_NAME' VALUE='$conf{WEB_TITLE}'>
<INPUT TYPE='HIDDEN' NAME='PAYEE_HOME_PAGE_URL' VALUE='$conf{PAYSYS_PORTMONE_HOME_PAGE_URL}'>
<INPUT TYPE='HIDDEN' NAME='SHOPORDERNUMBER' VALUE='$FORM{OPERATION_ID}' />
<INPUT TYPE='HIDDEN' NAME='BILL_AMOUNT' VALUE='$FORM{SUM}' />
<INPUT TYPE='HIDDEN' NAME='DESCRIPTION' VALUE='$FORM{DESCRIBE}' />
<INPUT TYPE='HIDDEN' NAME='OUT_URL' VALUE='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi?index=$FORM{index}&sid=$FORM{sid}' />
<INPUT TYPE='HIDDEN' NAME='LANG' VALUE='%LANG%' />

<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='45'>


<input type=hidden name='ADD_PARAM[1][NAME]' value='UID' /> 
<input type=hidden name='ADD_PARAM[1][VALUE]' value='$LIST_PARAMS{UID}' />

    <div class='box box-primary'>
        <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

        <div class='box-body'>
            <div class='form-group'>
                <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
                <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
            </div>

            <div class='form-group'>
                <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
                <label class='col-md-6 control-label'>Portmone</label>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
                <label class='control-label col-md-6'> $FORM{SUM} </label>
            </div>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type='submit' value=_{PAY}_ name='submit'>
        </div>
    </div>

    <!--<table width=100% class=form>-->
<!--<tr><th class='form_title' colspan=2>Visa / Mastercard (Portmone)</th></tr>-->

<!--<tr><th colspan=2 align=center>-->
<!--<a href='https://secure.privatbank.ua/help/verified_by_visa.html'-->
<!--<img src='/img/v-visa.gif' width=140 height=75 border=0></a>-->
<!--<a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>-->
<!--<img src='/img/mastercard-sc.gif' width=140 height=75 border=0>-->
<!--</a>-->
<!--</td></tr>-->


<!--<tr><td>ID:</td><td>$FORM{OPERATION_ID}</td></tr>-->
    <!--<tr>-->
        <!--<td>_{DESCRIBE}_:</td>-->
        <!--<td>$FORM{DESCRIBE}</td>-->
    <!--</tr>-->
    <!--<tr>-->
        <!--<td>_{SUM}_:</td>-->
        <!--<td>$FORM{SUM}</td>-->
    <!--</tr>-->

    <!--<tr>-->
        <!--<th colspan=2><INPUT TYPE='submit' NAME='submit' VALUE='_{ADD}_'/>-->
        <!--</td></tr>-->
<!--</table>-->


</FORM>



