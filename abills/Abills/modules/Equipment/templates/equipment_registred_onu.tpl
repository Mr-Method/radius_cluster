<FORM action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='VENDOR' value='%VENDOR%'>
    <input type='hidden' name='NAS_ID' value='%NAS_ID%'>
    <input type='hidden' name='TYPE' value='%TYPE%'>
    <input type='hidden' name='BRANCH' value='%BRANCH%'>
    <input type='hidden' name='visual' value='$FORM{visual}'>
    <input type='hidden' name='unregister_list' value='$FORM{unregister_list}'>
    <input type='hidden' name='reg_onu' value='$FORM{reg_onu}'>

    <div class='box box-theme box-form center-block'>
        <div class='box-header with-border'>
            <h3 class='box-title'> _{REGISTRATION}_ ONU</h3>
        </div>
        <div class='box-body'>

            <div class='form-group'>
                <label class='control-label col-md-5' for='LINE_PROFILE'>Line-Profile:</label>

                <div class='col-md-7 control-element'>
                    %LINE_PROFILE_SEL%
                </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for='SRV_PROFILE'>Srv-Profile:</label>

                <div class='col-md-7 control-element'>
                    %SRV_PROFILE_SEL%
                </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <div class='form-group' id='INTERNET_VLAN_SEL_DIV'>
                <label class='control-label col-md-5' for='INTERNET_VLAN'>INTERNET VLAN:</label>

                <div class='col-md-7 control-element'>
                    %INTERNET_VLAN_SEL%
                </div>
            </div>

            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <div class='form-group' id='TR_069_VLAN_SEL_DIV'>
                <label class='control-label col-md-5' for='TR_069_VLAN'>TR-069 VLAN:</label>

                <div class='col-md-7 control-element'>
                    %TR_069_VLAN_SEL%
                </div>
            </div>

            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <div class='form-group' id='IPTV_VLAN_SEL_DIV'>
                <label class='control-label col-md-5' for='IPTV_VLAN'>IPTV VLAN:</label>

                <div class='col-md-7 control-element'>
                    %IPTV_VLAN_SEL%
                </div>
            </div>

            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for=''>Branch:</label>

                <div class='col-md-7 control-element'>
                     %UC_TYPE% %BRANCH%
                </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for=''>Mac_Serial:</label>

                <div class='col-md-7 control-element'>
                     <input type='text' name='MAC_SERIAL' value='%MAC_SERIAL%' class='form-control' ID='%MAC_SERIAL%'/>
                </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for='COMMENTS'>_{DESCRIBE}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='ONU_DESC' value='' class='form-control' ID='ONU_DESC'/>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

    </div>
    <script type='text/javascript'>
        jQuery(document).ready(function () {
  
            var inet_vlan_sel_div = jQuery('div#INTERNET_VLAN_SEL_DIV');
            var inet_vlan_select  = jQuery('select#VLAN_ID');
            var tr_069_vlan_sel_div = jQuery('div#TR_069_VLAN_SEL_DIV');
            var tr_069_vlan_select  = jQuery('select#TR_069_VLAN_ID');
            var iptv_vlan_sel_div = jQuery('div#IPTV_VLAN_SEL_DIV');
            var iptv_vlan_select  = jQuery('select#IPTV_VLAN_ID');

            if (jQuery('select#LINE_PROFILE').val() === '%DEF_LINE_PROFILE%') {
                inet_vlan_sel_div.show();
                inet_vlan_select.attr('name', 'VLAN_ID');
                tr_069_vlan_sel_div.hide()
                tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
                iptv_vlan_sel_div.hide()
                iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
            }
            else if (jQuery('select#LINE_PROFILE').val() === '%TRIPLE_LINE_PROFILE%') {
                inet_vlan_sel_div.show();
                inet_vlan_select.attr('name', 'VLAN_ID');
                tr_069_vlan_sel_div.show();
                tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID');
                iptv_vlan_sel_div.show();
                iptv_vlan_select.attr('name', 'IPTV_VLAN_ID');
            }
            else {
                if ("%SHOW_VLANS%" == 1) {
                  inet_vlan_sel_div.show();
                }
                else {
                  inet_vlan_sel_div.hide();
                }

                inet_vlan_select.attr('name', 'VLAN_ID_HIDE');
                tr_069_vlan_sel_div.hide()
                tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
                iptv_vlan_sel_div.hide()
                iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
            }  

            jQuery('select#LINE_PROFILE').change(function () {
                if (jQuery('select#LINE_PROFILE').val() === '%DEF_LINE_PROFILE%') {
                    inet_vlan_sel_div.show();
                    inet_vlan_select.attr('name', 'VLAN_ID');
                    tr_069_vlan_sel_div.hide()
                    tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
                    iptv_vlan_sel_div.hide()
                    iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
                }
                else if (jQuery('select#LINE_PROFILE').val() === '%TRIPLE_LINE_PROFILE%') {
                    inet_vlan_sel_div.show();
                    inet_vlan_select.attr('name', 'VLAN_ID');
                    tr_069_vlan_sel_div.show();
                    tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID');
                    iptv_vlan_sel_div.show();
                    iptv_vlan_select.attr('name', 'IPTV_VLAN_ID');
                }
                else {
                    if ("%SHOW_VLANS%" == 1) {
                        inet_vlan_sel_div.show();
                    }
                    else {
                        inet_vlan_sel_div.hide();
                    }

                    inet_vlan_select.attr('name', 'VLAN_ID_HIDE');
                    tr_069_vlan_sel_div.hide()
                    tr_069_vlan_select.attr('name', 'TR_069_VLAN_ID_HIDE');
                    iptv_vlan_sel_div.hide()
                    iptv_vlan_select.attr('name', 'IPTV_VLAN_ID_HIDE');
                }
            });
        });
    </script>
</FORM>

