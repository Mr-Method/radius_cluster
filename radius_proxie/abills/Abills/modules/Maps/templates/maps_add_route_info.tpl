<form action='$SELF_URL' ID='mapForm' name='adress' class='form-inline'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='COORDX' value='%COORDX%'>
  <input type='hidden' name='COORDY' value='%COORDY%'>
  <input type='hidden' name='POINTS' value='%POINTS%'>

  <div class='box box-theme'>
    <div class='box-header with-border'>
      <h3>_{ROUTES}_</h3>
    </div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3' for='ROUTE_ID'>_{ROUTE}_</label>
        <div class='col-md-9'>
          %ROUTE_ID%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PARENT_ID'>_{PARENT_ROUTE}_</label>
        <div class='col-md-9'>
          %PARENT_ROUTE_ID%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='GROUP_ID'>_{GROUP}_</label>
        <div class='col-md-9'>
          %GROUP_ID%
        </div>
      </div>
    </div>
    <div class='box-footer text-center'>
      <input type='submit' name=add_route_info value=_{ADD}_ class='btn btn-primary'>
    </div>
  </div>


</form>

