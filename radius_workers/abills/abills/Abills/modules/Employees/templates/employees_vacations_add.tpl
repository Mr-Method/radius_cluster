<form action='$SELF_URL' method='post' class='form form-horizontal'>

  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='box box-form box-primary'>

    <div class='box-header with-border'><h4>_{VACATIONS}_</h4></div>

    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{EMPLOYEE}_</label>
        <div class='col-md-9'>
          %ADMIN_SELECT%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{DATE}_ </label>
        <div class='col-md-9'>
          %DATE_RANGE%
      </div>
    </div>
    </div>

    <div class='box-footer'>
      <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
    </div>

  </div>

</form>