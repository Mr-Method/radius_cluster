<fieldset>
    <div class='box box-theme box-form'>
        <div class='box-body'>

            <legend>_{EQUIPMENT}_ _{SEARCH}_</legend>

            <div class='form-group'>
                <label for='SYSTEM_ID' class='control-label col-md-3'>System info</label>
                <div class='col-sm-9'>
                    <input type=text class='form-control' id='SYSTEM_ID' placeholder='%SYSTEM_ID%' name='SYSTEM_ID'
                           value='%SYSTEM_ID%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='MODEL_ID' class='control-label col-md-3'>_{MODEL}_</label>
                <div class='col-sm-9'>
                    %MODEL_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label for='FIRMWARE' class='control-label col-md-3'>FIRMWARE</label>
                <div class='col-sm-9'>
                    <input type=text class='form-control' id='FIRMWARE' placeholder='%FIRMWARE%' name='FIRMWARE'
                           value='%FIRMWARE%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='PORTS' class='control-label col-md-3'>_{PORTS}_</label>
                <div class='col-sm-9'>
                    <input type=text class='form-control' id='PORTS' placeholder='%PORTS%' name='PORTS' value='%PORTS%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='PORTS' class='control-label col-md-3'>_{FREE_PORTS}_</label>
                <div class='col-sm-9'>
                    <input type=text class='form-control' id='FREE_PORTS' placeholder='%FREE_PORTS%' name='FREE_PORTS'
                           value='%FREE_PORTS%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='SERIAL' class='control-label col-md-3'>_{SERIAL}_:</label>
                <div class='col-sm-9'>
                    <input type=text class='form-control' id='SERIAL' placeholder='%SERIAL%' name='SERIAL'
                           value='%SERIAL%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='START_UP_DATE' class='control-label col-md-3'>_{START_UP_DATE}_</label>
                <div class='col-sm-9'>
                    <input type=text class='form-control' id='START_UP_DATE' placeholder='%START_UP_DATE%'
                           name='START_UP_DATE' value='%START_UP_DATE%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='STATUS' class='control-label col-md-3'>_{STATUS}_</label>
                <div class='col-sm-9'>
                    %STATUS_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label for='LAST_ACTIVITY' class='control-label col-md-3'>_{LAST_ACTIVITY}_</label>
                <div class='col-sm-9'>
                    <input type=text class='form-control datepicker' id='LAST_ACTIVITY' placeholder='%LAST_ACTIVITY%'
                           name='LAST_ACTIVITY' value='%LAST_ACTIVITY%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <input type=text class='form-control' id='COMMENTS' placeholder='%COMMENTS%' name='COMMENTS'
                           value='%COMMENTS%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-sm-3' for='NAS_GROUPS'>_{GROUPS}_:</label>
                <div class='col-md-9'>
                    %NAS_GROUPS_SEL%
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-sm-3' for='USER_MAC'>_{USER}_ MAC:</label>
                <div class='col-md-9'>
                    <input type=text class='form-control' id='USER_MAC' placeholder='%USER_MAC%' name='USER_MAC'
                           value='%USER_MAC%'>
                </div>
            </div>
        </div>
    </div>
    <div class='box box-theme box-form'>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-sm-3' for='S_VLAN'>SVLAN:</label>
                <div class='col-md-9'>
                    <input type=text class='form-control' id='S_VLAN' placeholder='%S_VLAN%' name='S_VLAN'
                           value='%S_VLAN%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-sm-3' for='C_VLAN'>CVLAN:</label>
                <div class='col-md-9'>
                    <input type=text class='form-control' id='C_VLAN' placeholder='%C_VLAN%' name='C_VLAN'
                           value='%C_VLAN%'>
                </div>
            </div>
        </div>
    </div>
</fieldset>

