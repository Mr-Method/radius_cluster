<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>$lang{EVENTS} $lang{GROUP}</h4></div>
  <div class='box-body'>

    <form name='EVENTS_GROUP' id='form_EVENTS_GROUP' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>$lang{NAME}</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='row'>%MODULE_CHECKBOXES%</div>

    </form>
  </div>
  <div class='box-footer'>
    <input type='submit' form='form_EVENTS_GROUP' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>


