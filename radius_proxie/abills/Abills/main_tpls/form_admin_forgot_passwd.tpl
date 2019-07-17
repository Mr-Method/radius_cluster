<div class='row'>
    <form action='$SELF_URL' method='post' name='reg_request_form' class='form form-horizontal'>

        <input type='hidden' name='forgot_passwd' value='1'>
<br>
        <div class='box box-primary box-form center-block'>
            <div class='box-header with-border text-right'><h4 class='box-title'>_{PASSWORD_RECOVERY}_</h4></div>

            <div class='box-body'>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='EMAIL'>E-mail</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' id='EMAIL' name='email'/>

                    </div>
                </div>

                %CAPTCHA%

            </div>

            <div class='box-footer'>
                <input type='submit' class='btn btn-primary btn-block' name='SEND' value='_{SEND}_'/>
            </div>

        </div>
    </form>
</div>