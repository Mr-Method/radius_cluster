<form name='form_setting' id='form_setting' method='post' class='form form-horizontal'>
    
    <input type='hidden' name='get_index' value='equipment_info'>
    <input type='hidden' name='TR_069' value='1'>
    <input type='hidden' name='onu_setting' value='1'>
    <input type='hidden' name='tr_069_id' value='%tr_069_id%'>
    <input type='hidden' name='header' value='2'>
    <input type='hidden' name='change' value='1'>
    <input type='hidden' name='info_pon_onu' value='%info_pon_onu%'>
    <input type='hidden' name='menu' value='%menu%'>
    <input type='hidden' name='sub_menu' value='%sub_menu%'>

    <div class='form-group'>
        <label class='control-label col-md-5' for='STATUS'>Status:</label>
        <div class='col-md-3 control-element'>
            %STATUS_SEL%
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='SERVER'>Server:</label>
        <div class='col-md-3 control-element'>
            %SERVER_FORM%
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='PORT'>Port:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='port' value='%port%' class='form-control' ID='port' data-check-for-pattern='^\\d+\$' maxlength='10'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='USER'>Username:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='voip_user' value='%voip_user%' class='form-control' ID='voip_user'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='PASS'>Password:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='voip_pass' value='%voip_pass%' class='form-control' ID='voip_pass'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='form-group'>
        <label class='control-label col-md-5' for='NUMBER'>Number:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='voip_number' value='%voip_number%' class='form-control' ID='voip_number' data-check-for-pattern='^\\d+\$'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>

    <div class='box-footer'>
        <input type='submit' name='change' value='_{CHANGE}_' ID='change' class='btn btn-primary'>
    </div>
</form>
<script>
    jQuery(document).ready(function(){
        pageInit('#form_setting');
        jQuery('#form_setting').submit(function(e) {
            if (!jQuery('#form_setting').find('.has-error').find('.form-control').attr( "id")) 
            {
                jQuery.ajax({
                    type: "POST",
                    url: "index.cgi",
                    data: jQuery('#form_setting').serialize(),
                    success: function(html)
                    {
                        jQuery('#ajax_content').html(html);
                    }
                });
            }
            e.preventDefault();
        });
    });
</script>
