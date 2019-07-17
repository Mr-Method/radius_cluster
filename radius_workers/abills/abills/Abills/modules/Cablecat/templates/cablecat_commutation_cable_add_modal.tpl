<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{CABLES}_ : %WELL%</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_CABLES_ADD_MODAL' id='form_CABLECAT_CABLES_ADD_MODAL' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='entity' value='CABLE' />
      <input type='hidden' name='operation' value='ADD' />
      <input type='hidden' name='ID' value='%COMMUTATION_ID%' />
      <input type='hidden' name='COMMUTATION_ID' value='%COMMUTATION_ID%' />
      <input type='hidden' name='CONNECTER_ID' value='%CONNECTER_ID%' />

      %CABLES_CHECKBOXES%

    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_CABLECAT_CABLES_ADD_MODAL' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>