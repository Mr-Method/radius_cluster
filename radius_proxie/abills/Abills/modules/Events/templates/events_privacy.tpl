<div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{ACCESS}_</h4></div>
    <div class='box-body'>

        <form name='EVENTS_PRIVACY_FORM' id='form_EVENTS_PRIVACY_FORM' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>
          <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='PRIVACY_NAME_id'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required name='NAME' value='%NAME%'
                           id='PRIVACY_NAME_id' placeholder='_{PRIVACY}_'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='PRIVACY_VALUE_id'>_{VALUE}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' required name='VALUE' value='%VALUE%'
                           id='PRIVACY_VALUE_id'/>
                </div>
            </div>
        </form>

    </div>
    <div class='box-footer text-center'>
        <input type='submit' form='form_EVENTS_PRIVACY_FORM' class='btn btn-primary' name='submit'
               value='%SUBMIT_BTN_NAME%'>
    </div>
</div>

