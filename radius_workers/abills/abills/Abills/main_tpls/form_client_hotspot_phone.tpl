<form action='$SELF_URL' METHOD='POST' class='form-inline'>
    <input type=hidden name='GUEST_ACCOUNT' value='1'>
    <input type=hidden name='mac' value='%mac%'>
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>

    <fieldset>
        <div class='box box-theme'>
            <div class='box-body'>
                <div class='form-group'>
                    <label class='control-label' for='PHONE'>_{PHONE}_</label>

                    <div class='input-group'>
                      <span class='input-group-addon' id='basic-addon1'>+%PHONE_PREFIX%</span>
                      <input type='text' id='PHONE' required='required' name='PHONE' class='form-control'/>
                    </div>
                        <input type='submit' id='get' name='get' value='_{REGISTRATION}_' class='btn btn-primary'/>
                </div>
            </div>
        </div>

    </fieldset>
</form>

