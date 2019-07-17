
    <form action='$SELF_URL' method='post'>
        <input type='hidden' name='index' value='$index'>
        <input type='hidden' name='UID' value='$FORM{UID}'>
        <input type='hidden' name='sid' value='$sid'>

        <div class='box box-primary'>
            <div class='box-header'>
                <h3 class='box-title'>_{BONUS}_</h3>
            </div>
            <div class='box-body form form-horizontal'>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>%TARIF_SEL_NAME%:</label>

                    <div class='col-md-9'>
                        %TARIF_SEL%
                    </div>
                </div>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{STATUS}_:</label>

                    <div class='col-md-9'>
                        %STATE%
                    </div>
                </div>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{ACCEPT_RULES}_</label>

                    <div class='col-md-9'>
                        %ACCEPT_RULES%
                    </div>
                </div>
                <div class='box-footer'>
                    %ACTION%
                </div>
            </div>
        </div>

    </form>

