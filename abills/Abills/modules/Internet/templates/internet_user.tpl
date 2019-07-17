<!-- STATUS COLOR -->
<style>
  .alert-%STATUS% {
  /*color : %STATUS_COLOR%;*/
    background-image: -webkit-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    background-image: -o-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    background-image: -webkit-gradient(linear, left top, left bottom, from(%STATUS_COLOR_GR_S%), to(%STATUS_COLOR_GR_F%));
    background-image: linear-gradient(to bottom, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='%STATUS_COLOR_GR_S%', endColorstr='%STATUS_COLOR_GR_F%', GradientType=0);
    background-repeat: repeat-x;
    border-color:%STATUS_COLOR%;
  }

  div.input-group > span.clear_button {
    cursor: pointer;
  }
</style>

<script>
  jQuery(function () {
    jQuery('span.clear_button').on('click', function () {

      // Clear all inputs in parent
      jQuery(this).parent().find('input').val('');

      // For Chosen select need more specific logic
      jQuery(this).parent().find('select').each(function () {
        renewChosenValue(jQuery(this), '')
      });

    });
  });
</script>

<form class='form-horizontal' action='$SELF_URL' method='post'>

  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='STATUS_DAYS' value='%STATUS_DAYS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='ID' value='%ID%'>

  <div  id='form_3' class='box box-theme box-big-form for_sort'>
    <div class='box-header with-border'>
      <h4 class='box-title'>_{INTERNET}_: %ID%</h4>
      <div class='box-tools pull-right'>
        <a href='$SELF_URL?get_index=internet_user&full=1&UID=%UID%&add_form=1' class='btn btn-xs btn-success'
           title='_{ADD_SERVICE}_'>_{ADD_SERVICE}_</a>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>
      <div class='row no-padding'>
        <div class='col-md-12 text-center'>
          %MENU%
        </div>
      </div>
      %ONLINE_TABLE%
      <div style='padding: 10px; padding-top : 0'>

        %PAYMENT_MESSAGE%

        %NEXT_FEES_WARNING%

        %LAST_LOGIN_MSG%

        %LOGIN_FORM%
        <div class='form-group'>
          <label class='control-label col-md-4 col-xs-4 pull-left' for='TP'>_{TARIF_PLAN}_</label>
          <div class='col-md-8 col-xs-8'>
            %TP_ADD%
            <div class='input-group' %TP_DISPLAY_NONE%>
              <span class='hidden-xs input-group-addon bg-primary'>%TP_NUM%</span>
              <input type=text name='GRP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs'
                     readonly>
              <input type=text name='GRP1' value='%TP_ID%:%TP_NAME%' ID='TP_NUM' class='form-control visible-xs'
                     readonly>
              <span class='input-group-addon'>%CHANGE_TP_BUTTON%</span>
              <span class='input-group-addon'><a
                href='$SELF_URL?index=$index&UID=$FORM{UID}&ID=%ID%&pay_to=1'
                class='$conf{CURRENCY_ICON}' title='_{PAY_TO}_'></a></span>
            </div>
          </div>
          <div class='col-md-12'>%PERSONAL_TP_MSG%</div>
        </div>

        <div class='form-group alert alert-%STATUS%'>
          <label class='control-label col-xs-4'>_{STATUS}_</label>
          <div class='col-xs-8'>
            <div class='input-group'>
              %STATUS_SEL%
              <span class='input-group-addon'>%SHEDULE%</span>
            </div>
            <div class='row text-center'>
              <strong>%STATUS_INFO%</strong>
            </div>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2'>_{STATIC}_ IP Pool</label>
          <div class='col-xs-8 col-md-4'>
            %STATIC_IP_POOL%

            <div class='row text-left' style='margin-left:1px;'>
              <strong>%CHOOSEN_STATIC_IP_POOL%</strong>
            </div>
          </div>
          <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
          <label class='control-label col-xs-4 col-md-2' for='IP'>_{STATIC}_ IP</label>
          <div class='col-xs-8 col-md-4'>
            <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control'
                   type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2' for='CID'>CID (;)</label>
          <div class='col-xs-8 col-md-4'>
            <input id='CID' name='CID' value='%CID%' placeholder='%CID%'
                   %CID_PATTERN% class='form-control' type='text'>
          </div>
          <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
          <label class='control-label col-xs-4 col-md-2' for='NETMASK'>MASK</label>
          <div class='col-xs-8 col-md-4 %NETMASK_COLOR%'>
            <input id='NETMASK' name='NETMASK' value='%NETMASK%' placeholder='%NETMASK%'
                   class='form-control' type='text'>
          </div>
        </div>
        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2' for='CPE_MAC'>CPE MAC</label>
          <div class='col-xs-8 col-md-4'>
            <input id='CPE_MAC' type='text' class='form-control' name='CPE_MAC' value='%CPE_MAC%'
                   %CID_PATTERN%>
          </div>
        </div>
      </div>
    </div>

    <div class='box %IPOE_SHOW_BOX%' style='margin-bottom: 0px; border-top-width: 1px;'>
      <div class='box-header with-border'>
        <h3 class='box-title'>IPoE / DHCP Option 82</h3>
        <div class='box-tools pull-right'>
          <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>

        <div class='form-group grpstyle'>
          <label class='control-label col-md-3' for='NAS_SEL'>_{NAS}_:</label>
          <div class='col-md-9'>
            %NAS_SEL%
          </div>
        </div>

        <div class='form-group grpstyle'>
          <label class='control-label col-md-3' for='PORT'>_{PORT}_:</label>
          <div class='col-md-6'>
            %PORT_SEL%
          </div>
        </div>

        <div class='form-group grpstyle'>
          <label class='control-label col-md-3' for='VLAN'>VLAN ID:</label>
          <div class='col-md-3'>
            <div class='input-group'>
              <input type='text' id='VLAN' name='VLAN' value='%VLAN%' placeholder='%VLAN%'
                     class='form-control'/>
              <span class='input-group-addon clear_button'><span class='glyphicon glyphicon-remove'></span></span>
            </div>
          </div>

          <label class='control-label col-md-2' for='SERVER_VLAN'>Server:</label>
          <div class='col-md-4'>
            <div class='input-group'>
              %VLAN_SEL%
              <span class='input-group-addon clear_button'><span class='glyphicon glyphicon-remove'></span></span>
            </div>
          </div>
        </div>

        <div class='form-group grpstyle'>
          <label class='control-label col-md-3' for='IPN_ACTIVATE'>_{ACTIVATE}_ IPN:</label>
          <div class='col-md-3'>
            <input id='IPN_ACTIVATE' name='IPN_ACTIVATE' value='1' %IPN_ACTIVATE% type='checkbox'>
            %IPN_ACTIVATE_BUTTON%
          </div>
        </div>

      </div>
    </div>


    <div class='box collapsed-box' style='margin-bottom: 0px; border-top-width: 1px;'>
      <div class='box-header with-border'>
        <h3 class='box-title'>_{EXTRA}_</h3>
        <div class='box-tools pull-right'>
          <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>
        <div class='form-group'>
          <label class='control-label col-xs-3 col-md-3'>IPv6 Pool:</label>
          <div class='col-xs-9 col-md-9'>
            %STATIC_IPV6_POOL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-3' for='IPV6'>_{STATIC}_ IPv6</label>
          <div class='col-xs-6 col-md-7'>
            <input id='IPV6' name='IPV6' value='%IPV6%' placeholder='%IPV6%' class='form-control'
                   type='text'>
          </div>

          <div class='col-xs-2 col-md-2'>
            %IPV6_MASK_SEL%
          </div>

        </div>

        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-3' for='IPV6_PREFIX'>_{PREFIX}_ IPv6</label>
          <div class='col-xs-6 col-md-7'>
            <input id='IPV6_PREFIX' name='IPV6_PREFIX' value='%IPV6_PREFIX%' placeholder='%IPV6_PREFIX%'
                   class='form-control'
                   type='text'>
          </div>

          <div class='col-xs-2 col-md-2'>
            %IPV6_PREFIX_MASK_SEL%
          </div>


        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='SPEED'>_{SPEED}_ (kb)</label>
          <div class='col-md-3'>
            <input id='SPEED' name='SPEED' value='%SPEED%' placeholder='%SPEED%'
                   class='form-control' type='text'>
          </div>

          <label class='control-label col-md-3' for='LOGINS'>_{SIMULTANEOUSLY}_</label>
          <div class='col-md-3'>
            <input id='LOGINS' type='text' name='LOGINS' value='%LOGINS%' class='form-control'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='SERVICE_ACTIVATE'>_{ACTIVATE}_</label>
          <div class='col-md-3 %EXPIRE_COLOR%'>
            <input id='SERVICE_ACTIVATE' name='SERVICE_ACTIVATE' value='%SERVICE_ACTIVATE%'
                   placeholder='%SERVICE_ACTIVATE%'
                   class='form-control datepicker' rel='tcal' type='text' %ACTIVATE_DISABLE%>
          </div>

          <label class='control-label col-md-3' for='SERVICE_EXPIRE'>_{EXPIRE}_</label>
          <div class='col-md-3 %EXPIRE_COLOR%'>
            <input id='SERVICE_EXPIRE' name='SERVICE_EXPIRE' value='%SERVICE_EXPIRE%' placeholder='%SERVICE_EXPIRE%'
                   class='form-control datepicker' rel='tcal' type='text' %EXPIRE_DISABLE%>
          </div>
        </div>


        <div class='form-group'>
          <label class='control-label col-md-3' for='FILTER_ID'>_{FILTERS}_</label>
          <div class='col-md-9'>
            <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                   class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='DETAIL_STATS'>_{DETAIL}_</label>
          <div class='col-md-9'>
            <input id='DETAIL_STATS' name='DETAIL_STATS' value='1' %DETAIL_STATS%
                   type='checkbox'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3 pull-left'>_{PERSONAL}_ _{TARIF_PLAN}_</label>
          <div class='col-md-9'>
            <input type='text' class='form-control' name='PERSONAL_TP' value='%PERSONAL_TP%' %PERSONAL_TP_DISABLE%>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3 pull-left'>ID</label>
          <div class='col-md-9'>
            <span class='label label-primary'>%ID%</span>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3'>$lang{MEMO}</label>
          <div class='col-md-3' align='left'>
            %REGISTRATION_INFO%
            %REGISTRATION_INFO_PDF%
            %REGISTRATION_INFO_SMS%
          </div>
        </div>
        %PASSWORD_FORM%
        %TURBO_MODE_FORM%
        <div class='form-group'>
          <label class='control-label col-md-3' for='DETAIL_STATS'>_{COMMENTS}_</label>
          <div class='col-md-9'>
            <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%INTERNET_COMMENT%</textarea>
          </div>
        </div>
      </div>
    </div>

    <div class='box-footer'>
      %BACK_BUTTON%
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
      %DEL_BUTTON%
    </div>
  </div>
</form>
