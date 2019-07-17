<form id='liqpay_form' method='post' action='https://www.liqpay.ua/api/checkout' accept-charset='utf-8'>
    %BODY%
    <input type='hidden' name='signature' value='%SIGN%'/>
    <input type='hidden' name='language' value='ru'/>
    <div class='container-fluid'>
        <div class='box box-primary'>
            <div class='box-header with-border text-center'>LiqPAY</div>
            <div class='box-body'>
                <div class='form-group'>
                    <img class='col-xs-8 col-xs-offset-2' src='https://www.liqpay.ua/static/img/logo.png' />
                </div>
                <div class='form-group'>
                    <a href='https://secure.privatbank.ua/help/verified_by_visa.html'>
                        <img class='col-md-4 col-md-offset-1 col-xs-10 col-xs-offset-1' src='/img/v-visa.gif' height='150'/>
                    </a>
                    <a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>
                        <img class='col-md-4 col-md-offset-2 col-xs-10 col-xs-offset-1' src='/img/mastercard-sc.gif' height='150'/>
                    </a>
                </div>
                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label'>_{ORDER}_</label>
                    <label class='font-weight-bold col-md-6 form-control-label'>$FORM{OPERATION_ID}</label>
                </div>
                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{BALANCE_RECHARCHE_SUM}_:</label>
                    <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>$FORM{SUM}</label>
                </div>
                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label'>_{COMMISSION}_:</label>
                    <label class='font-weight-bold col-md-6 form-control-label'>%COMMISSION_SUM%</label>
                </div>
                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label'>_{TOTAL}__{SUM}_:</label>
                    <label class='font-weight-bold col-md-6 form-control-label'>%TOTAL_SUM%</label>
                </div>
            </div>
            <div class='box-footer'>
                <input class='btn btn-primary' type='submit' value='_{PAY}_'>
            </div>
        </div>
    </div>
</form>