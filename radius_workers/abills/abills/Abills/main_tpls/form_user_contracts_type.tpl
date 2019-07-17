<form id='form_contract_type' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index' />
  <input type='hidden' name='chg' value='$FORM{chg}' />
  <div class='box box-theme box-form'>
    <div class='box-header with-border'>
      <h4 class='box-title'>_{TYPES}_ _{CONTRACTS}_</h4>
    </div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME'>_{NAME}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%NAME%'  name='NAME'  id='NAME'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='TEMPLATE'>_{TEMPLATE}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%TEMPLATE%'  name='TEMPLATE'  id='TEMPLATE'  />
        </div>
      </div>
    </div>
    <div class='box-footer text-center'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>