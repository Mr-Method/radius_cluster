<form action='$SELF_URL' class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=$FORM{chg}>
    <input type=hidden name=TP_ID value=$FORM{TP_ID}>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            <h3 class='box-title'>_{RULES}_</h3>
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>

                <div class='col-md-9'>
                    <input type=text name='NAME' class='form-control' value='%NAME%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{SERVICE}_ _{PERIOD}_ (_{MONTH}_):</label>

                <div class='col-md-9'>
                    <input type=text name='SERVICE_PERIOD' class='form-control' value='%SERVICE_PERIOD%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{REGISTRATION}_ (_{DAYS}_):</label>

                <div class='col-md-9'>
                    <input type=text name='REGISTRATION_DAYS' class='form-control' value='%REGISTRATION_DAYS%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{TOTAL}_ _{PAYMENTS}_ (_{SUM}_):</label>

                <div class='col-md-9'>
                    <input type=text name='TOTAL_PAYMENTS_SUM' class='form-control' value='%TOTAL_PAYMENTS_SUM%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{ONETIME_PAYMENT_SUM}_:</label>

                <div class='col-md-9'>
                    <input type=text name='ONETIME_PAYMENT_SUM' class='form-control'
                    value='%ONETIME_PAYMENT_SUM%'>
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-3'>_{PAYMENTS}_ _{TYPE}_:</label>

                <div class='col-md-9'>
                    %PAYMENT_TYPES_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{TARIF_PLANS}_:</label>

                <div class='col-md-9'>
                    %SEL_TP%
                </div>
            </div>


            <div class='box-header with-border'>
                <h3 class='box-title'>_{RESULT}_</h3>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{REDUCTION}_ %:</label>
                <div class='col-md-9'>
                    <input type=text name='DISCOUNT' class='form-control' value='%DISCOUNT%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{REDUCTION}_ _{DAYS}_:</label>

                <div class='col-md-9'>
                    <input type=text name='DISCOUNT_DAYS' class='form-control' value='%DISCOUNT_DAYS%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{BONUS}_ _{SUM}_:</label>

                <div class='col-md-9'>
                    <input type=text name='BONUS_SUM' class='form-control' value='%BONUS_SUM%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for='BONUS_PERCENT'>_{BONUS_PERCENT}_:</label>

                <div class='col-md-9'>
                    <input type=text name='BONUS_PERCENT' id='BONUS_PERCENT' class='form-control' value='%BONUS_PERCENT%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='EXT_ACCOUNT'>_{EXTRA}_  _{ACCOUNT}_:</label>
                <div class='col-md-9'>
                    <input type=checkbox ID='EXT_ACCOUNT' name='EXT_ACCOUNT' value='1' %EXT_ACCOUNT%>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>

                <div class='col-md-9'>
                    <textarea cols=60 rows=3 ID=COMMENTS name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
                </div>
            </div>


        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type=submit name=%ACTION% class='form-control' value='%LNG_ACTION%'>
        </div>
    </div>

</form>
