<form action='$SELF_URL' METHOD='post' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%GID%'/>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            _{CHANGE}_
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3'>GID:</label>

                <div class='col-md-9'>
                    <input class='form-control' type='text' name='GID' value='%GID%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{NAME}_:</label>

                <div class='col-md-9'>
                    <input class='form-control' type='text' name='NAME' value='%NAME%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-9' for='USER_CHG_TP'>_{USER_CHG_TP}_:</label>

                <div class='col-md-3 text-left'>
                    <input class='form-checkbox' type='checkbox' name='USER_CHG_TP' id='USER_CHG_TP' value='1' %USER_CHG_TP% >
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
        </div>
    </div>
</form>