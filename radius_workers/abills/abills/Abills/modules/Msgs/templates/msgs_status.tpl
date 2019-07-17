<form method='POST' action='$SELF_URL' class='form-horizontal'>

<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='%ID%'>


  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{STATUS}_</h4></div>
    <div class='box-body'>

  <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='NAME' value='%NAME%'>
    </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'>_{READINESS}_</label>
    <div class='col-md-9'>
      <div class='input-group'>
        <input type='number' class='form-control' name='READINESS' value='%READINESS%'>
        <span class='input-group-addon'>%</span>
      </div>
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{COLOR}_</label>
      <div class='col-md-9'>
          <input type='color' class='form-control' name='COLOR' value='%COLOR%'>
      </div>
   </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{ICON}_</label>
      <div class='col-md-9'>
          <input type='text' class='form-control' name='ICON' value='%ICON%'>
      </div>
   </div>

  <div class='form-group'>
    <div class='checkbox'>
      <label class='col-md-3'></label>
    <label>
      <input type='checkbox' name='TASK_CLOSED' %CHECKED%>_{TASK_CLOSED}_
    </label>
  </div>
  </div>
</div>

<div class='box-footer'>
  <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
</div>

</div>

</form>