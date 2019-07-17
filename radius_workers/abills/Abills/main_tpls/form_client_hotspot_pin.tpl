<form action='$SELF_URL' METHOD='POST' class='form-inline' name=admin_form>
    <input type=hidden name='GUEST_ACCOUNT' value='1'>
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>
    <input type=hidden name='LOGIN' value='%LOGIN%'>

    <fieldset>
        <div class='box box-theme'>
            <div class='box-body'>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='PIN'>PIN:</label>
                    <div class='col-md-7'>
                        <input id='PIN' name='PIN' value='%PIN%' placeholder='xxxx'
                                class='form-control' type='text'>
                    </div>
                    <div class='col-md-2'>
                        <input type='submit' class='btn btn-primary' name='SEND' value='_{GO}_'>
                    </div>
                </div>
            </div>
        </div>

    </fieldset>
</form>
