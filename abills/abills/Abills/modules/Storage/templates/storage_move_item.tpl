<form method='post'  action='$SELF_URL'>

  <input type='hidden' name='' value=''>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='INCOMING_ARTICLE_ID' value='%INCOMING_ARTICLE_ID%'>
  <input type='hidden' name='SUPPLIER_ID' value='%SUPPLIER_ID%'>
  <input type='hidden' name='OLD_STORAGE_ID' value='%OLD_STORAGE_ID%'>


  <div class='box box-theme box-form form-horizontal'>

    <div class='box-header with-border'><b>_{TRANSFER_ITEM}_</b></div>

    <div class='box-body'>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{OUT_STORAGE}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='OLD_STORAGE_NAME' value='%OLD_STORAGE_NAME%' disabled></div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{IN_STORAGE}_</label>
        <div class='col-md-9'>%STORAGE_SELECT%</div>
      </div>

    </div>

    <div class='box-footer'>
      <input class='btn btn-primary' type='submit' name='move_confirm' value='_{APPLY}_'>
    </div>

  </div>

</form>
