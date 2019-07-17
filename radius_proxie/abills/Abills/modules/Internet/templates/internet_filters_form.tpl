          <div class='box box-theme box-form'>
          <div class='box-header with-border'><h4 class='box-title'>_{FILTERS_LOG}_</h4></div>
          <div class='box-body'>
                <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='GET' class='form form-horizontal'>
                <input type='hidden' name='index' value='$index' />
                <input type='hidden' name='ID' value='%ID%' />

              <div class='form-group'>
                <label class='control-label col-md-3' for='FILTER_ID'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' name='FILTER'  id='FILTER_ID' value='%FILTER%' />
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3' for='PARAMS_ID'>_{PARAMS}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' name='PARAMS'  id='PARAMS_ID' value='%PARAMS%' />
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3' for='DESCR_ID'>_{DESCRIBE}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' name='DESCR'  id='DESCR_ID' value='%DESCR%' />
                </div>
              </div>

                </form>

          </div>
          <div class='box-footer text-center'>
              <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='%ACTION%' value="%BTN%">
          </div>
        </div>     