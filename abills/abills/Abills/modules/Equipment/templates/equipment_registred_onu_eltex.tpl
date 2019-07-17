<FORM action='$SELF_URL' METHOD='GET' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
    <input type='hidden' name='TYPE' value='$FORM{TYPE}'>
    <input type='hidden' name='visual' value='$FORM{visual}'>
    <input type='hidden' name='unregister_list' value='$FORM{unregister_list}'>
    <input type='hidden' name='reg_onu' value='$FORM{reg_onu}'>

    <div class='box box-theme box-form center-block'>
        <div class='box-header with-border'>
            <h3 class="box-title"> _{REGISTRATION}_ ONU</h3>
        </div>
        <div class='box-body'>

            <div class='form-group'>
                <label class='control-label col-md-5' for='PON_TYPE'>PON _{TYPE}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='PON_TYPE' value='%PON_TYPE%' ID='PON_TYPE' readonly class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-5' for='VENDOR'>_{MODEL}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='MODEL_NAME' value='%MODEL_NAME%' ID='MODEL_NAME' readonly class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-5' for='BRANCH'>BRANCH:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='BRANCH' value='%BRANCH%' ID='BRANCH' readonly class='form-control'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-5' for='MAC'>MAC:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='MAC' value='%MAC%' ID='MAC' readonly class='form-control'>
                </div>
            </div>

            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <div class='form-group' id='VLAN_SEL_DIV'>
                <label class='control-label col-md-5' for='VLAN'>VLAN:</label>
                <div class='col-md-7 control-element'>
                    <input type='text' name='VLAN' value='%VLAN%' ID='VLAN' class='form-control'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-5' for='PORT'>_{PORT}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='PORT' value='%PORT%' ID='PORT' class='form-control'>
                </div>
            </div>

        </div>
        <div class='box-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

    </div>
</FORM>

