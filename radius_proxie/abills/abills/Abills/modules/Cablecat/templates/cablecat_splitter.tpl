<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{SPLITTER}_</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_SPLITTER' id='form_CABLECAT_SPLITTER' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>

      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='TYPE_ID'>_{SPLITTER_TYPE}_</label>
        <div class='col-md-9'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='WELL_ID'>_{WELL}_</label>
        <div class='col-md-9'>
          %WELL_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMUTATION_ID'>_{COMMUTATION}_</label>
        <div class='col-md-9'>
          %COMMUTATION_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='COLOR_SCHEME_ID_SELECT'>_{COLOR_SCHEME}_</label>
        <div class='col-md-9'>
          %COLOR_SCHEME_ID_SELECT%
        </div>
      </div>


      %OBJECT_INFO%

    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_CABLECAT_SPLITTER' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>