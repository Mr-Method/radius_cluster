<script>
    /**
     * Controls inputting only prefix or ip adresses count.
     * Hides other input group when filled value
     *
     * Allows to drop current input value to show other input group
     */
    jQuery(function(){
        //cacheDOM
        var ipCountGroup = jQuery('#ip-count').parents('.form-group');
        var ipCountInput = ipCountGroup.find('input');
        var ipPrefixGroup = jQuery('#ip-prefix');
        var ipPrefixSelect = ipPrefixGroup.find('select');

        var ipCountDrop = jQuery('#ip-count-drop');
        var ipPrefixDrop = jQuery('#ip-prefix-drop');

        ipCountInput.on('input', function () {
            ipPrefixGroup.hide();
            ipPrefixSelect.val('');
        });
        ipCountDrop.on('click', function () {
            ipCountInput.val('');
            updateChosen();

            ipPrefixGroup.show();
        });
        ipPrefixSelect.on('change', function () {
            ipCountInput.val('');
            ipCountGroup.hide();
        });
        ipPrefixDrop.on('click', function () {
            ipPrefixSelect.val('');
            updateChosen();

            ipCountGroup.show();
        });
    })
</script>

<form action='$SELF_URL' METHOD='post' class='form form-horizontal'>
    <input type='hidden' name='index' value='%INDEX%'/>
    <input type='hidden' name='NAS_ID' value='%NAS_ID%'/>
    <input type='hidden' name='IP_POOLS' value='1'/>
    <input type='hidden' name='chg' value='$FORM{chg}'/>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            <div class='box-title'>
                <h4>IP Pool</h4>
            </div>
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-4 required'>_{NAME}_:</label>

                <div class='col-md-8'>
                    <input class='form-control' type='text' name='NAME' required value='%NAME%' maxlength='15'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 required'>_{FIRST}_ IP:</label>

                <div class='col-md-8'>
                    <input class='form-control ip-input' type='text' name='IP' value='%IP%' maxlength='39' required/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 required'>_{COUNT}_:</label>

                <div class='col-md-7'>
                    <input class='form-control' id='ip-count' type='text' name='COUNTS' value='%COUNTS%'
                           maxlength='15'/>
                </div>
                <div class='col-md-1'>
                    <a id='ip-count-drop'><span class='glyphicon glyphicon-remove control-element'></span></a>
                </div>
            </div>

            <div class='form-group' id='ip-prefix'>

                <label class='control-label col-md-4 required'>_{MASK}_:</label>

                <div class='col-md-7'>
                    %BIT_MASK%
                </div>
                <div class='col-md-1'>
                    <a id='ip-prefix-drop'><span class='glyphicon glyphicon-remove control-element'></span></a>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4' for='IPV6_PREFIX_id'>IPv6 _{PREFIX}_</label>
                <div class='col-md-8'>
                    <input type='text' class='form-control'  name='IPV6_PREFIX'  value='%IPV6_PREFIX%'  id='IPV6_PREFIX_id'  />
                </div>
            </div>

            <!--
                        <div class='form-group'>
                            <label class='control-label col-md-3'>IPv6 _{PREFIX}_:</label>

                            <div class='col-md-9'>
                                <input type='text' name='IPV6_PREFIX' value='%IPV6_PREFIX%'/>
                            </div>
                        </div>
            -->
            <!--
                        <div class='form-group'>
                            <label class='control-label col-md-3'>MASK:</label>

                            <div class='col-md-9'>
                                %IPV6_BIT_MASK%
                            </div>
                        </div>
            -->
            <div class='form-group'>
                <div class='box box-theme box-form'>
                    <div class='box-header with-border' role='tab' id='pool_advanced_heading'>
                        <h4 class='box-title'>_{EXTRA}_</h4>
                        <div class='box-tools pull-right'>
                            <button type='button' class='btn btn-box-tool' data-toggle='collapse' data-parent='#accordion'
                                    href='#pool_advanced' aria-expanded='false' aria-controls='pool_advanced'><i class='fa fa-plus'></i>
                            </button>
                        </div>
                    </div>
                    <div id='pool_advanced' class='box-collapse collapse' role='tabpanel'
                         aria-labelledby='pool_advanced_heading'>
                        <div class='box-body'>
                            <div class='form-group'>
                                <label class='control-label col-md-4'>_{STATIC}_:</label>

                                <div class='col-md-8'>
                                    <input class='control-element' type='checkbox' name='STATIC' value='1' %STATIC%/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='PRIORITY'>_{PRIORITY}_:</label>

                                <div class='col-md-8'>
                                    <input class='form-control' type='text' name='PRIORITY' value='%PRIORITY%'
                                           maxlength='5' id='PRIORITY'/>
                                </div>
                            </div>
                            <div class='form-group'>
                                <label class='control-label col-md-4' for='DNS'>DNS:</label>
                                <div class='col-md-8'>
                                    <input class='form-control' type='text' name='DNS' value='%DNS%' id='DNS'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='GATEWAY'>_{DEFAULT_GATEWAY}_:</label>
                                <div class='col-md-8'>
                                    <input class='form-control' type='text' id='GATEWAY' name='GATEWAY' value='%GATEWAY%'/>
                                </div>
                            </div>


                            <div class='form-group'>
                                <label class='control-label col-md-4'>_{SPEED}_:</label>
                                <div class='col-md-8'>
                                    <input class='form-control' type='text' name='SPEED' value='%SPEED%' maxlength='5'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4'>VLAN:</label>
                                <div class='col-md-8'>
                                    <input class='form-control' type='text' name='VLAN' value='%VLAN%' maxlength='5'/>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-4'>Next Pool:</label>

                <div class='col-md-8'>
                    %NEXT_POOL_ID_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4'>_{GUEST}_:</label>

                <div class='col-md-8'>
                    <input type='checkbox' value='1' name='GUEST' %GUEST%>
                </div>
            </div>

        </div>

        <div class='box-footer'>
            <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
        </div>
    </div>

</form>
