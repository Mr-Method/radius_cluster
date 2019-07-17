<form action=$SELF_URL METHOD=post name=FORM_NAS ID='FORM_NAS' class='form-horizontal' role='form'>
    <fieldset>

        <input type=hidden name='index' value='$index'>
        <input type=hidden name='add_form' value='1'>
        <input type=hidden name='NAS_ID' value='%NAS_ID%'>

        <div class='box box-theme box-big-form'>
            <div class='box-header with-border'><h4 class='box-title'>_{EQUIPMENT}_</h4></div>
            <div class='box-body'>

                <div class='form-group'>
                    <label for='NAS_IP' class='control-label col-md-4 required'>IP</label>

                    <div class='col-sm-8'>
                        <input type=text class='form-control ip-input' required id='NAS_IP'
                               placeholder='%IP%' name='IP' value='%NAS_IP%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label for='NAS_NAME' class='control-label col-md-4 required'>_{NAME}_ (a-zA-Z0-9_)</label>

                    <div class='col-md-8'>
                        <input type='text' class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%'
                               name='NAS_NAME'
                               value='%NAS_NAME%' required pattern='^\\w*\$' maxlength='30'>
                    </div>
                </div>

                <div class='form-group'>
                    <label for='NAS_DESCRIBE' class='control-label col-md-4'>_{DESCRIBE}_</label>

                    <div class='col-md-8'>
                        <input class='form-control' id='NAS_DESCRIBE' placeholder='%NAS_DESCRIBE%'
                               name='NAS_DESCRIBE'
                               value='%NAS_DESCRIBE%'>
                    </div>
                </div>

                <div class='form-group'>
                    <label for='NAS_DISABLE' class='control-label col-md-4'>_{DISABLE}_</label>

                    <div class='col-md-8'>
                        <input type='checkbox' id='NAS_DISABLE' name='NAS_DISABLE' value='1' %NAS_DISABLE%>
                    </div>
                </div>

                <div class='box box-default box-big-form collapsed-box'>
                    <div class='box-header with-border'>
                        <h3 class='box-title'>_{MANAGE}_</h3>
                        <div class='box-tools pull-right'>
                            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i
                                    class='fa fa-plus'></i>
                            </button>
                        </div>
                    </div>
                    <div class='box-body'>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='NAS_MNG_IP'>IP</label>
                            <div class='col-md-4'>
                                <input id='NAS_MNG_IP' name='NAS_MNG_IP' value='%NAS_MNG_IP%'
                                       placeholder='IP' class='form-control' type='text'>
                            </div>
                            <label class='control-label col-md-2' for='COA_PORT'>POD/COA</label>

                            <div class='col-md-3'>
                                <input id='COA_PORT' name='COA_PORT' value='%COA_PORT%'
                                       placeholder='PORT' class='form-control' type='text'>
                            </div>
                        </div>
                        <div class='form-group'>

                            <label class='control-label col-md-3' for='SSH_PORT'>SSH</label>

                            <div class='col-md-4'>
                                <input id='SSH_PORT' name='SSH_PORT' value='%SSH_PORT%'
                                       placeholder='PORT' class='form-control' type='text'>
                            </div>
                            <label class='control-label col-md-2' for='SNMP_PORT'>SNMP</label>

                            <div class='col-md-3'>
                                <input id='SNMP_PORT' name='SNMP_PORT' value='%SNMP_PORT%'
                                       placeholder='PORT' class='form-control' type='text'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='NAS_MNG_USER'>_{USER}_</label>

                            <div class='col-md-9'>
                                <div class='input-group'>
                                    <input id='NAS_MNG_USER' name='NAS_MNG_USER' value='%NAS_MNG_USER%'
                                           placeholder='%NAS_MNG_USER%'
                                           class='form-control' type='text'>
                                    <span class='input-group-addon'>
                    <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&create=1&ssh_key=1'
                       class='fa fa-key' target='_new' title='_{DOWNLOAD}_ SSH public key'></a>
                                    </span>
                                    <span class='input-group-addon'>
                    <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&download=1&ssh_key=1'
                       class='fa fa-download' target='_new' title='_{DOWNLOAD}_ SSH public key'></a>
                    </span>
                                </div>


                            </div>
                        </div>
                        <div class='form-group'>
                            <label class='control-label col-md-3' for='NAS_MNG_PASSWORD'>_{PASSWD}_ (PoD,RADIUS
                                Secret,SNMP)</label>

                            <div class='col-md-9'>
                                <input id='NAS_MNG_PASSWORD' name='NAS_MNG_PASSWORD' class='form-control'
                                       type='password'>
                            </div>
                        </div>
                    </div>
                </div>

                %ADDRESS_FORM%

                <div class='box box-default box-big-form collapsed-box'>
                    <div class='box-header with-border'>
                        <h3 class='box-title'>_{EXTRA}_</h3>
                        <div class='box-tools pull-right'>
                            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i
                                    class='fa fa-plus'></i>
                            </button>
                        </div>
                    </div>
                    <div class='box-body'>


                        <div id='nas_misc' class='box-collapse box-body collapse in'>
                            %NAS_ID_FORM%

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='MAC'>MAC</label>

                                <div class='col-md-8'>
                                    <input id='MAC' name='MAC' value='%MAC%' placeholder='%MAC%' class='form-control'
                                           type='text'>
                                </div>
                            </div>


                            <div class='form-group'>
                                <label for='NAS_GROUPS' class='control-label col-md-3'>_{GROUP}_</label>

                                <div class='col-md-9'>
                                    %NAS_GROUPS_SEL%
                                </div>
                            </div>
                            <div>
                                %EXTRA_PARAMS%
                            </div>
                        </div>

                    </div>
                </div>


                <div class='box-footer'>
                    <input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
                </div>
            </div>

        </div>

    </fieldset>
</form>
