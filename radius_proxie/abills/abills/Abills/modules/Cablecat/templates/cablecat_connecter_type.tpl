<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{CONNECTER_TYPE}_</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_CONNECTER_TYPES' id='form_CABLECAT_CONNECTER_TYPES' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_ID'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CARTRIDGES_ID'>_{CARTRIDGES}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%CARTRIDGES%' name='CARTRIDGES' placeholder='1' id='CARTRIDGES_ID'/>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_CABLECAT_CONNECTER_TYPES' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>