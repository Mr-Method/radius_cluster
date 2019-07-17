<form action='$SELF_URL' class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=$FORM{chg}>
    <input type=hidden name=TP_ID value=$FORM{TP_ID}>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            _{RULES}_
        </div>
        <div class='box-body'>
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
                <label class='control-label col-md-3'>_{PAYMENTS}_ _{TYPE}_:</label>

                <div class='col-md-9'>
                    %PAYMENT_TYPES_SEL%
                </div>
            </div>

            <div class='form-group bg-primary'>
                _{RESULT}_
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{REDUCTION}_ %:</label>
                <div class='col-md-9'>
                    <input type=text name='DISCOUNT' class='form-control' value='%DISCOUNT%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'> (_{DAYS}_):</label>

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
                <label class='control-label col-md-3'>_{BONUS_PERCENT}_:</label>

                <div class='col-md-9'>
                    <input type=text name='BONUS_PERCENT' class='form-control' value='%BONUS_PERCENT%'>
                </div>
            </div>
            <div class='checkbox'>
                <label>
                    <input type=checkbox name='EXT_ACCOUNT' value='1' %EXT_ACCOUNT%><strong>_{EXTRA}_
                    _{ACCOUNT}_</strong>
                </label>
            </div>

        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type=submit name=%ACTION% class='form-control' value='%LNG_ACTION%'>
        </div>
    </div>

</form>
