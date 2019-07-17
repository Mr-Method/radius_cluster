<div class='col-xs-12 col-md-6'>
    <div class='box box-theme'>
        <div class='box-body'>

<!--
            <div class='form-group'>
                <label class='col-md-3 control-label' for='GROUP'>_{GROUP}_</label>
                <div class='col-md-9'>
                    %GROUP_SEL%
                </div>
            </div>
-->
            %DV_LOGIN_FORM%

            <div class='form-group'>
                <label class='col-md-3 control-label' for='IP'>IP (!,>,<)</label>
                <div class='col-md-9'>
                  <div class="input-group">
                    <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control' type='text'>
                    <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                      <i class='fa fa-exclamation'></i>
                      <input type="checkbox" name='IP' data-input-disables=IP value='!'>
                    </span>
                  </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='CID'>CID/MAC</label>
                <div class='col-md-9'>
                  <div class="input-group">
                    <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
                    <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                      <i class='fa fa-exclamation'></i>
                      <input type="checkbox" name='CID' data-input-disables=CID value='!'>
                    </span>
                  </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='CPE_MAC'>CPE MAC</label>
                <div class='col-md-9'>
                  <div class="input-group">
                    <input id='CPE_MAC' name='CPE_MAC' value='%CPE_MAC%' placeholder='%CPE_MAC%' class='form-control' type='text'>
                    <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                      <i class='fa fa-exclamation'></i>
                      <input type="checkbox" name='CPE_MAC' data-input-disables=CPE_MAC value='!'>
                    </span>
                  </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='PORT'>_{PORT}_ (!,>,<)</label>
                <div class='col-md-9'>
                  <div class="input-group">
                    <input id='PORT' name='PORT' value='%PORT%' placeholder='%PORT%' class='form-control' type='text'>
                    <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                      <i class='fa fa-exclamation'></i>
                      <input type="checkbox" name='PORT' data-input-disables=PORT value='!'>
                    </span>
                  </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='VID'>VLAN _{USER}_:</label>
                <div class='col-md-3'>
                    <input id='VLAN' name='VLAN' value='%VLAN%' placeholder='%VLAN%' class='form-control' type='text'>
                </div>
                <label class='control-label col-md-3' for='SERVWER_VLAN'>Server:</label>
                <div class='col-md-3'>
                    <input id='SERVER_VLAN' name='SERVER_VLAN' value='%SERVER_VLAN%' placeholder='%SERVWER_VLAN%'
                           class='form-control' type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='NAS'>_{NAS}_/_{SWITCH}_:</label>
                <div class='col-md-6'>
                    %NAS_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label' for='TP_NUM'>_{TARIF_PLAN}_ (ID):</label>
                <div class='col-md-9'>
                    %TP_SEL%
                </div>
            </div>


            <div class='box box-default collapsed-box'>
                <div class='box-header with-border'>
                    <h3 class='box-title'>_{EXTRA}_</h3>
                    <div class='box-tools pull-right'>
                        <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
                        </button>
                    </div>
                </div>
                <div class='box-body'>

                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='PERSONAL_TP'>_{PERSONAL}_ _{TARIF_PLAN}_</label>
                        <div class='col-md-9'>
                          <div class="input-group">
                            <input id='PERSONAL_TP' name='PERSONAL_TP' value='%PERSONAL_TP%' placeholder='%PERSONAL_TP%'
                                   class='form-control' type='text'>
                            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                              <i class='fa fa-exclamation'></i>
                              <input type="checkbox" name='PERSONAL_TP' data-input-disables=PERSONAL_TP value='!'>
                            </span>
                          </div>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='STATUS'>_{STATUS}_</label>
                        <div class='col-md-9'>
                            %STATUS_SEL%
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='NETMASK'>NETMASK (!,>,<)</label>
                        <div class='col-md-9'>
                          <div class="input-group">
                            <input id='NETMASK' name='NETMASK' value='%NETMASK%' placeholder='%NETMASK%' class='form-control'
                                   type='text'>
                            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                              <i class='fa fa-exclamation'></i>
                              <input type="checkbox" name='NETMASK' data-input-disables=NETMASK value='!'>
                            </span>
                          </div>
                        </div>
                    </div>


                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='FILTER_ID'>FILTER ID (*)</label>
                        <div class='col-md-9'>
                          <div class="input-group">
                            <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                                   class='form-control' type='text'>
                            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                              <i class='fa fa-exclamation'></i>
                              <input type="checkbox" name='FILTER_ID' data-input-disables=FILTER_ID value='!'>
                            </span>
                          </div>
                        </div>
                    </div>


                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='INTERNET_ACTIVATE'>_{ACTIVATE}_</label>
                        <div class='col-md-9'>
                          <div class="input-group">
                            <input id='INTERNET_ACTIVATE' name='INTERNET_ACTIVATE' value='%INTERNET_ACTIVATE%'
                                   placeholder='%INTERNET_ACTIVATE%' class='form-control datepicker' type='text'>
                            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                              <i class='fa fa-exclamation'></i>
                              <input type="checkbox" name='INTERNET_ACTIVATE' data-input-disables=INTERNET_ACTIVATE value='!'>
                            </span>
                          </div>
                        </div>
                    </div>


                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='INTERNET_EXPIRE'>_{EXPIRE}_</label>
                        <div class='col-md-9'>
                          <div class="input-group">
                            <input id='INTERNET_EXPIRE' name='INTERNET_EXPIRE' value='%INTERNET_EXPIRE%'
                                   placeholder='%INTERNET_EXPIRE%' class='form-control datepicker' type='text'>
                            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                              <i class='fa fa-exclamation'></i>
                              <input type="checkbox" name='INTERNET_EXPIRE' data-input-disables=INTERNET_EXPIRE value='!'>
                            </span>
                          </div>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='SIMULTANEONSLY'>_{SIMULTANEOUSLY}_</label>
                        <div class='col-md-9'>
                          <div class="input-group">
                            <input id='SIMULTANEONSLY' name='SIMULTANEONSLY' value='%SIMULTANEONSLY%'
                                   placeholder='%SIMULTANEONSLY%' class='form-control' type='text'>
                            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                              <i class='fa fa-exclamation'></i>
                              <input type="checkbox" name='SIMULTANEONSLY' data-input-disables=SIMULTANEONSLY value='!'>
                            </span>
                          </div>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='SPEED'>_{SPEED}_ (!,>,<)</label>
                        <div class='col-md-9'>
                          <div class="input-group">
                            <input id='SPEED' name='SPEED' value='%SPEED%' placeholder='%SPEED%' class='form-control'
                                   type='text'>
                            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                              <i class='fa fa-exclamation'></i>
                              <input type="checkbox" name='SPEED' data-input-disables=SPEED value='!'>
                            </span>
                          </div>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='SERVICES'>_{SERVICES}_ (>,<)</label>
                        <div class='col-md-9'>
                            <input id='SERVICES' name='SERVICES' value='%SERVICES%' class='form-control'
                                   type='text'>
                        </div>
                    </div>


                    <div class='form-group'>
                        <label class='col-md-3 control-label' for='IP_POOL'>IP_POOL</label>
                        <div class='col-md-9'>
                            %IP_POOL_SEL%
                        </div>
                    </div>

                </div>
            </div>

        </div>
    </div>
</div>