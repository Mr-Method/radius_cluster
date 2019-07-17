
<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{LEADS}_</h4></div>
  <div class='box-body'>
        <form name='CRM_LEAD_SEARCH' id='form_CRM_LEAD_SEARCH' method='post' class='form form-horizontal %AJAX_SUBMIT_FORM%'>
        
        <input type='hidden' name='index' value='%INDEX%' />
        <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1' />
        <input type='hidden' name='ID' value='%LEAD_ID%' />

      <div class='form-group %HIDE_ID%'>
        <label class='control-label col-md-3' for='LEAD_ID_ID'>ID</label>
        <div class='col-md-9'>
            <input type='text' %DISABLE_ID% class='form-control' value='%LEAD_ID%'  name='LEAD_ID'  id='LEAD_ID_ID'  />
        </div>
      </div>
  
      <div class='form-group'>
        <label class='control-label col-md-3' for='FIO_ID'>_{FIO}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%FIO%' name='FIO'  id='FIO_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PHONE_ID'>_{PHONE}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%PHONE%'  name='PHONE'  id='PHONE_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='EMAIL_ID'>E-Mail</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%EMAIL%'  name='EMAIL'  id='EMAIL_ID'  />
        </div>
      </div>
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='COMP_ID'>_{CITY}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%CITY%'  name='CITY'  id='CITY_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMP_ID'>_{ADDRESS}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%ADDRESS%'  name='ADDRESS'  id='ADDRESS_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMP_ID'>_{COMPANY}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%COMPANY%'  name='COMPANY'  id='COMPANY_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{SOURCE}_</label>
        <div class='col-md-9'>
          %LEAD_SOURCE%
        </div>
      </div>

          <div class='form-group %HIDE_ID%'>
            <label class='control-label col-md-3'>_{STEP}_</label>
            <div class='col-md-9'>
              %CURRENT_STEP_SELECT%
            </div>
          </div>

    <div class='form-group'>
      <label class='control-label col-md-3'>_{DATE}_</label>
      <div class='col-md-9'>
        <!--<input type='text' name='DATE' value='%DATE%' placeholder='%DATE%' class='form-control daterange' >-->
        %DATE%
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-md-3'>_{RESPOSIBLE}_</label>
      <div class='col-md-9'>
        %RESPONSIBLE_ADMIN%
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-md-3'>_{PRIORITY}_</label>
      <div class='col-md-9'>
        %PRIORITY_SEL%
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
  <div class='box-footer '>
      <input type='submit' form='form_CRM_LEAD_SEARCH' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

