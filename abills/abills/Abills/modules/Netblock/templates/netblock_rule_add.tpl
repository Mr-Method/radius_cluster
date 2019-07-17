<form class='form-horizontal' action='$SELF_URL' METHOD='POST' role='form'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='chg'   value='$FORM{chg}'>

    <fieldset>
        <div class='box box-theme box-form'>
            <div class='box-header with-border'><h4 class='box-title'>_{RULE}_</h4></div>
            <div class='box-body'>

                <div class='form-group'>
                    <label for='BLOCKTYPE' class='control-label col-sm-4'>_{BLOCKTYPE}_</label>
                    <div class='col-sm-8'>
                        %BLOCKTYPE_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label for='HASH' class='control-label col-sm-4'>_{VALUE}_</label>
                    <div class='col-sm-8'>
                        <input class='form-control' id='HASH' placeholder='_{VALUE}_' name='HASH' value='%HASH%'>
                    </div>
                </div>

            <div class='box-footer'>
                <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
            </div>
        </div>
    </fieldset>
</form>
