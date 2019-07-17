<div class='col-xs-12 col-md-6'>
    <div class='box box-theme box-big-form'>
       <div class='box-header with-border'><h3 class='box-title'>_{INFO}_</h3>
       <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
      </div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-xs-3' for='COMPANY_NAME'>_{NAME}_:</label>
                <div class='col-xs-9'>
                    <textarea cols='40' rows='4' name='COMPANY_NAME' class='form-control'>%COMPANY_NAME%</textarea>
                </div>
            </div>

            <div class='form-group'>
                <label for='ADDRESS' class='control-label col-xs-3'>_{ADDRESS}_:</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='ADDRESS' placeholder='%ADDRESS%' name='ADDRESS' value='%ADDRESS%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='PHONE' class='control-label col-xs-3'>_{PHONE}_:</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='PHONE' placeholder='%PHONE%' name='PHONE' value='%PHONE%'>
                </div>
            </div>

            <div class='form-group'>
                <label for='REPRESENTATIVE' class='control-label col-xs-3'>_{REPRESENTATIVE}_:</label>
                <div class='col-xs-9'>
                    <input class='form-control' id='REPRESENTATIVE' placeholder='%REPRESENTATIVE%' name='REPRESENTATIVE'
                           value='%REPRESENTATIVE%'>
                </div>
            </div>
        </div>
            
            <div class="box collapsed-box" style='margin-bottom: 0px; border-top-width: 1px;'>
              <div class="box-header with-border">
                <h3 class="box-title">_{OTHER}_</h3>
                <div class="box-tools pull-right">
                  <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
                  </button>
                </div>
              </div>
              <div class="box-body">
                <div class='form-group'>
                    <label for='DEPOSIT' class='control-label col-xs-3'>_{DEPOSIT}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='DEPOSIT' placeholder='%DEPOSIT%' name='DEPOSIT' value='%DEPOSIT%'>
                    </div>
                </div>

                <div class='form-group'>
                    <label for='CREDIT' class='control-label col-xs-3'>_{CREDIT}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT' value='%CREDIT%'>
                    </div>
                </div>


                <div class='form-group' >
                    <label class='control-label col-xs-3' for='CREDIT_DATE'>_{DATE}_:</label>
                    <div class='col-xs-9'>
                        %CREDIT_DATE%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-xs-3' for='REGISTRATION'>_{REGISTRATION}_:</label>
                    <div class='col-xs-9'>
                        %REGISTRATION%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-xs-3' for='DISABLE'>_{DISABLE}_:</label>
                    <div class='col-xs-9'>
                        <input id='DISABLE' name='DISABLE' value='1' %DISABLE% type='checkbox'>
                    </div>
                </div>

              </div>
            </div>
            
            <div class="box collapsed-box" style='margin-bottom: 0px; border-top-width: 1px;'>
              <div class="box-header with-border">
                <h3 class="box-title">_{BANK}_</h3>
                <div class="box-tools pull-right">
                  <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
                  </button>
                </div>
              </div>
              <div class="box-body">

                <div class='form-group'>
                    <label for='VAT' class='control-label col-xs-3'>_{VAT}_ (%):</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='VAT' placeholder='%VAT%' name='VAT' value='%VAT%'>
                    </div>
                </div>

                <div class='form-group'>
                    <label for='TAX_NUMBER' class='control-label col-xs-3'>_{TAX_NUMBER}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='TAX_NUMBER' placeholder='%TAX_NUMBER%' name='TAX_NUMBER'
                               value='%TAX_NUMBER%'>
                    </div>
                </div>

                <div class='form-group'>
                    <label for='BANK_ACCOUNT' class='control-label col-xs-3'>_{ACCOUNT}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='BANK_ACCOUNT' placeholder='%BANK_ACCOUNT%' name='BANK_ACCOUNT'
                               value='%BANK_ACCOUNT%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label for='BANK_NAME' class='control-label col-xs-3'>_{BANK}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='BANK_NAME' placeholder='%BANK_NAME%' name='BANK_NAME'
                               value='%BANK_NAME%'>
                    </div>
                </div>

                <div class='form-group'>
                    <label for='COR_BANK_ACCOUNT' class='control-label col-xs-3'>_{COR_BANK_ACCOUNT}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='COR_BANK_ACCOUNT' placeholder='%COR_BANK_ACCOUNT%'
                               name='COR_BANK_ACCOUNT'
                               value='%COR_BANK_ACCOUNT%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label for='BANK_BIC' class='control-label col-xs-3'>_{BANK_BIC}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='BANK_BIC' placeholder='%BANK_BIC%' name='BANK_BIC'
                               value='%BANK_BIC%'>
                    </div>
                </div>
                <div class='form-group'>
                    <label for='CONTRACT_ID' class='control-label col-xs-3'>_{CONTRACT_ID}_:</label>
                    <div class='col-xs-9'>
                        <input class='form-control' id='CONTRACT_ID' placeholder='%CONTRACT_ID%' name='CONTRACT_ID'
                               value='%CONTRACT_ID%'>
                    </div>
                </div>
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
                  %INFO_FIELDS%
              </div>
          </div>
    </div>
</div>