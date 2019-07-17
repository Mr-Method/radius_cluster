<script>
    jQuery(document).ready(function () {
        //find NAS_TYPE Select
        var typeSelect = jQuery('#NAS_TYPE');

        //find wiki-link button '?'
        var wikiLink = jQuery('#wiki-link');

        //get base url from wiki-link
        var wiki_NAS_Href = wikiLink.attr('href');

        //define handler for select
        //here we need to change href link regarding to selected option
        typeSelect.on('change', function () {

            wikiLink.fadeToggle();
            wikiLink.fadeToggle();
            var selected = typeSelect.val();
            wikiLink.attr('href', wiki_NAS_Href + ':' + selected + ':ru');
        });
    });
</script>

<form action=$SELF_URL METHOD=post name=FORM_NAS class='form-horizontal' role='form'>
    <fieldset>

        <input type=hidden name='index' value='62'>
        <input type=hidden name='NAS_ID' value='%NAS_ID%'>
        <div class='row'>

            <div class='col-md-6'>
                <div class='box box-theme box-form-big'>
                    <div class='box-header with-border'><h4 class='box-title'>_{NAS}_</h4></div>
                    <div class='box-body'>

                        <div class='form-group'>
                            <label for='NAS_IP' class='control-label col-md-3 required'>IP</label>

                            <div class='col-sm-9'>
                                <input type=text class='form-control ip-input' required id='NAS_IP'
                                       placeholder='%IP%' name='IP' value='%NAS_IP%'>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_NAME' class='control-label col-md-3 required'>_{NAME}_ (a-zA-Z0-9_)</label>

                            <div class='col-md-9'>
                                <input type='text' class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%'
                                       name='NAS_NAME'
                                       value='%NAS_NAME%' required pattern='^\\w*\$' maxlength='30'>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_TYPE' class='control-label col-md-3 required'>_{TYPE}_</label>

                            <div class='col-sm-9' id='NAS-type-wrapper'>
                                <div class='col-md-8'>
                                    %SEL_TYPE%
                                </div>

                                <div class='col-md-1'>
                                    <a class='btn btn-info' id='wiki-link' data-tooltip='_{GUIDE_WIKI_LINK}_'
                                       href='http://abills.net.ua/wiki/doku.php/abills:docs:nas'
                                       target='_blank'>?</a>
                                </div>

                                <div class='col-md-1'>
                                    %WINBOX%
                                </div>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_ALIVE' class='control-label col-sm-3'>Alive (sec.)</label>

                            <div class='col-sm-9'>
                                <input class='form-control' id='NAS_ALIVE' placeholder='%NAS_ALIVE%' name='NAS_ALIVE'
                                       value='%NAS_ALIVE%'>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_DISABLE' class='control-label col-sm-3'>_{DISABLE}_</label>

                            <div class='col-sm-5'>
                                <input type='checkbox' id='NAS_DISABLE' name='NAS_DISABLE' value='1' %NAS_DISABLE%>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label class='col-md-12 bg-primary'>_{MANAGE}_</label>
                        </div>

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
                        <div class='form-group'>
                            %ADDRESS_FORM%
                        </div>


                    </div>
                </div>

            </div>
            <div class='col-md-6'>
                <div class='form-group'>
                    <div class='box box-theme box-form-big'>
                        <div class='box-header with-border'>
                            <a data-toggle='collapse' data-parent='#accordion' href='#nas_misc'>_{EXTRA}_</a>
                        </div>
                        <div id='nas_misc' class='box-collapse box-body collapse in'>


                            %NAS_ID_FORM%
                            <div class='form-group'>
                                <label for='NAS_DESCRIBE' class='control-label col-md-4'>_{DESCRIBE}_</label>

                                <div class='col-md-8'>
                                    <input class='form-control' id='NAS_DESCRIBE' placeholder='%NAS_DESCRIBE%'
                                           name='NAS_DESCRIBE'
                                           value='%NAS_DESCRIBE%'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='NAS_IDENTIFIER'>Radius NAS-Identifier</label>

                                <div class='col-md-8'>
                                    <input id='NAS_IDENTIFIER' name='NAS_IDENTIFIER' value='%NAS_IDENTIFIER%'
                                           placeholder='%NAS_IDENTIFIER%' class='form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='MAC'>MAC</label>

                                <div class='col-md-8'>
                                    <input id='MAC' name='MAC' value='%MAC%' placeholder='%MAC%' class='form-control'
                                           type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='AUTH_TYPE'>_{AUTH}_</label>

                                <div class='col-md-9'>
                                    %SEL_AUTH_TYPE%
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='EXT_ACCT'>External Accounting</label>

                                <div class='col-md-9'>
                                    %NAS_EXT_ACCT%
                                </div>
                            </div>

                            <div class='form-group'>
                                <label for='NAS_GROUPS' class='control-label col-sm-3'>_{GROUP}_</label>

                                <div class='col-md-9'>
                                    %NAS_GROUPS_SEL%
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='col-md-12'>RADIUS _{PARAMS}_ (,)</label>

                                <div class='col-md-12'>
                        <textarea cols='40' rows='4' name='NAS_RAD_PAIRS'
                                  class='form-control'>%NAS_RAD_PAIRS%</textarea>
                                </div>
                            </div>

                            <div>

                                %EXTRA_PARAMS%

                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>

        <div class='row'>
            <div class='box-footer'>
                <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
            </div>
        </div>

    </fieldset>
</form>
