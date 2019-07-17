<script language='JavaScript'>
  function autoReload() {
    document.equipment_info.NAS_ID.value = '$FORM{NAS_ID}';
    document.equipment_info.submit();
  }

  jQuery(function () {
    var base_wiki_link = 'http://abills.net.ua/wiki/doku.php/abills:docs:manual:admin:equipment:equipment_info:';
    var model_select   = jQuery('select#MODEL_ID');
    var type_select    = jQuery('select#TYPE_ID');
    var wiki_link      = jQuery('a#MODEL_ID_WIKI_LINK');

    var get_option = function (select, selected) {
      var option = select.find('option[value="' + selected + '"]');
      if (option.length) {
        return option;
      }
      return false
    };

    var update_wiki_link = function (type_name, vendor_name) {
      var formatted_vendor_name = vendor_name.toLowerCase();
      var formatted_type_name   = type_name.toLowerCase();
      wiki_link.attr('href', base_wiki_link + formatted_type_name + ':' + formatted_vendor_name);
    };

    var find_vendor_name = function () {
      var option = get_option(model_select, model_select.val());
      if (!option.length) return false;
      return option.data('vendor_name');
    };

    var find_type_name = function () {
      var option = get_option(type_select, type_select.val());
      if (!option.length) return false;
      return option.text();
    };

    var read_form_and_update_link = function () {
      var type_name   = find_type_name();
      var vendor_name = find_vendor_name();
      console.log(type_name, vendor_name);
      if (!type_name || !vendor_name) return false;
      update_wiki_link(type_name, vendor_name);
    };

    model_select.on('change', function () {
      read_form_and_update_link();
    });

    read_form_and_update_link();
  });
</script>


<form action='$SELF_URL' METHOD='post' name='equipment_info' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
  <input type='hidden' name='chg' value='$FORM{chg}'>

  <fieldset>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'>
        <h4>_{EQUIPMENT}_ _{INFO}_</h4>
        <!-- NAS_BTN -->
        <a title='info' href='$SELF_URL?get_index=form_nas&NAS_ID=%NAS_ID%&full=1'>
          <span class='glyphicon glyphicon-list-alt'></span>
          _{NAS}_
        </a>

        <!-- MAP_BTN -->
        %MAP_BTN%
      </div>
      <div class='box-body'>

        <div class='form-group'>
          <label for='NAS_NAME' class='control-label col-md-3'>ID: %NAS_ID%</label>
          <div class='col-sm-9'>
            <p class='form-control-static'>
              _{NAME}_: %NAS_NAME% (%NAS_IP%)
            </p>
          </div>
        </div>

        <div class='form-group'>
          <label for='SYSTEM_ID' class='control-label col-md-3'>System info</label>
          <div class='col-sm-9'>
            <input type=text class='form-control' id='SYSTEM_ID' placeholder='%SYSTEM_ID%' name='SYSTEM_ID'
                   value='%SYSTEM_ID%'>
          </div>
        </div>

        <div class='form-group'>
          <label for='TYPE_ID' class='control-label col-md-3'>_{TYPE}_</label>
          <div class='col-sm-9'>
            %TYPE_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label for='MODEL_ID' class='control-label col-md-3'>_{MODEL}_</label>
          <div class='col-sm-9'>
            %MODEL_SEL% %MANAGE_WEB%
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
            %FREE_PORTS%
          </div>
        </div>

        <div class='form-group'>
          <label for='STATUS' class='control-label col-md-3'>_{STATUS}_</label>
          <div class='col-sm-9'>
            %STATUS_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label for='START_UP_DATE' class='control-label col-md-3'>_{VERSION}_ SNMP:</label>
          <div class='col-sm-9'>
            %SNMP_VERSION_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label for='LAST_ACTIVITY' class='control-label col-md-3'>_{LAST_ACTIVITY}_</label>
          <div class='col-sm-9'>
            %LAST_ACTIVITY%
          </div>
        </div>

      </div>


      <div class='box box-theme box-big-form collapsed-box'>
        <div class='box-header with-border'><h3 class='box-title'>_{EXTRA}_</h3>
          <div class='box-tools pull-right'>
            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='box-body'>
          <div class='form-group'>
            <label for='REVISION' class='control-label col-md-3'>_{REVISION}_</label>
            <div class='col-sm-9'>
              <input type=text class='form-control' id='REVISION' placeholder='%REVISION%' name='REVISION'
                     value='%REVISION%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='FIRMWARE' class='control-label col-md-3'>_{FIRMWARE}_</label>
            <div class='col-sm-9'>
              <input type=text class='form-control' id='FIRMWARE' placeholder='%FIRMWARE%' name='FIRMWARE'
                     value='%FIRMWARE%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='SERIAL' class='control-label col-md-3'>_{SERIAL}_:</label>
            <div class='col-sm-9'>
              <input type=text class='form-control' id='SERIAL' placeholder='%SERIAL%' name='SERIAL' value='%SERIAL%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='START_UP_DATE' class='control-label col-md-3'>_{START_UP_DATE}_</label>
            <div class='col-sm-9'>
              <input type=text class='form-control' id='START_UP_DATE' placeholder='%START_UP_DATE%'
                     name='START_UP_DATE'
                     value='%START_UP_DATE%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='SERVER_VLAN' class='control-label col-md-3'>SERVER VLAN:</label>
            <div class='col-sm-9'>
              %VLAN_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label for='INTERNET_VLAN' class='control-label col-md-3'>INTERNET VLAN:</label>
            <div class='col-sm-9'>
              <input type=text class='form-control' id='INTERNET_VLAN' placeholder='%INTERNET_VLAN%' name='INTERNET_VLAN'
                     value='%INTERNET_VLAN%'>
            </div>
          </div>
          <div class='form-group'>
            <label for='TR_069_VLAN' class='control-label col-md-3'>TR-069 VLAN:</label>
            <div class='col-sm-9'>
             <input type=text class='form-control' id='TR_069_VLAN' placeholder='%TR_069_VLAN%' name='TR_069_VLAN'
                     value='%TR_069_VLAN%'>
            </div>
          </div>
          <div class='form-group'>
            <label for='IPTV_VLAN' class='control-label col-md-3'>IPTV VLAN:</label>
            <div class='col-sm-9'>
              <input type=text class='form-control' id='IPTV_VLAN' placeholder='%IPTV_VLAN%' name='IPTV_VLAN'
                     value='%IPTV_VLAN%'>
            </div>
          </div>
        </div>
      </div>

      <div class='box-body'>
        <div class='form-group'>
          <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
          <div class='col-md-9'>
            <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
          </div>
        </div>

      </div>

      <div class='box-footer'>
        <input type=submit name=get_info value='SNMP _{GET_INFO}_' class='btn btn-default'>
        <input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
      </div>
    </div>
  </fieldset>
</form>

%EX_INFO%
