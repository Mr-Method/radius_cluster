<div class='col-xs-12 col-md-6' style='min-height: 450px;'>
    <div class='box box-theme inside-full-height content'>

        <div class='form-group'>
            <label class='control-label col-xs-4' for='FIO'>_{FIO}_ (*):</label>

            <div class='col-xs-8'>
              <div class="input-group">
                <input id='FIO' name='FIO' value='%FIO%' class='form-control' type='text'/>
                <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                  <i class='fa fa-exclamation'></i>
                  <input type="checkbox" name='FIO' data-input-disables=FIO value='!'>
                </span>
              </div>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='CONTRACT_ID'>_{CONTRACT_ID}_ (*):</label>

            <div class='col-xs-8'>
              <div class="input-group">
                <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' class='form-control' type='text'/>
                <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                  <i class='fa fa-exclamation'></i>
                  <input type="checkbox" name='CONTRACT_ID' data-input-disables=CONTRACT_ID value='!'>
                </span>
              </div>
            </div>
        </div>

        %CONTRACT_TYPE_FORM%

        <div class='form-group'>
            <label class='control-label col-xs-4' for='CONTRACT_DATE'>_{CONTRACT}_ _{DATE}_:</label>

            <div class='col-xs-8'>
                <input id='CONTRACT_DATE' name='CONTRACT_DATE' value='%CONTRACT_DATE%'
                       placeholder='%CONTRACT_DATE%'
                       class='form-control datepicker' type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='PHONE'>_{PHONE}_ (&gt;, &lt;, *):</label>

            <div class='col-xs-8'>
              <div class="input-group">
                <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control' type='text'/>
                <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                  <i class='fa fa-exclamation'></i>
                  <input type="checkbox" name='PHONE' data-input-disables=PHONE value='!'>
                </span>
              </div>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='COMMENTS'>_{COMMENTS}_ (*):</label>

            <div class='col-xs-8'>
                <input id='COMMENTS' name='COMMENTS' value='%COMMENTS%' placeholder='%COMMENTS%'
                       class='form-control' type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4'>_{GROUP}_:</label>

            <div class='col-xs-8'>%GROUPS_SEL%</div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='DEPOSIT'>_{DEPOSIT}_ (&gt;, &lt;):</label>

            <div class='col-xs-8'>
                <input id='DEPOSIT' name='DEPOSIT' value='%DEPOSIT%' placeholder='%DEPOSIT%'
                       class='form-control' type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='BILL_ID'>_{BILL}_:</label>

            <div class='col-xs-8'>
                <input id='BILL_ID' name='BILL_ID' value='%BILL_ID%' placeholder='%BILL_ID%'
                       class='form-control' type='text'/>
            </div>
        </div>

        %DOMAIN_FORM%

    </div>
</div>

<div class='col-xs-12 col-md-6'>
    <div class='box box-theme inside-full-height content'>


        <div class='form-group'>
            <label class='control-label col-xs-4' for='UID'>UID:</label>

            <div class='col-xs-8'>
                <input id='UID' name='UID' value='%UID%' type='text' class='form-control'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='EMAIL'>E-Mail (*):</label>

            <div class='col-xs-8'>
                <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control'
                       type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='REGISTRATION'>_{REGISTRATION}_ (&lt;&gt;):</label>

            <div class='col-xs-8'>
                <input id='REGISTRATION' name='REGISTRATION' value='%REGISTRATION%' placeholder='%REGISTRATION%'
                       class='form-control datepicker' type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='ACTIVATE'>_{ACTIVATE}_ (&lt;&gt;):</label>

            <div class='col-xs-8'>
                <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
                       class='form-control datepicker'
                       type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='EXPIRE'>_{EXPIRE}_ (&lt;&gt;):</label>

            <div class='col-xs-8'>
                <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                       class='form-control datepicker' type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='REDUCTION'>_{REDUCTION}_ (&lt;&gt;):</label>

            <div class='col-xs-8'>
                <input id='REDUCTION' name='REDUCTION' value='%REDUCTION%' placeholder='%REDUCTION%'
                       class='form-control'
                       type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='REDUCTION'>_{REDUCTION}_ _{DATE}_ (&lt;&gt;):</label>

            <div class='col-xs-8'>
                <input id='REDUCTIONDATE' name='REDUCTIONDATE' value='%REDUCTION_DATE%'
                       placeholder='%REDUCTION_DATE%'
                       class='form-control' type='text'/>
            </div>
        </div>
        <div class='form-group'>
            <label class='control-label col-xs-4' for='DISABLE'>_{DISABLE}_:</label>

            <div class='col-xs-8'>
                <input id='DISABLE' name='DISABLE' value='1' type='checkbox'/>
            </div>
        </div>


    </div>
</div>
<div class='col-xs-12 col-md-6' style='min-height: 380px;'>
        <div class='box box-theme inside-full-height content'>


            <legend>_{CREDIT}_</legend>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='CREDIT'>_{SUM}_ (&gt;, &lt;):</label>

                <div class='col-xs-8'>
                    <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%' class='form-control'
                           type='text'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='CREDIT_DATE'>_{DATE}_ ((&gt;, &lt;) YYYY-MM-DD):</label>

                <div class='col-xs-8'>
                    <input id='CREDIT_DATE' name='CREDIT_DATE' value='%CREDIT_DATE%' placeholder='%CREDIT_DATE%'
                           class='form-control datepicker' type='text'/>
                </div>
            </div>
            <legend>_{PAYMENTS}_</legend>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='PAYMENTS'>_{DATE}_ ((&gt;, &lt;) YYYY-MM-DD):</label>

                <div class='col-xs-8'>
                    <input id='PAYMENTS' name='PAYMENTS' value='%PAYMENTS%' placeholder='%PAYMENTS%'
                           class='form-control' type='text'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='PAYMENT_DAYS'>_{DAYS}_ (&gt;, &lt;):</label>

                <div class='col-xs-8'>
                    <input id='PAYMENT_DAYS' name='PAYMENT_DAYS' value='%PAYMENT_DAYS%' placeholder='%PAYMENT_DAYS%'
                           class='form-control'
                           type='text'/>
                </div>
            </div>
            <legend>_{FEES}_</legend>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='FEES'>_{DATE}_ ((&gt;, &lt;) YYYY-MM-DD):</label>

                <div class='col-xs-8'>
                    <input id='FEES' name='FEES' value='%FEES%' placeholder='%FEES%'
                           class='form-control' type='text'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='FEES_DAYS'>_{DAYS}_ (&gt;, &lt;):</label>

                <div class='col-xs-8'>
                    <input id='FEES_DAYS' name='FEES_DAYS' value='%FEES_DAYS%' placeholder='%FEES_DAYS%'
                           class='form-control'
                           type='text'/>
                </div>
            </div>

        </div>
    </div>

<div class='col-xs-12 col-md-6'>
        <div class='box box-theme inside-full-height content'>

            <legend>_{PASPORT}_</legend>

            <div class='form-group'>
                <label class='control-label col-xs-4' for='PASPORT_NUM'>_{NUM}_:</label>

                <div class='col-xs-8'>
                    <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%' placeholder='%PASPORT_NUM%'
                           class='form-control'
                           type='text'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='PASPORT_DATE'>_{DATE}_:</label>

                <div class='col-xs-8'>
                    <input id='PASPORT_DATE' name='PASPORT_DATE' value='%PASPORT_DATE%' placeholder='%PASPORT_DATE%'
                           class='form-control datepicker' type='text'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-xs-4' for='PASPORT_GRANT'>_{GRANT}_:</label>

                <div class='col-xs-8'>
                    <input id='PASPORT_GRANT' name='PASPORT_GRANT' value='%PASPORT_GRANT%'
                           placeholder='%PASPORT_GRANT%'
                           class='form-control' type='text'/>
                </div>
            </div>

        </div>
    </div>
<div class='col-xs-12 col-md-6'>
        <div class='box box-theme inside-full-height content'>
            <legend>_{INFO_FIELDS}_</legend>
            %INFO_FIELDS%

        </div>
    </div>


<!-- USERS -->



