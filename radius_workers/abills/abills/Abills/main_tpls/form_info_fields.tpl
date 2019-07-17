<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{INFO_FIELDS}_ - _{ADD}_</h4></div>
  <div class='box-body'>
        <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1' />
        <input type='hidden' name='ID' value='%ID%' />
  
      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_ID'>_{NAME}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%NAME%'  name='NAME'  id='NAME_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='SQL_FIELD_ID'>SQL_FIELD</label>
        <div class='col-md-9'>
            <input %READONLY% required type='text' class='form-control' value='%SQL_FIELD%' name='SQL_FIELD' id='SQL_FIELD_ID'" />
        </div>
      </div>
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='TYPE'>_{TYPE}_</label>
          <div class='col-md-9'>
            %TYPE_SELECT%
          </div>  
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PRIORITY_ID'>_{PRIORITY}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%PRIORITY%'  name='PRIORITY'  id='PRIORITY_ID'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PATTERN'>_{TEMPLATE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%PATTERN%'  name='PATTERN'  id='PATTERN'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='TITLE'>_{TIP}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%TITLE%'  name='TITLE'  id='TITLE'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PLACEHOLDER'>_{PLACEHOLDER}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%PLACEHOLDER%'  name='PLACEHOLDER'  id='PLACEHOLDER'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='ABON_PORTAL_ID'>_{USER_PORTAL}_</label>
        <div class='col-md-9'>
            <input type='checkbox' data-return='1' data-checked='%ABON_PORTAL%' name='ABON_PORTAL' id='ABON_PORTAL_ID' value='1'/> 
        </div>        
      </div>
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='USER_CHG_ID'>_{USER}_ _{CHANGE}_</label>
        <div class='col-md-9'>
            <input type='checkbox' data-return='1' data-checked='%USER_CHG%' name='USER_CHG'   id='USER_CHG_ID' value='1'/> 
        </div>        
      </div>
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='COMPANY_ID'>_{COMPANY}_</label>
        <div class='col-md-9'>
            <input %READONLY2% type='checkbox' data-return='1' data-checked='%COMPANY%' name='COMPANY' id='COMPANY_ID' value='1'/> 
        </div>        
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='MODULE_ID'>_{MODULE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%MODULE%'  name='MODULE'  id='MODULE_ID'  />
        </div>
      </div>
      
      <div class='form-group'>
          <label class='control-label col-md-3' for='COMMENT_ID'>_{COMMENTS}_</label>
          <div class='col-md-9'>
              <textarea class='form-control col-md-9'  rows='2'  name='COMMENT' id='COMMENT_ID'>%COMMENT%</textarea>
          </div>
      </div>
    </form>

  </div>
  <div class='box-footer text-center'>
      <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>