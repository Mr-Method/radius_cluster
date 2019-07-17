<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>%PANEL_HEADING%</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_WELLS_TYPE' id='form_CABLECAT_WELLS_TYPE' method='post' class='form form-horizontal'>
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
        <label class='control-label col-md-3' for='ICON'>_{ICON}_</label>
        <div class='col-md-9'>
          %ICON_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_ID'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control col-md-9'  rows='5'  name='COMMENTS' id='COMMENTS_ID'>%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_CABLECAT_WELLS_TYPE' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

