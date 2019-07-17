<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{CONTACTS}_ _{TYPES}_</h4></div>
  <div class='box-body'>

    <form name='contact_types' id='form_contact_types' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='checkbox'>
        <label>
          <input type='checkbox' name='IS_DEFAULT' %IS_DEFAULT_CHECKED% data-return='1' value='1' id='IS_DEFAULT_id'/>
          <strong>_{DEFAULT}_</strong>
        </label>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_contact_types' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

