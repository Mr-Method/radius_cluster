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
        <div class='box-header with-border'>
            <h3 class='box-title'>%CAPTION%</h3>
        </div>
        <div class='box-body form-horizontal'>

            <div class='form-group'>
                <label class='control-label col-md-3' for='DATE'>_{DATE}_:</label>
                <div class='col-md-9'>
                    %DATE%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='CURENT_BILLING_PERIOD'>_{CURENT_BILLING_PERIOD}_:</label>
                <div class='col-md-9'>
                    %CURENT_BILLING_PERIOD_START% - %CURENT_BILLING_PERIOD_STOP%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='PERIOD'>_{PERIOD}_:</label>
                <div class='col-md-9'>
                    %PERIOD_DATE%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='INCLUDE_CUR_BILLING_PERIOD'></label>
                <div class='col-md-9'>
                    <input type=radio id=INCLUDE_CUR_BILLING_PERIOD name=INCLUDE_CUR_BILLING_PERIOD value=0 checked>
                    _{INCLUDE_CUR_BILLING_PERIOD}_ <br>
                    <input type=radio id=INCLUDE_CUR_BILLING_PERIOD name=INCLUDE_CUR_BILLING_PERIOD value=1>
                    _{NOT_INCLUDE_CUR_BILLING_PERIOD}_
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-3' for='NEXT_PERIOD'>_{NEXT_PERIODS}_ (_{MONTH}_):</label>
                <div class='col-md-9'>
                    <input type=text name=NEXT_PERIOD ID='NEXT_PERIOD' value='%NEXT_PERIOD=0%' size=5
                           class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='SEND_EMAIL'>_{SEND}_ E-mail:</label>
                <div class='col-md-9'>
                    <input type=checkbox name=SEND_EMAIL id='SEND_EMAIL' value=1 checked>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='INCLUDE_DEPOSIT'>_{INCLUDE_DEPOSIT}_:</label>
                <div class='col-md-9'>
                    <input type=checkbox name=INCLUDE_DEPOSIT id='INCLUDE_DEPOSIT' value=1 checked>
                </div>
            </div>

            <!-- <input type=submit name=pre value='_{PRE}_'>  -->
            <div class='form-group'>
                %ORDERS%
            </div>


        </div>
        <div class='box-footer'>

            %BACK%
            <input type=submit name=update value='_{REFRESH}_' class='btn btn-default'>
            <input type=submit name=create value='_{CREATE}_' class='btn btn-primary'>
            %NEXT%


        </div>
    </div>
</form>
