<div class='row'>
    <form action='$SELF_URL' method='post' name='reg_request_form' class='form form-horizontal'>

        <input type='hidden' name='FORGOT_PASSWD' value='1'>

        <div class='box box-theme box-form center-block'>
            <div class='box-header with-border'><h4 class='box-title'>_{PASSWORD_RECOVERY}_</h4></div>

            <div class='box-body'>

                <div class='form-group'>

                    <label class='control-label col-md-5' for='LOGIN'>_{LOGIN}_</label>
                    <div class='col-md-7'>
                        <input type='text' class='form-control' id='LOGIN' name='LOGIN' value='%LOGIN%'
                               data-input-disables='UID'
                        />
                    </div>
                </div>

                <div class='form-group'>

                    <label class='control-label col-md-5' for='UID'>_{CONTRACT}_№</label>
                    <div class='col-md-7'>
                        <input type='text' class='form-control' id='UID' name='UID' value='%UID%'
                               data-input-disables='LOGIN'
                        />
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label required col-md-5' for='EMAIL'>E-mail</label>
                    <div class='col-md-7'>
                        <input type='text' class='form-control' id='EMAIL' required='required' name='EMAIL'
                               value='%EMAIL%'
                               data-input-disables='PHONE,SEND_SMS'
                        />

                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label required col-md-5' for='PHONE'>_{CELL_PHONE}_</label>
                    <div class='col-md-7'>
                        <input type='text' class='form-control' id='PHONE' required='required' name='PHONE'
                               value='%PHONE%'
                               data-input-disables='EMAIL'
                        />
                    </div>
                </div>

                %EXTRA_PARAMS%

                <hr/>

                %CAPTCHA%

            </div>

            <div class='box-footer text-right'>
                <input type='submit' class='btn btn-primary' name='SEND' value='_{SEND}_'/>
            </div>

        </div>
    </form>
</div>