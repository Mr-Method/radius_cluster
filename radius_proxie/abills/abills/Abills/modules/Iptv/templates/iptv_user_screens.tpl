<form action=$SELF_URL method=post class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=screen value='$FORM{screen}'>
    <input type=hidden name=UID value='$FORM{UID}'>
    <input type=hidden name=chg value='$FORM{chg}'>
    <input type=hidden name=MODULE value='Iptv'>
    <fieldset>
        <div class='box box-theme box-form'>
            <div class='box-header with-border'><h4 class='box-title'>_{SCREENS}_</h4></div>

            <div class='box-body'>

                <div class='form-group'>
                    %STORAGE_FORM%

                    <label class='control-label col-md-3' for='NUM'>_{NUM}_:</label>
                    <div class='col-md-9'>
                        %NUM% %NAME%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='PIN'>PIN:</label>
                    <div class='col-md-9'>
                        <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control' type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='CID'>MAC/CID:</label>
                    <div class='col-md-9'>
                        <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='SERIAL'>_{SERIAL}_:</label>
                    <div class='col-md-9'>
                        <input id='SERIAL' name='SERIAL' value='%SERIAL%' placeholder='%SERIAL%' class='form-control'
                               type='text'>
                    </div>
                </div>

                %FORM_DEVICE%

                %DEVICE_BINDING_CODE_FORM%

            </div>

            <div class='box-footer'>
                <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
                %DELETE%
            </div>


        </div>
    </fieldset>
</form>

