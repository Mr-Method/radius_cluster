<form action='$SELF_URL' >

<input type='hidden' name='index' value=$index>

<div class='box box-form box-primary form-horizontal'>

<div class='box-header with-border'>_{EXTERNAL_COMMAND}_</div>

<div class='box-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{START_COMMAND}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='PAYSYS_EXTERNAL_START_COMMAND'>%PAYSYS_EXTERNAL_START_COMMAND%</textarea>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{END_COMMAND}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='PAYSYS_EXTERNAL_END_COMMAND'>%PAYSYS_EXTERNAL_END_COMMAND%</textarea>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ATTEMPTS}_</label>
    <div class='col-md-9'>
      <input type='number' class='form-control' name='PAYSYS_EXTERNAL_ATTEMPTS' value='%PAYSYS_EXTERNAL_ATTEMPTS%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{TIME}_</label>
    <div class='col-md-9'>
      <input type='number' class='form-control' name='PAYSYS_EXTERNAL_TIME' value='%PAYSYS_EXTERNAL_TIME%'>
    </div>
  </div>
</div>

<div class='box-footer'>
<input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LANG%'>
</div>

</div>

</form>