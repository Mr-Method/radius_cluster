<form action='$SELF_URL' class='form-horizontal' method='post' ID=user name=user role='form' onsubmit=\"postthread('submitbutton');\">
    <input type=hidden name=UID value='%UID%'>
    <input type=hidden name=index value='$index'>
    <input type=hidden name=subf value='$FORM{subf}'>

    <fieldset>

        <div class='box box-theme box-form'>
            <div class='box-header with-border'><h4 class='box-title'>_{FEES}_</h4></div>
            <div class='box-body'>


                <div class='form-group'>
                    <label class='control-label col-md-3' for='SUM'>_{SUM}_:</label>
                    <div class='col-md-9'>
                        <input autofocus id='SUM' name='SUM' value='$FORM{SUM}' placeholder='$FORM{SUM}' class='form-control'
                               type='text'>
                    </div>
                </div>


                <div class='form-group'>
                    <label class='control-label col-md-3' for='DESCRIBE'>_{DESCRIBE}_:</label>
                    <div class='col-md-9'>
                        <input id='DESCRIBE' type='text' name='DESCRIBE' value='%DESCRIBE%' class='form-control'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='INNER_DESCRIBE'>_{INNER}_:</label>
                    <div class='col-md-9'>
                        <input id='INNER_DESCRIBE' type='text' name='INNER_DESCRIBE' value='%INNER_DESCRIBE%'
                               class='form-control'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='METHOD'>_{TYPE}_:</label>
                    <div class='col-md-9'>
                        %SEL_METHOD%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='CURRENCY'>_{CURRENCY}_ : _{EXCHANGE_RATE}_:</label>
                    <div class='col-md-9'>
                        %SEL_ER%
                    </div>
                </div>

                <div class='form-group'>
                    %PERIOD_FORM%
                </div>


                    %EXT_DATA_FORM%
                  </div>

                    %SHEDULE_FORM%


            </div>

            <div class='box-footer'>
                <input type=submit name='take' value='_{TAKE}_' class='btn btn-primary'>
            </div>


        </div>
    </fieldset>
</form>

