<form action=$SELF_URL name='storage_form' method=POST class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='%ID%'>

        <div class='box box-theme box-form'>
            <div class='box-header with-border'>
                <div class='box-title'>
                    <h4>_{STORAGE}_</h4>
                </div>
            </div>
            <div class='box-body'>
                <div class='table'>
                    <div class='form-group'>
                        <label class='col-md-3 control-label'>_{NAME}_:</label>
                        <div class='col-md-9'><input class='form-control' name='NAME' type='text' value='%NAME%'/></div>
                    </div>
                    <div class='form-group'>
                        <label class='col-md-3 control-label'>_{COMMENTS}_</label>
                        <div class='col-md-9'><textarea name='COMMENTS'
                                                        class='form-control col-xs-12'>%COMMENTS%</textarea></div>
                    </div>
                </div>
            </div>
            <div class='box-footer'>
                <input class='btn btn-primary' type='submit' name=%ACTION% value=%ACTION_LNG%>
            </div>
        </div>
</form>