<FORM action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='$FORM{chg_pon_port}'>
    <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
    <input type='hidden' name='TYPE' value='$FORM{TYPE}'>
    <input type='hidden' name='visual' value='$FORM{visual}'>

    <div class='box box-theme box-form center-block'>
        <div class='box-header with-border'>
            <h3 class="box-title"> _{PORT}_:  %PON_TYPE% %BRANCH%</h3>
        </div>
        <div class='box-body'>

            <div class='form-group'>
                <label class='control-label col-md-5' for='VLAN'>VLAN:</label>

                <div class='col-md-7 control-element'>
                    %VLAN_SEL%
                </div>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for='COMMENTS'>_{DESCRIBE}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='BRANCH_DESC' value='%BRANCH_DESC%' class='form-control' ID='BRANCH_DESC'/>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

    </div>
</FORM>

