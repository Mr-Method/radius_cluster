<form method='POST' action='$SELF_URL' class='form-horizontal'>

<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='%ID%'>


  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{ADD}_ _{MSGS_TAGS}_</h4></div>
    <div class='box-body'>

  <div class='form-group'>
    <label class='col-md-3 control-label'>_{TAGS}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='REPLY' value='%REPLY%'>
    </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'>_{MSGS_TAGS_TYPES}_</label>
    <div class='col-md-9'>
      %QUICK_REPLYS_CATEGORY%
    </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COLOR}_</label>
    <div class='col-md-9'>
      <input type='color' class='form-control' value='#80ff00' name='COLOR' value='%COLOR%'>
    </div>
  </div>

<div class='box-footer'>
  <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
</div>

</div>
</div>

</form>