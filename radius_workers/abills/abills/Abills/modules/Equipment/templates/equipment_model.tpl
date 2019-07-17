<script src='/styles/default_adm/js/modules/equipment.js'></script>

<FORM action='$SELF_URL' METHOD='POST' class='form-horizontal' id='EQUIPMENT_MODEL_INFO_FORM'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='$FORM{chg}'>
  <input type='hidden' name='chg' value='$FORM{chg}'>
  <input type='hidden' name='HAS_EXTRA_PORTS' id='HAS_EXTRA_PORTS'>

  <fieldset>

    <div class='box box-theme box-form'>

      <div class='box-header with-border'><h4>_{EQUIPMENT}_ _{INFO}_</h4></div>

      <div class='box-body'>

        <div class='form-group'>
          <label class='control-label col-md-3' for='TYPE'>_{TYPE}_</label>

          <div class='col-md-9'>
            %TYPE_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='VENDOR'>_{VENDOR}_</label>

          <div class='col-md-9'>
            %VENDOR_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='MODEL_NAME'>_{MODEL}_</label>

          <div class='col-md-9'>
            <input type=text class='form-control' id='MODEL_NAME' placeholder='%MODEL_NAME%'
                   name='MODEL_NAME' value='%MODEL_NAME%'>
          </div>
        </div>

        <div class='form-group'>
          <label for='TEST_FIRMWARE' class='control-label col-md-3'>_{FIRMWARE}_</label>
          <div class='col-sm-9'>
            <input type=text class='form-control' id='TEST_FIRMWARE' placeholder='%TEST_FIRMWARE%' name='TEST_FIRMWARE'
                   value='%TEST_FIRMWARE%'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='SITE'>URL: </label>

          <div class='col-md-9'>
            <div class='input-group'>
              <input class='form-control' type='text' id='SITE' name='SITE' value='%SITE%'>
              <span class='input-group-addon'>
                                <a title='_{GO}_' href='%SITE%' target='%SITE%'>_{GO}_</a>
                            </span>
            </div>
          </div>
        </div>


        <div class='box box-default box-big-form collapsed-box'>
          <div class='box-header with-border'>
            <h3 class='box-title'>_{MANAGE}_</h3>
            <div class='box-tools pull-right'>
              <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='box-body'>

            <div class='form-group'>
              <label class='control-label col-md-3' for='MANAGE_WEB'>WEB: </label>

              <div class='col-md-9'>
                <input class='form-control' type='text' id='MANAGE_WEB' name='MANAGE_WEB' value='%MANAGE_WEB%'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-3' for='MANAGE_SSH'>telnet/ssh: </label>

              <div class='col-md-9'>
                <input class='form-control' type='text' name='MANAGE_SSH' id='MANAGE_SSH' value='%MANAGE_SSH%'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-3' for='SNMP_TPL'>_{SNMP_SURVEY}_: </label>

              <div class='col-md-9'>
                %SNMP_TPL_SEL%
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-3' for='SYS_OID'>SYSTEM_OID: </label>

              <div class='col-md-9'>
                <input class='form-control' type='text' id='SYS_OID' name='SYS_OID' value='%SYS_OID%'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_: </label>

              <div class='col-md-9'>
                        <textarea class='form-control' name='COMMENTS' id='COMMENTS' rows='6'
                                  cols='50'>%COMMENTS%</textarea>
              </div>
            </div>

          </div>
        </div>


        <div class='box box-default box-big-form collapsed-box'>
          <div class='box-header with-border'>
            <h3 class='box-title'>_{PORTS}_</h3>
            <div class='box-tools pull-right'>
              <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='box-body'>

            <div class='form-group'>
              <label class='control-label col-md-5' for='PORT_SHIFT'>_{PORT_SHIFT}_ SNMP</label>

              <div class='col-md-7'>
                <input class='form-control' type='number' min='0' id='PORT_SHIFT' name='PORT_SHIFT'
                       value='%PORT_SHIFT%'>
              </div>
            </div>


            <div class='form-group'>
              <label class='control-label col-md-5' for='PORTS'>_{COUNT}_</label>

              <div class='col-md-7'>
                <input class='form-control' type='number' min='1' id='PORTS' name='PORTS' value='%PORTS%'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-5' for='PORTS_TYPE'>_{PORTS}_ _{TYPE}_</label>

              <div class='col-md-7'>
                %PORTS_TYPE_SELECT%
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-5' for='ROWS_COUNT_id'>_{ROWS}_</label>

              <div class='col-md-7'>
                <input type='number' min='1' class='form-control' name='ROWS_COUNT' value='%ROWS_COUNT%'
                       id='ROWS_COUNT_id'/>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-5' for='BLOCK_SIZE_id'>_{IN_BLOCK}_</label>

              <div class='col-md-7'>
                <input type='number' min='1' class='form-control' name='BLOCK_SIZE' value='%BLOCK_SIZE%'
                       id='BLOCK_SIZE_id'/>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-5' for='PORT_NUMBERING'>_{PORT_NUMBERING}_</label>

              <div class='col-md-7'>
                %PORT_NUMBERING_SELECT%
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-5' for='FIRST_POSITION'>_{FIRST_PORT_POSITION}_</label>

              <div class='col-md-7'>
                %FIRST_POSITION_SELECT%
              </div>
            </div>

            <div id='extraPortWrapper'>

              <div id='templateWrapper'>
                <label class='control-label col-md-7' for='EXTRA_PORT'>_{EXTRA}_ _{PORT}_</label>
                <div class='col-md-5'>
                  %EXTRA_PORT1_SELECT%
                </div>
              </div>

            </div>
            <div class='form-group' id='extraPortControls' style='margin-right: 15px;'>
              <div class='text-right'>
                <div class='btn-group btn-group-xs'>
                  <button class='btn btn-xs btn-danger' id='removePortBtn'
                          data-tooltip='_{DEL}_ _{PORT}_'
                          data-tooltip-position='bottom'>
                    <span class='glyphicon glyphicon-remove'></span>
                  </button>
                  <button class='btn btn-xs btn-success' id='addPortBtn'
                          data-tooltip='_{ADD}_ _{PORT}_'>
                    <span class='glyphicon glyphicon-plus'></span>
                  </button>
                </div>
              </div>
            </div>

          </div>

        </div>
      </div>

      <div class='box-footer'>
        <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
      </div>
    </div>
  </fieldset>

  <div class='box box-theme' id='ports_preview'>
    <div class='box-body'>
      %PORTS_PREVIEW%
    </div>
  </div>


  %EX_INFO%

</FORM>


