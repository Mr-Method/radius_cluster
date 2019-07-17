<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='$index'>
  %MAIN_USER_TPL%
  <input type=hidden name=UID value='%UID%'>

  <!-- General panel -->
  <div id='form_2' class='box box-theme box-big-form for_sort'>
    <div class='box-header with-border'><h3 class='box-title'>_{INFO}_</h3>
      <div class='box-tools pull-right'>
        %EDIT_BUTTON%
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>
      <div class='col-md-2 col-xs-2 no-padding'>
        <img src=%PHOTO% class='img-responsive pull-left' alt=''>
      </div>
      <div class='col-md-10 col-xs-10'>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-user'></span></span>
          <input class='form-control' type='text' readonly value='%FIO%' placeholder='_{FIO}_'>
          <span class='input-group-addon'>
            <a href='$SELF_URL?UID=$FORM{UID}&get_index=msgs_admin&add_form=1&SEND_TYPE=1&header=1&full=1'
               class='fa fa-envelope'></a>
          </span>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-home'></span></span>
          <input class='form-control' type='text' readonly value='%ADDRESS_STR%' placeholder='_{ADDRESS}_'>
          <span class='input-group-addon'>%MAP_BTN%</span>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-earphone'></span></span>
          <input class='form-control' type='text' readonly value='%PHONE%' placeholder='_{PHONE}_'>
          <span class='input-group-addon'><a href='%CALLTO_HREF%' class='fa fa-list'></a></span>
        </div>
      </div>
      <div class='col-md-12 col-xs-12'>
        <div class='input-group' style='margin-top: 5px;'>
          <span class='input-group-addon'><span class='align-middle glyphicon glyphicon-exclamation-sign'></span></span>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='2' readonly>%COMMENTS%</textarea>
        </div>
      </div>
    </div>

    <!-- Pasport panel -->
      <div class="box collapsed-box" style='margin-bottom: 0px; border-top-width: 1px;'>
        <div class="box-header with-border">
          <h3 class="box-title">_{PASPORT}_</h3>
          <div class="box-tools pull-right">
            <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
            </button>
          </div>
        </div>
        <div class="box-body">
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='PASPORT_NUM' readonly>_{NUM}_</label>
            <div class='col-xs-8 col-sm-4'>
              <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                     placeholder='%PASPORT_NUM%'
                     class='form-control' type='text' readonly>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 10px"> </span>
            <label class='control-label col-xs-4 col-md-2' for='PASPORT_DATE'>_{DATE}_</label>
            <div class='col-xs-8 col-sm-4'>
              <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                     class='datepicker form-control' disabled>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='PASPORT_GRANT'>_{GRANT}_</label>
            <div class='col-xs-8 col-md-10'>
              <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT'
                        rows='2' readonly>%PASPORT_GRANT%</textarea>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='BIRTH_DATE'>_{BIRTH_DATE}_</label>
            <div class='col-xs-8 col-md-4'>
              <input class='form-control datepicker' id='BIRTH_DATE' name='BIRTH_DATE'
                     type='text' value='%BIRTH_DATE%' disabled>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='REG_ADDRESS'>_{REG_ADDRESS}_</label>
            <div class='col-xs-8 col-md-10'>
              <textarea class='form-control' id='REG_ADDRESS' name='REG_ADDRESS'
                        rows='2' readonly>%REG_ADDRESS%</textarea>
            </div>
          </div>
        </div>
      </div>

    <div class="box collapsed-box" style='margin-bottom: 0px; border-top-width: 1px;'>
      <div class="box-header with-border">
        <h3 class="box-title">_{CONTRACT}_</h3>
        <div class="box-tools pull-right">
          <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
          </button>
        </div>
      </div>
      <div class="box-body">
        %ACCEPT_RULES_FORM%
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='CONTRACT_ID'>_{CONTRACT_ID}_
              %CONTRACT_SUFIX%</label>
            <div class='col-xs-8 col-md-4'>
              <div class='input-group'>
                <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%'
                       placeholder='%CONTRACT_ID%' class='form-control' type='text'>
                <span class='input-group-addon'>%PRINT_CONTRACT%</span>
                <span class='input-group-addon'><a
                    href='$SELF_URL?qindex=15&UID=$FORM{UID}&PRINT_CONTRACT=%CONTRACT_ID%&SEND_EMAIL=1&pdf=1'
                    class='glyphicon glyphicon-envelope' target=_new>
                                        </a></span>
              </div>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <label class='control-label col-xs-4 col-md-2' for='CONTRACT_DATE'>_{DATE}_</label>
            <div class='col-xs-8 col-md-4'>
              <input id='CONTRACT_DATE' type='text' name='CONTRACT_DATE'
                     value='%CONTRACT_DATE%' class='datepicker form-control'>
            </div>
          </div>
          %CONTRACT_TYPE%
        %CONTRACTS_TABLE%
      </div>
    </div>

    <div class="box collapsed-box" style='margin-bottom: 0px; border-top-width: 1px;'>
      <div class="box-header with-border">
        <h3 class="box-title">_{EXTRA_ABBR}_. _{FIELDS}_</h3>
        <div class="box-tools pull-right">
          <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
          </button>
        </div>
      </div>
      <div class="box-body">
        <fieldset id='info_fields'>
          %INFO_FIELDS%
        </fieldset>
      </div>
    </div>
  </div>
</form>

<script>
  'use strict';
  jQuery(function(){
    jQuery('#info_fields').find('select').prop('disabled', true).trigger('chosen:updated');
  })
</script>
<style>
  #info_fields div.chosen-disabled {
    opacity: 1 !important;
  }
  #info_fields .chosen-disabled a.chosen-single {
    cursor: not-allowed;
  }
</style>
