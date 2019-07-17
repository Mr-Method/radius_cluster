<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>Cams _{TARIF_PLAN}_</h4></div>
  <div class='box-body'>

    <form name='CAMS_USER_ADD' id='form_CAMS_USER_ADD' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control'  required name='NAME'  value='%NAME%'  id='NAME_id'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='STREAMS_COUNT_id'>_{STREAMS_COUNT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control'  required name='STREAMS_COUNT'  value='%STREAMS_COUNT%'  id='STREAMS_COUNT_id'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='ABON_TP'>Abon _{TARIF_PLAN}_</label>
        <div class='col-md-9'>
          %ABON_TP_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control'  rows='5'  name='COMMENTS'  id='COMMENTS_id' >%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_CAMS_USER_ADD' id='go' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>