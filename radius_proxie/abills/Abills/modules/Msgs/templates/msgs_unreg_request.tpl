<form action='$SELF_URL' METHOD='POST' name='reg_request_form' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <fieldset>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'><h4 class='box-title'>_{REQUESTS}_</h4></div>
      <div class='box-body'>

        <div class='form-group'>
          <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>
          <div class='col-md-9'>
            %DATE%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='CHAPTERS'>_{CHAPTERS}_</label>
          <div class='col-md-9'>
            %CHAPTER_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_:</label>
          <div class='col-md-9'>
            <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%' class='form-control'
                   type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='col-sm-offset-2 col-sm-8'>_{COMMENTS}_</label>
          <div class='col-sm-offset-2 col-sm-10'>
            <textarea cols='30' rows='4' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='COMPANY_NAME'>_{COMPANY}_:</label>
          <div class='col-md-9'>
            <input id='COMPANY_NAME' name='COMPANY_NAME' value='%COMPANY_NAME%' placeholder='%COMPANY_NAME%'
                   class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='FIO'>_{FIO}_:</label>
          <div class='col-md-9'>
            <input id='FIO' name='FIO' value='%FIO%' placeholder='%FIO%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='PHONE'>_{PHONE}_:</label>
          <div class='col-md-9'>
            <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='EMAIL'>E-mail:</label>
          <div class='col-md-9'>
            <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control' type='text'>
          </div>
        </div>


        <div class='form-group'>
          <label class='control-label col-md-3' for='SUBJECT'>_{CONNECTION_TIME}_:</label>
          <div class='col-md-9'>
            <input id='CONNECTION_TIME' name='CONNECTION_TIME' value='%CONNECTION_TIME%' placeholder='%CONNECTION_TIME%'
                   class='form-control datepicker' type='text'>
          </div>
        </div>

        %ADDRESS_TPL%

        <div class='form-group'>
          <label class='control-label col-md-3' for='STATE'>_{STATE}_:</label>
          <div class='col-md-9'>
            %STATE_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_:</label>
          <div class='col-md-9'>
            %PRIORITY_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='RESPOSIBLE'>_{RESPOSIBLE}_:</label>
          <div class='col-md-9'>
            %RESPOSIBLE_SEL%
          </div>
        </div>

      </div>
      <div class='box-footer text-center'>

        %BACK_BUTTON% <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
      </div>
    </div>

  </fieldset>
</form>
