<form action='$SELF_URL' method='post' name='add_message' class='form form-horizontal'>
  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4>_{DISPATCH}_</h4></div>
    <div class='box-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PLAN_DATE'>_{EXECUTION}_</label>
        <div class='col-md-9'>
          <input type='text' name='PLAN_DATE' id='PLAN_DATE'
                 value='%PLAN_DATE%' placeholder='%PLAN_DATE%'
                 class='form-control datepicker'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'
          >%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
        <div class='col-md-9'>
          %STATE_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='RESPOSIBLE'>_{RESPOSIBLE}_</label>
        <div class='col-md-9'>
          %RESPOSIBLE_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME'>_{DISPACTH_CATEGORY}_</label>
        <div class='col-md-9'>
          %CATEGORY_SEL%
        </div>
      </div>

    </div>
    <div class='box-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>

  </div>
</form>
