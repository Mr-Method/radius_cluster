<div class='noprint'>
    <form action='$SELF_URL' name=user class='form form-horizontal'>
        <input type=hidden name=UID value='%UID%'>
        <input type=hidden name=index value='$index'>
        <input type=hidden name=subf value='$FORM{subf}'>
        <div class='box box-theme box-form'>
            <div class='box-header with-border'>
                _{FEES}_ _{TYPES}_
            </div>
            <div class='box-body'>
                <div class='form-group'>
                    <label class='control-label col-md-3'>ID:</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' name='ID' value='%ID%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{NAME}_:</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' name='NAME' value='%NAME%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{SUM}_:</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' name='SUM' value='%SUM%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{DESCRIBE}_: _{USER}_:</label>
                    <div class='col-md-9'>
                        <input type=text class='form-control' name=DEFAULT_DESCRIBE value='%DEFAULT_DESCRIBE%'>
                    </div>
                </div>
            </div>
            <div class='box-footer'>
                <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
            </div>
        </div>

    </form>
</div>
