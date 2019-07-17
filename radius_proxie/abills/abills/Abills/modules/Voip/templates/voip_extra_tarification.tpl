<form action='$SELF_URL' class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=$FORM{chg}>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>_{EXTRA_TARIFICATION}_</div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='col-md-3 control-label'>ID</label>
                <div class='col-md-9'>
                    %ID%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type=text name=NAME value='%NAME%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{PREPAID}_ _{TIME}_</label>
                <div class='col-md-9'>
                    <input class='form-control' input type=text name=PREPAID_TIME value='%PREPAID_TIME%'>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
        </div>
    </div>

</form>