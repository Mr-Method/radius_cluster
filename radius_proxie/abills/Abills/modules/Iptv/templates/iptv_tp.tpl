<form action=$SELF_URL METHOD=POST class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=TP_ID value='%TP_ID%'>
    <div class='container-fluid'>
        <div class='row'>
            <div class='col-md-6'>
                <div class='box box-primary'>
                    <div class='box-header with-border'>
                        <a data-toggle='collapse' data-parent='#accordion' href='#_tp'>_{TARIF_PLAN}_</a>
                    </div>
                    <div id='_tp' class='box-body box-collapse collapse in'>
                        <div class='form-group'>
                            <label for='SERVICE' class='control-label col-md-3'>_{SERVICES}_:</label>
                            <div class='col-md-9'>
                                %SERVICE_SEL%
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='ID' class='control-label col-md-3'>#:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='ID' placeholder='%ID%' name=CHG_TP_ID value='%ID%'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='_{NAME}_:' class='control-label col-md-3'>_{NAME}_:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='NAME' placeholder='%NAME%' name='NAME' value='%NAME%'>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='ALERT' class='control-label col-md-3'>_{UPLIMIT}_:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='ALERT' placeholder='%ALERT%' name='ALERT'
                                       value='%ALERT%'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='GROUPS_SEL' class='control-label col-md-3'>_{GROUP}_:</label>
                            <div class='col-md-9'>
                                %GROUPS_SEL%
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class='col-md-6'>
                <div class='box box-primary'>
                    <div class='box-header with-border'>
                        <a data-toggle='collapse' data-parent='#accordion' href='#_abon' >_{ABON}_</a>
                    </div>

                    <div id='_abon' class='box-body box-collapse collapse out'>

                        <div class='form-group'>
                            <label for='DAY_FEE' class='control-label col-md-3'>_{DAY_FEE}_:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='DAY_FEE' placeholder='%DAY_FEE%' name='DAY_FEE'
                                       value='%DAY_FEE%'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='POSTPAID_DAY_FEE'>_{DAY_FEE}_
                                _{POSTPAID}_:</label>
                            <div class='col-md-9'>
                                <input id='POSTPAID_DAY_FEE' name='POSTPAID_DAY_FEE' value=1 %POSTPAID_DAY_FEE%
                                       type='checkbox'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='MONTH_FEE' class='control-label col-md-3'>_{MONTH_FEE}_:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='MONTH_FEE' placeholder='%MONTH_FEE%' name='MONTH_FEE'
                                       value='%MONTH_FEE%'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='POSTPAID_MONTH_FEE'>_{MONTH_FEE}_
                                _{POSTPAID}_:</label>
                            <div class='col-md-9'>
                                <input id='POSTPAID_MONTH_FEE' name='POSTPAID_MONTH_FEE' value='1' %POSTPAID_MONTH_FEE%
                                       type='checkbox'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
                            <div class='col-md-9'>
                                <input id='PERIOD_ALIGNMENT' name='PERIOD_ALIGNMENT' value='1' %PERIOD_ALIGNMENT%
                                       type='checkbox'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='ABON_DISTRIBUTION'>_{ABON_DISTRIBUTION}_:</label>
                            <div class='col-md-9'>
                                <input id='ABON_DISTRIBUTION' name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%
                                       type='checkbox'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='SMALL_DEPOSIT_ACTION_SEL'
                                   class='control-label col-md-3'>_{SMALL_DEPOSIT_ACTION}_:</label>
                            <div class='col-md-9'>%SMALL_DEPOSIT_ACTION_SEL%</div>
                        </div>

                    </div>
                </div>
            </div>
        </div>
        <div class='row'>
            <div class='col-md-6'>
                <div class='box box-primary'>
                    <div class='box-header with-border'>
                        <a data-toggle='collapse' data-parent='#accordion' href='#_other' >_{OTHER}_</a>
                    </div>

                    <div id='_other' class='box-body box-collapse collapse out'>


                        <div class='form-group'>
                            <label for='ACTIV_PRICE' class='control-label col-md-3'>_{ACTIVATE}_:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='ACTIV_PRICE' placeholder='%ACTIV_PRICE%'
                                       name='ACTIV_PRICE'
                                       value='%ACTIV_PRICE%'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='CHANGE_PRICE' class='control-label col-md-3'>_{CHANGE}_:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='CHANGE_PRICE' placeholder='%CHANGE_PRICE%'
                                       name='CHANGE_PRICE'
                                       value='%CHANGE_PRICE%'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='PAYMENT_TYPE_SEL' class='control-label col-md-3'>_{PAYMENT_TYPE}_:</label>
                            <div class='col-md-9'>
                                %PAYMENT_TYPE_SEL%
                            </div>
                        </div>

                        <div class='form-group'>
                            <label for='CREDIT' class='control-label col-md-3'>_{CREDIT}_:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT'
                                       value='%CREDIT%'>
                            </div>
                        </div>


                        <div class='form-group'>
                            <label for='FILTER_ID' class='control-label col-md-3'>Filter ID:</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='FILTER_ID' placeholder='%FILTER_ID%' name='FILTER_ID'
                                       value='%FILTER_ID%'>
                            </div>
                        </div>

                        <div class='form-group bg-info'>
                            <label for='AGE' class='control-label col-sm-3'>_{AGE}_ (_{DAYS}_):</label>
                            <div class='col-md-9'>
                                <input class='form-control' id='AGE' placeholder='%AGE%' name='AGE' value='%AGE%'>
                            </div>
                        </div>

                        <div class='form-group bg-info'>
                            <label for='NEXT_TARIF_PLAN_SEL' class='control-label col-sm-3'>_{TARIF_PLAN}_ _{NEXT_PERIOD}_:</label>
                            <div class='col-md-9'>
                                %NEXT_TARIF_PLAN_SEL%
                            </div>
                        </div>

                    </div>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
    </div>
</form>