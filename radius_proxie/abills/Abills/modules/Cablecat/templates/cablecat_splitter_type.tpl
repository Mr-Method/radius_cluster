<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{SPLITTER_TYPE}_</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_SPLITTER' id='form_CABLECAT_SPLITTER' method='post' class='form form-horizontal'>
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
        <label class='control-label col-md-3 required' for='IN_ID'>_{FIBERS_IN}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%FIBERS_IN%' required name='FIBERS_IN' id='IN_ID'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='OUT_ID'>_{FIBERS_OUT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%FIBERS_OUT%' required name='FIBERS_OUT' id='OUT_ID'/>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer text-center'>
    <input type='submit' form='form_CABLECAT_SPLITTER' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

