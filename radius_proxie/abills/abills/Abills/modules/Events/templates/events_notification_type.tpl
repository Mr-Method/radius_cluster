<div class="clearfix"></div>
<div class="row">
  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{NOTIFICATION_TYPE}_</h4></div>
    <div class='box-body'>
      <form name='EVENTS_PRIORITY_SEND_TYPE' id='form_EVENTS_PRIORITY_SEND_TYPE' method='post'
            class='form form-horizontal'>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='save' value='1'/>
        <input type='hidden' name='PRIORITY_ID' value='%PRIORITY_ID%'/>
        <input type='hidden' name='AID' value='%AID%'/>

        <div class='form-group'>
          <label class='control-label col-md-3' for='CHECKBOXES'>_{NOTIFICATION_TYPE}_</label>
          <div class='col-md-9'>
            %CHECKBOXES%
          </div>
        </div>
      </form>

    </div>
    <div class='box-footer text-center'>
      <input type='submit' form='form_EVENTS_PRIORITY_SEND_TYPE' class='btn btn-primary' name='submit'
             value='_{SEND}_'>
    </div>
  </div>

</div>