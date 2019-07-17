<form action='$SELF_URL' METHOD='POST' class='form-horizontal'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='chg' value='$FORM{chg}'>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4>_{EXCHANGE_RATE}_</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{EXCHANGE_RATE}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=VOIP_ER value='%VOIP_ER%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=VOIP_ER_NAME value='%VOIP_ER_NAME%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{CHANGED}_</label>
                <div class='col-md-9'>
                    %VOIP_ER_CHANGED%
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
        </div>
    </div>

</form>
