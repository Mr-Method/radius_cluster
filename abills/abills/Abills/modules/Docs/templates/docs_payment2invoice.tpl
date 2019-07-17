<form action='$SELF_URL' method='post' name='account_add'>
    <input type=hidden name=index value=$index>
    <input type=hidden name='UID' value='$FORM{UID}'>
    <input type=hidden name='sid' value='$FORM{sid}'>
    <input type=hidden name='UNINVOICED' value='1'>
    <div class='container-fluid'>
        <div class='box box-primary form-horizontal'>
            <div class='box-header with-border text-center'>_{PAYMENTS}_</div>
            <div class='box-body'>
                <div class='form-group col-xs-12' align='center'>
                    %PAYMENTS_LIST%
                </div>
                <div class='form-group'>
                    <label class='col-md-6 control-label text-center'>_{SUM}_</label>
                    <div class='col-md-6'><input type='text' name='SUM' value='%SUM%' size='8' class='form-control'/></div>
                </div>
                <div class='form-group'>
                    <label class='col-md-6 control-label text-center'>_{INVOICE}_</label>
                    <label class='col-md-6 control-label'>%INVOICE_SEL%</label>
                </div>
                <div class='form-group'>
                    <canvas class='col-xs-12' height='2'></canvas>
                </div>
            </div>
            <div class='box-footer'>
                <input class='btn btn-primary' type='submit' name='apply' value='_{APPLY}_'>
            </div>
        </div>
    </div>
</form>
