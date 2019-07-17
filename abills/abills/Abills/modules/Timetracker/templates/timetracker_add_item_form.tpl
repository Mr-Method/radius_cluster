          <div class='box box-theme box-form'>
          <div class='box-header with-border'><h4 class='box-title'>%TITLE%</h4></div>
          <div class='box-body'>
                <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='GET' class='form form-horizontal'>
                <input type='hidden' name='index' value='$index' />
                <input type='hidden' name='ID' value='%ID%' />

              <div class='form-group'>
                <label class='control-label col-md-3 required' for='ELEMENT_ID'>_{ELEMENT}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control'  required name='ELEMENT'  id='ELEMENT_ID' value='%ELEMENT%' />
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3'>_{AUTOFILL}_</label>
                <div class='col-md-9'>
                    %EXTERNAL_SYSTEMS%
                </div>
              </div>


              <div class='checkbox text-center'>
                <label>
                    <input type='checkbox' data-return='1' value = "1" data-checked='%PRIORITY%' name='PRIORITY'  id='PRIORITY_ID'  />
                    <strong>_{FOCUS_FACTOR}_</strong>
                </label>
              </div>

                </form>

          </div>
          <div class='box-footer text-center'>
              <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='%ACTION%' value="%BTN%">
          </div>
        </div>     