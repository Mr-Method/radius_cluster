<script src='/styles/default_adm/js/modules/netlist/ipv4network.js'></script>
<script>
    jQuery(function () {
        var ip_input = jQuery('input#IP_id');
        var mask_select = jQuery('select#BIT_MASK');
        var hosts_input = jQuery('input#COUNTS_id');

        var netmask_text = jQuery('p#netmask_text');
        var network_text = jQuery('p#network_text');
        var first_ip_text = jQuery('span#first_ip_text');
        var last_ip_text = jQuery('span#last_ip_text');

        var netmask_manual = jQuery('input#MANUAL_NETMASK');

        var helper_block = jQuery('div#network_params_hint');
        var helper_block_visible = false;

        // BIT MASK select uses internal 33..16 array to store masks
        var normalizeSelectedMaskToBits = function (selected_value) {
            return 33 - (selected_value || 1);
        };
        var denormalizeBitsToSelectedMask = function (bits) {
            return 33 - (bits || 32);
        };

        var network = null;

        var updateFormVisualization = function () {
            hosts_input.val(network.getRangeHostsCount());

            if (network === null || network.hosts_count < 0) {
                if (helper_block_visible) {
                    helper_block.hide();
                    helper_block_visible = false;
                }
                return false;
            }

            if (!helper_block_visible) {
                helper_block.show();
                helper_block_visible = true;
            }

            renewChosenValue(mask_select, denormalizeBitsToSelectedMask(network.getBits()));

            netmask_text.text(network.getNetmask());
            hosts_input.val(network.getRangeHostsCount());

            network_text.text(network.getAddress()
                + ' ( ' + network.getFirstAddress() + ' - ' + network.getLastAddress() + ' ) '
                + (network.getHostsCount() - 2)
            );

            first_ip_text.text(network.getFirstAddress(true)); // 'true' here means to count offset
            last_ip_text.text(network.getLastAddress(true));
        };

        var ip_changed = function () {
            var address = this.value;
            if (IPv4Network.prototype.isValidIPv4(address)) {
                network = new IPv4Network();
                network.setBits(normalizeSelectedMaskToBits(mask_select.val()) || 24);
                network.setAddress(address);
            }
            updateFormVisualization();
        };
        var mask_selected = function () {
            var bits = normalizeSelectedMaskToBits(this.value);

            var hosts_count = 0;
            if (bits >= 30) {
                hosts_count = ({
                    30: 2,
                    31: 1,
                    32: 0
                })[bits];
            }
            else {
                hosts_count = network.calculateHostsCountForBits(bits) - network.getOffset() - 2;
            }
            network.setHostsCount(hosts_count);

            updateFormVisualization();
        };
        var hosts_changed = function () {
            var in_value = this.value;
            network.setHostsCount(+in_value);
            updateFormVisualization();

            // Restore value
            hosts_input.val(in_value);
        };
        var init_listeners = function () {
            ip_input.on('input', ip_changed);
            mask_select.on('change', mask_selected);
            hosts_input.on('input', hosts_changed);
        };

        init_listeners();

        netmask_manual.on('click', function () {
            var checked = jQuery(this).prop('checked');

            if (checked) {
                // Disable calculation
                ip_input.off('input', ip_changed);
                mask_select.off('change', mask_selected);
                hosts_input.off('input', hosts_changed);

                helper_block.hide();
                helper_block_visible = false;
            }
            else {
                // Renew calculation
                init_listeners();
                updateFormVisualization();
            }

        });


        if (IPv4Network.prototype.isValidIPv4(ip_input.val()) && hosts_input.val()) {
            network = new IPv4Network();

            var hosts_count = +hosts_input.val();

            if (mask_select.val()) {
                netmask_manual.click();
            }
            else {
                // First assign to calculate minimal netmask
                network.setHostsCount(hosts_count);
                network.setAddress(ip_input.val());
                updateFormVisualization();

                // Second assign to renew value
                network.setHostsCount(hosts_count);
                updateFormVisualization();
            }

        }

        window['NETWORK_DEBUG'] = network;
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
                <label class='control-label col-md-4 required' for='NAME_id'>_{NAME}_</label>

                <div class='col-md-8'>
                    <input class='form-control' name='NAME' required value='%NAME%' id='NAME_id' maxlength='15'/>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 required' for='IP_id'>_{FIRST}_ IP</label>

                <div class='col-md-8'>
                    <input class='form-control ip-input' name='IP' value='%IP%' id='IP_id' maxlength='39' required/>
                </div>
            </div>

            <div class='form-group' id='ip-prefix'>
                <label class='control-label col-md-4'>_{MASK}_ (CIDR)</label>
                <div class='col-md-8'>
                    <div class='input-group'>
                        %BIT_MASK%
                        <span class='input-group-addon' data-tooltip='_{MANUAL}_'>
              <span class='glyphicon glyphicon-wrench'></span>
              <input type='checkbox' id='MANUAL_NETMASK'/>
            </span>
                    </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4 required' for='COUNTS_id'>_{COUNT}_</label>

                <div class='col-md-8'>
                    <input class='form-control' type='number' id='COUNTS_id' min='1' name='COUNTS' value='%COUNTS%'
                           maxlength='15'/>
                </div>
            </div>

            <div class='form-group text-muted' id='network_params_hint' style='display: none;'>
                <label class='control-label col-md-4'>_{NETWORK}_</label>
                <div class='col-md-8 text-left'>
                    <p class='form-control-static' id='network_text'></p>
                </div>
                <label class='control-label col-md-4'>_{RANGE}_</label>
                <div class='col-md-8 text-left'>
                    <p class='form-control-static'>
                        <span id='first_ip_text'></span> - <span id='last_ip_text'></span>
                    </p>
                </div>
                <label class='control-label col-md-4'>_{MASK}_</label>
                <div class='col-md-8 text-left'>
                    <p class='form-control-static' id='netmask_text'></p>
                </div>
            </div>

            <div class='form-group'>
                <div class='box box-theme box-form'>
                    <div class='box-header with-border' role='tab' id='pool_v6_heading'>
                        <h4 class='box-title'>IPv6</h4>
                        <div class='box-tools pull-right'>
                            <button type='button' class='btn btn-box-tool' data-toggle='collapse'
                                    data-parent='#accordion'
                                    href='#pool_v6' aria-expanded='false' aria-controls='pool_v6'><i
                                    class='fa fa-plus'></i>
                            </button>
                        </div>
                    </div>
                    <div id='pool_v6' class='box-collapse collapse' role='tabpanel'
                         aria-labelledby='pool_v6_heading'>
                        <div class='box-body'>
                            <div class='form-group'>
                                <label class='control-label col-md-4' for='IPV6_PREFIX_id'>_{PREFIX}_</label>
                                <div class='col-md-8'>
                                    <input class='form-control' name='IPV6_PREFIX' value='%IPV6_PREFIX%' id='IPV6_PREFIX_id'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3'>MASK:</label>

                                <div class='col-md-9'>
                                    %IPV6_BIT_MASK%
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='IPV6_TEMPLATE'>_{TEMPLATE}_:</label>

                                <div class='col-md-9'>
                                    <input class='form-control' name='IPV6_TEMPLATE' value='%IPV6_TEMPLATE%' id='IPV6_TEMPLATE'/>
                                </div>
                            </div>

                        </div>
                        <div class='box-footer'>
                            <h4 class='box-title'>Prefix delegated</h4>
                            <div class='form-group'>
                                <label class='control-label col-md-4' for='IPV6_PD_id'>_{PREFIX}_</label>
                                <div class='col-md-8'>
                                    <input class='form-control' name='IPV6_PD' value='%IPV6_PD%' id='IPV6_PD_id'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3'>MASK:</label>

                                <div class='col-md-9'>
                                    %IPV6_PD_BIT_MASK%
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='IPV6_PD_TEMPLATE'>_{TEMPLATE}_:</label>

                                <div class='col-md-9'>
                                    <input class='form-control' name='IPV6_PD_TEMPLATE' value='%IPV6_PD_TEMPLATE%' id='IPV6_PD_TEMPLATE'/>
                                </div>
                            </div>

                        </div>
                    </div>
                </div>
            </div>

            <div class='form-group'>
                <div class='box box-theme box-form'>
                    <div class='box-header with-border' role='tab' id='pool_advanced_heading'>
                        <h4 class='box-title'>_{EXTRA}_</h4>
                        <div class='box-tools pull-right'>
                            <button type='button' class='btn btn-box-tool' data-toggle='collapse'
                                    data-parent='#accordion'
                                    href='#pool_advanced' aria-expanded='false' aria-controls='pool_advanced'><i
                                    class='fa fa-plus'></i>
                            </button>
                        </div>
                    </div>
                    <div id='pool_advanced' class='box-collapse collapse' role='tabpanel'
                         aria-labelledby='pool_advanced_heading'>
                        <div class='box-body'>
                            <div class='form-group'>
                                <label class='control-label col-md-4' for='STATIC_id'>_{STATIC}_:</label>
                                <div class='col-md-8'>
                                    <input class='control-element' type='checkbox' name='STATIC' id='STATIC_id'
                                           value='1' %STATIC%/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='PRIORITY'>_{PRIORITY}_:</label>

                                <div class='col-md-8'>
                                    <input class='form-control' type='number' name='PRIORITY' value='%PRIORITY%'
                                           maxlength='5' id='PRIORITY'/>
                                </div>
                            </div>
                            <div class='form-group'>
                                <label class='control-label col-md-4' for='DNS'>DNS:</label>
                                <div class='col-md-8'>
                                    <input class='form-control ip-input' name='DNS' value='%DNS%' id='DNS'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='GATEWAY'>_{DEFAULT_GATEWAY}_:</label>
                                <div class='col-md-8'>
                                    <input class='form-control ip-input' id='GATEWAY' name='GATEWAY' value='%GATEWAY%'/>
                                </div>
                            </div>


                            <div class='form-group'>
                                <label class='control-label col-md-4' for='SPEED_id'>_{SPEED}_:</label>
                                <div class='col-md-8'>
                                    <input class='form-control' type='number' name='SPEED' id='SPEED_id' value='%SPEED%'
                                           maxlength='5'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4' for='VLAN_id'>Server VLAN:</label>
                                <div class='col-md-8'>
                                    <input class='form-control' type='number' name='VLAN' id='VLAN_id' value='%VLAN%'
                                           maxlength='5'/>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-4'>Next Pool:</label>

                                <div class='col-md-8'>
                                    %NEXT_POOL_ID_SEL%
                                </div>
                            </div>


                        </div>

                    </div>
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-4' for='GUEST_id'>_{GUEST}_:</label>

                <div class='col-md-8'>
                    <input type='checkbox' value='1' name='GUEST' id='GUEST_id' %GUEST%>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4' for='COMMENTS'>_{COMMENTS}_</label>
                <div class='col-md-8'>
                    <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='2'>%COMMENTS%</textarea>
                </div>
            </div>


        </div>

        <div class='box-footer'>
            <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
        </div>
    </div>

</form>
