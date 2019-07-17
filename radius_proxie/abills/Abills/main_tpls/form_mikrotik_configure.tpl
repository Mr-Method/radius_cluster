<form method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <input type='hidden' name='NAS_ID' value='%NAS_ID%'/>
  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class='box-title'>%PANEL_HEADING%</h4></div>
    <div class='box-body'>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='RADIUS_IP_ID'>RADIUS IP</label>
        <div class='col-md-9'>
          <div class="col-md-5 no-padding">
            %RADIUS_IP_SELECT%
          </div>
          <div class="col-md-1 no-padding">
            <p class="form-control-static">
              $lang{OR}
            </p>
          </div>
          <div class="col-md-6 no-padding">
            <input type='text' class='form-control' value='%RADIUS_IP%' required name='RADIUS_IP'
                   id='RADIUS_IP_CUSTOM' data-input-disables='RADIUS_IP'/>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='DNS_ID'>DNS</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%DNS%' name='DNS' id='DNS_ID'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CLIENTS_POOL_ID'>IP Pool</label>
        <div class='col-md-9'>
          %IP_POOL_SELECT%
        </div>
      </div>

      <div class='checkbox text-center'>
        <label>
          <input type='checkbox' data-return='1' data-checked='%USE_NAT%' name='USE_NAT' id='USE_NAT_ID'/>
          <strong>NAT (Masquerade)</strong>
        </label>
      </div>

      <hr/>

      <!--extrea-->
      %EXTRA_INPUTS%
      <!--extrea-->


    </div>
    <div class='box-footer text-center'>
      <input type='submit' class='btn btn-primary' name='action' value='_{CONFIGURATION}_'>
    </div>
  </div>
</form>

