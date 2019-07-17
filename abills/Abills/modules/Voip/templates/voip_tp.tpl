<form action='$SELF_URL' METHOD='POST' class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=TP_ID value=%TP_ID%>


    <div class='row'>

        <div class='col-md-6'>
            <div class='box box-theme box-form'>
                <div class='box-header with-border'>
                    <a data-toggle='collapse' data-parent='#accordion' href='#_main'>_{MAIN}_</a>
                </div>
                <div id='_main' class='box-body box-collapse collapse in'>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>#</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=ID value='%ID%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{NAME}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=NAME value='%NAME%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{UPLIMIT}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=ALERT value='%ALERT%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{SIMULTANEOUSLY}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class='col-md-6'>
            <div class='box box-theme box-form'>
                <div class='box-header with-border'>
                    <a data-toggle='collapse' data-parent='#accordion' href='#_abon'>_{ABON}_</a>
                </div>
                <div id='_abon' class='box-body box-collapse collapse in'>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{DAY_FEE}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=DAY_FEE value='%DAY_FEE%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <div class='checkbox'>
                            <label>
                                <input type='checkbox' name=POSTPAID_DAY_FEE value=1 %POSTPAID_DAY_FEE%> _{DAY_FEE}_
                                _{POSTPAID}_
                            </label>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{MONTH_FEE}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=MONTH_FEE value='%MONTH_FEE%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <div class='checkbox'>
                            <label>
                                <input type='checkbox' name=POSTPAID_MONTH_FEE value=1 %POSTPAID_MONTH_FEE%>
                                _{MONTH_FEE}_ _{POSTPAID}_
                            </label>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class='row'>
        <div class='col-md-6'>
            <div class='box box-theme box-form'>
                <div class='box-header with-border'>
                    <a data-toggle='collapse' data-parent='#accordion' href='#_t3'>_{LIMIT}_</a>
                </div>
                <div id='_t3' class='box-body box-collapse collapse out'>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{HOUR_TARIF}_ (1 Hour):</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=TIME_TARIF value='%TIME_TARIF%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{DAY}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{WEEK}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{MONTH}_</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{ACTIVATE}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{CHANGE}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{CREDIT_TRESSHOLD}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class='col-md-6'>
            <div class='box box-theme box-form'>
                <div class='box-header with-border'>
                    <a data-toggle='collapse' data-parent='#accordion' href='#_other'>_{OTHER}_</a>
                </div>
                <div id='_other' class='box-body box-collapse collapse out'>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{MAX_SESSION_DURATION}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=MAX_SESSION_DURATION
                                   value='%MAX_SESSION_DURATION%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{AGE}_ (_{DAYS}_):</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=AGE value='%AGE%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{PAYMENT_TYPE}_:</label>
                        <div class='col-md-8'>
                            %PAYMENT_TYPE_SEL%
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{MIN_SESSION_COST}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type='text' name='MIN_SESSION_COST' value='%MIN_SESSION_COST%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>FILTER_ID:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=FILTER_ID value='%FILTER_ID%'>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>

    <div class='row'>
        <div class='col-md-6'>
            <div class='box box-theme box-form'>
                <div class='box-header with-border'>
                    <a data-toggle='collapse' data-parent='#accordion' href='#_t5'>_{TIME}_</a>
                </div>
                <div id='_t5' class='box-body box-collapse collapse out'>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{FREE_TIME}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=FREE_TIME value='%FREE_TIME%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{FIRST_PERIOD}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=FIRST_PERIOD value='%FIRST_PERIOD%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{FIRST_PERIOD_STEP}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=FIRST_PERIOD_STEP value='%FIRST_PERIOD_STEP%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{NEXT_PERIOD}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=NEXT_PERIOD value='%NEXT_PERIOD%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{NEXT_PERIOD_STEP}_:</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=NEXT_PERIOD_STEP value='%NEXT_PERIOD_STEP%'>
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-4 control-label'>_{TIME_DIVISION}_ (_{SECONDS}_ .):</label>
                        <div class='col-md-8'>
                            <input class='form-control' type=text name=TIME_DIVISION value='%TIME_DIVISION%'>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class='box-footer'>
        <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
    </div>


</form>