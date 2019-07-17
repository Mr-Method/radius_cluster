<script language='JavaScript'>
  function autoReload() {
    document.equipment_info.NAS_ID.value = '$FORM{NAS_ID}';
    document.equipment_info.submit();
  }
</script>


<form action='$SELF_URL' METHOD='post' name='equipment_info' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
  <input type='hidden' name='chg' value='$FORM{chg}'>

  <fieldset>
    <div class='box box-theme box-form'>
      <div class='box-body'>

        <legend>_{EQUIPMENT}_ _{INFO}_</legend>

        <div class='form-group'>
          <label for='NAS_NAME' class='control-label col-md-3'>ID: %NAS_ID%</label>
          <div class='col-sm-9'>
            _{NAME}_: %NAS_NAME% (%NAS_IP%) <a title='info' class='change rightAlignText'
                                               href='$SELF_URL?get_index=form_nas&NAS_ID=%NAS_ID%&full=1'>info</a>
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
          <label for='LAST_ACTIVITY' class='control-label col-md-3'>_{LAST_ACTIVITY}_</label>
          <div class='col-sm-9'>
            %LAST_ACTIVITY%
          </div>
        </div>

      </div>

        
        <div class='box box-theme box-big-form collapsed-box'>
    <div class='box-header with-border'><h3 class="box-title">_{EXTRA}_</h3>
      <div class="box-tools pull-right">
        <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
        </button>
      </div>
    </div>
         <div class='box-body'>
          <div class='form-group'>
           <label for='REVISION' class='control-label col-md-3'>_{REVISION}_</label>
            <div class='col-sm-9'>
             <input type=text class='form-control' id='REVISION' placeholder='%REVISION%' name='REVISION'value='%REVISION%'>
              </div>
           </div>

            <div class='form-group'>
             <label for='FIRMWARE' class='control-label col-md-3'>FIRMWARE</label>
              <div class='col-sm-9'>
               <input type=text class='form-control' id='FIRMWARE' placeholder='%FIRMWARE%' name='FIRMWARE' value='%FIRMWARE%'>
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
               <input type=text class='form-control' id='START_UP_DATE' placeholder='%START_UP_DATE%' name='START_UP_DATE'
                   value='%START_UP_DATE%'>
              </div>
             </div>

             <div class='form-group'>
                 <label for='START_UP_DATE' class='control-label col-md-3'>_{VERSION}_ SNMP:</label>
                 <div class='col-sm-9'>
                     %SNMP_VERSION_SEL%
                 </div>
             </div>


         </div>
         </div>

      <div class='box-body'>
        <div class='form-group'>
          <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
          <div class='col-md-9'>
            <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS% %DESCRIBE%</textarea>
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
