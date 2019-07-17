<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{EVENT}_ _{STATE}_</h4></div>
  <div class='box-body'>

    <form name='EVENTS_STATE_FORM' id='form_EVENTS_STATE_FORM' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='STATE_NAME_id'>_{STATE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='STATE_NAME_id'
                 placeholder='_{STATE}_'/>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_EVENTS_STATE_FORM' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

