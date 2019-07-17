<p><a class=link_button title='_{NEXT_PERIOD}_ _{INVOICE}_'
      href='$SELF_URL?index=$index&amp;ALL_SERVICES=1&amp;UID=$FORM{UID}'>_{NEXT_PERIOD}_ _{INVOICE}_</a></p>


<form action='$SELF_URL' method='post' name='account_add'>
    <input type=hidden name=index value=$index>
    <input type=hidden name='UID' value='$FORM{UID}'>
    <input type=hidden name='DOC_ID' value='%DOC_ID%'>
    <input type=hidden name='sid' value='$FORM{sid}'>
    <input type=hidden name='OP_SID' value='%OP_SID%'>
    <input type=hidden name=step value='$FORM{step}'>
    <input type=hidden name='VAT' value='%VAT%'>
    <input type=hidden name='SEND_EMAIL' value='1'>
    <input type=hidden name=INCLUDE_DEPOSIT value=1>

    <div class='box box-primary'>
        <div class='box-header with-border'><h4 class='box-title'>%CAPTION%</h4></div>
        <div class='box-body form form-horizontal'>
            %FORM_ACCT_ID%
            <div class='form-group'>
                <label class='control-label col-md-3'>_{DATE}_:</label>

                <div class='col-md-9' style='margin-top:5px'>%DATE_FIELD%</div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{CUSTOMER}_:</label>

                <div class='col-md-9'><input type='text' name='CUSTOMER' value='%CUSTOMER%' class='form-control'></div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{PHONE}_:</label>

                <div class='col-md-9'><input type='text' name='PHONE' value='%PHONE%' class='form-control'></div>
            </div>

            %ORDERS%

            <!-- <tr><td>_{VAT}_:</td><td>%COMPANY_VAT%</td></tr> -->

            <!-- <tr><td>_{PRE}_</td><td><input type=checkbox name=PREVIEW value='1'></td></tr> -->

        </div>
        <div class='box-footer'>
            <input type=submit name=create value='_{CREATE}_' class='btn btn-primary'>
        </div>
    </div>
    <!-- <input type=submit name=pre value='_{PRE}_'>  -->

</form>
