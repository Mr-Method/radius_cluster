<form name='CABLECAT_CROSS_LINK' id='form_CABLECAT_CROSS_LINK' method='post' class='form form-horizontal'>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{CROSS}_ _{LINK}_ %SUBMIT_BTN_NAME%</h4></div>
    <div class='box-body'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='cross_link_operation' value='1'/>

      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <input type='hidden' name='CROSS_ID' value='%CROSS_ID%'/>
      <input type='hidden' name='CROSS_PORT' value='%CROSS_PORT%'/>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{CROSS}_</label>
        <div class='col-md-9'>
          <p class='form-control-static'>%CROSS_NAME%</p>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{PORT}_</label>
        <div class='col-md-9'>
          <p class='form-control-static'>%CROSS_PORT%</p>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='EQUIPMENT'>_{EQUIPMENT}_</label>
        <div class='col-md-9'>
          %EQUIPMENT_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='EQUIPMENT_PORT'>_{EQUIPMENT}_ _{PORT}_</label>
        <div class='col-md-9'>
          %EQUIPMENT_PORT_SELECT%
        </div>
      </div>

    </div>
    <div class='box-footer text-center'>
      <input type='submit' class='btn btn-primary' name='action' value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>

</form>
