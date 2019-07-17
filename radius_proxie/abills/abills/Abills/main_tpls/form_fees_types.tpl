<div class='noprint'>
    <form action='$SELF_URL' name=user class='form form-horizontal'>
        <input type=hidden name=UID value='%UID%'>
        <input type=hidden name=index value='$index'>
        <input type=hidden name=subf value='$FORM{subf}'>
        <div class='box box-theme box-form'>
            <div class='box-header with-border'>
                <h4 class='box-title'>_{FEES}_ _{TYPES}_</h4>
            </div>
            <div class='box-body'>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='ID' >ID:</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' ID='ID' name='ID' value='%ID%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' ID='NAME' name='NAME' value='%NAME%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='SUM'>_{SUM}_:</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' ID='SUM' name='SUM' value='%SUM%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='DEFAULT_DESCRIBE'>_{DESCRIBE}_: _{USER}_:</label>
                    <div class='col-md-9'>
                        <input type=text class='form-control' ID='DEFAULT_DESCRIBE' name=DEFAULT_DESCRIBE value='%DEFAULT_DESCRIBE%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='TAX'>_{TAX}_:</label>
                    <div class='col-md-9'>
                        <input type=text class='form-control' name=TAX value='%TAX%' ID=TAX>
                    </div>
                </div>

            </div>
            <div class='box-footer'>
                <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
            </div>
        </div>

    </form>
</div>
