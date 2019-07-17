<form action=$SELF_URL METHOD=POST>

<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value='%ID%'>

<div class='box box-theme box-form form-horizontal'>
<div class='box-header with-border text-primary'>$lang{DISCOUNT}</div>

<div class='box-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_</label>
    <div class='col-md-9'>
    <input class='form-control' type='text' name='NAME' value='%NAME%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{SIZE}_</label>
    <div class='col-md-9'>
      <input class='form-control' type='number' name='SIZE' value='%SIZE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9'>
    <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
    </div>
  </div>
</div>

<div class='box-footer'>
  <input type='submit' class='btn btn-primary' name=%ACTION% value='%ACTION_LANG%'>
</div>
</div>

</form>