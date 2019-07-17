<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='%ID%'>
    <input type='hidden' name='SERVICE_ID' value='%SERVICE_ID%'>
    <input type='hidden' name='DEV_ID' value='%DEV_ID%'>
    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4>%DEVICE_ACTION%</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3 required' for="DEVICE_ID">_{DEVICE}_: </label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id="DEVICE_ID" name='DEVICE_ID' value='%DEVICE_ID%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{USER}_:</label>
                <div class='col-md-9'>
                    %USERS_LIST%
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3 required' for="IP_ACTIVITY">IP: </label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id="IP_ACTIVITY" name='IP_ACTIVITY' value='%IP_ACTIVITY%'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for="ENABLE">_{ENABLE}_ : </label>
                <div class='col-md-9'>
                    <input type='checkbox' class='plugin_checkbox' data-checked='%ENABLE%' id="ENABLE" name='ENABLE' value='1'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3' for="CODE">_{CODE}_: </label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' id="CODE" name='CODE' value='%CODE%'/>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
        </div>
    </div>
</form>
