<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{CROSS}_</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_CROSS' id='form_CABLECAT_CROSS' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1' />
      <input type='hidden' name='ID' value='%ID%' />

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_ID'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%NAME%'  required name='NAME'  id='NAME_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='TYPE_ID'>_{TYPE}_</label>
        <div class='col-md-9'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='WELL_ID'>_{WELL}_</label>
        <div class='col-md-9'>
          %WELL_ID_SELECT%
        </div>
      </div>

      %OBJECT_INFO%

    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_CABLECAT_CROSS' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

%CROSS_LINKS_TABLE%