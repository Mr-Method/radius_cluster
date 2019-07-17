<form action='$SELF_URL' class='form-horizontal'>
  <input type=hidden  name=index value='$index'>
  <input type=hidden  name=add_delivery value='%ID%'>
  <input type=hidden  name=ID value='%ID%'>

  <fieldset>

    <div class='box box-theme '>
      <div class='box-header'><h4 class='box-title'>_{ADD_DELIVERY}_</h4></div>
      <div class='box-body'>

        <div class='form-group'>
          <label class='control-label col-md-2 required' for='SUBJECT'>_{SUBJECT}_:</label>
          <div class=' col-md-10'>
            <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' required placeholder='%SUBJECT%' %DISABLE% class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-2 required' for='TEXT'>_{MESSAGES}_:</label>
          <div class='col-md-10'>
            <textarea class='form-control col-md-10'  required rows='5' %DISABLE% id='TEXT' name='TEXT'  placeholder='_{TEXT}_' >%TEXT%</textarea>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-2 ' for='TEXT'>_{SEND_TIME}_:</label>
          <div class='col-md-5'>

           %DATE_PIKER%
         </div>
         <div class='col-md-5'>

           %TIME_PIKER%
         </div>
       </div>

       <div class='form-group'>
        <label class='control-label col-md-2 ' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-4'>
          %STATUS_SELECT%
        </div>
        <label class='control-label col-md-2 ' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-4'>
          %PRIORITY_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-2 ' for='SEND_METHOD'>_{SEND}_:</label>
        <div class='col-md-10'>
          %SEND_METHOD_SELECT%
        </div>
      </div>

      <div class='box-footer'><input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'></div>

    </div></div>

  </fieldset>
</form>