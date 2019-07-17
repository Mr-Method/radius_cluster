<form action=$SELF_URL method=post>
    <input type=hidden name=index value=$index>
    <input type=hidden name=UID value='$FORM{UID}'>
    <input type=hidden name=sid value='$sid'>

    <div class='box box-primary'>
        <div class='box-header with-border'>
            <h3 class='box-title'> _{BONUS}_ _{BALANCE_RECHARCHE}_</h3>
        </div>
        <div class='box-body form form-horizontal'>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{SUM}_:</label>

                <div class='col-md-9'>
                    <input type='text' class='form-control' name='COST' value='%COST%'>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type=submit name=transfer value='_{BALANCE_RECHARCHE}_'>
        </div>
    </div>
</form>

