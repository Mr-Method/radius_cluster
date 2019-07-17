<form action='$SELF_URL' METHOD='POST' class='form-horizontal'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='OP_SID' value='%OP_SID%'>
    <input type=hidden name='UID' value='$FORM{UID}'>
    <input type=hidden name='ID' value='$FORM{chg}'>

    <div class='box box-theme box-form-big'>
        <div class='box-header with-border'><h4>_{FEES}_</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{SUM}_:</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name='SUM' value='%SUM%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{DESCRIBE}_:</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=DESCRIBE value='%DESCRIBE%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{TYPE}_:</label>
                <div class='col-md-9'>
                    %TYPE_SEL%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{ACCOUNT}_:</label>
                <div class='col-md-9'>
                    %MACCOUNT_SEL%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{DATE}_:</label>
                <div class='col-md-9'>
                    %DATE_LIST%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{CLOSED}_:</label>
                <div class='col-md-9'>
                    <input type=checkbox name=STATUS value=1 %STATUS%>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>EXT ID:</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=EXT_ID value='%EXT_ID%'>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
        </div>
    </div>
</form>
