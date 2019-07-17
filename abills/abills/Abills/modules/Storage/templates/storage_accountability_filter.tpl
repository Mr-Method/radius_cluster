<form action='$SELF_URL' method='GET'>
  <input type='hidden' name='index' value=$index>

  <div class='box box-form'>
    <div class='box-header'><h4>_{SEARCH}_</h4></div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{ADMIN}_:</label>
        <div class='form-group col-md-9'>
          %ADMIN_SEL%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>SN:</label>
        <div class='form-group col-md-9'>
          <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type='submit' name='show_accountability' value='_{SHOW}_' class='btn btn-primary'>
    </div>
  </div>
</form>