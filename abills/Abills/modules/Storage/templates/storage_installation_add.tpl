<form action=$SELF_URL ID=mapForm name=adress class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=%ID%>
    <!--
        <input type=hidden name=STREET_ID value='%STREET_ID%' ID='STREET_ID'>
        <input type=hidden name=LOCATION_ID value='%LOCATION_ID%' ID='LOCATION_ID'>
        <input type=hidden name=DISTRICT_ID value='%DISTRICT_ID%' ID='DISTRICT_ID'>
        -->

    <fieldset>
        <div class='box box-theme box-form' style='margin-left:auto; margin-right: auto;'>
            <div class='box-body form'>

                <legend>_{INSTALLATION}_</legend>

                <div id='address_form_source'>
                    %ADDRESS_FORM%
                </div>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{COUNT}_:</label>
                    <div class='col-md-8'><input class='form-control' name='COUNT' value='%COUNT%' type='text'></div>
                </div>

                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
                    <div class='col-md-8'><textarea class='form-control col-xs-12' name='COMMENTS'>%COMMENTS%</textarea>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{NAS}_:</label>
                    <div class='col-md-8'>%NAS%</div>
                </div>

                <div class='form-group'>
                    <label class='col-md-3 control-label' for='USER_LOGIN'>_{USER}_:</label>
                    <div class='col-md-9'>
                        <input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
                        <div class='col-md-10'>
                            <input type='text' class='form-control' value='%USER_LOGIN%' id='USER_LOGIN'
                                   readonly='readonly'/>
                        </div>
                        <div class='col-md-2'>
                            %USER_SEARCH%
                        </div>
                    </div>
                </div>
                <!--
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{USER}_:</label>
                    <div class='col-md-8'>%USER_SEL%</div>
                </div>
-->
            </div>
            <div class='box-footer'>
                <input type=submit name=install value=_{INSTALL}_ class='btn btn-primary'>
            </div>
        </div>

    </fieldset>
</form>
