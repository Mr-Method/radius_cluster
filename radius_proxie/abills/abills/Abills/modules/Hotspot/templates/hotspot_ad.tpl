<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{ADVERTISE}_</h4></div>
  <div class='box-body'>

    <form name='HOTSPOT_ADVERT' id='form_HOTSPOT_ADVERT' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='URL_id'>URL</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='URL' id='URL_id'/>
        </div>
      </div>

<!--      <div class='form-group'>
        <label class='control-label col-md-3' for='NAS_ID_id'>_{NAS}_</label>
        <div class='col-md-9'>
          %NAS_ID_SELECT%
        </div>
      </div>-->

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'></textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_HOTSPOT_ADVERT' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

