<div class='noprint'>
<FORM action='$SELF_URL' METHOD='POST' class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>

<div class='box box-theme box-form'>
<div class='box-header with-border'>_{VENDOR}_</div>
  <div class='box-body'>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{VENDOR}_:</label>
      <div class='col-md-9'>
        <input class='form-control' type='text' name='NAME' value='%NAME%'>
      </div>
    </div>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{SITE}_ URL:</label>
      <div class='col-md-9'>
        <input class='form-control' type='text' name='SITE' value='%SITE%'>
      </div>
    </div>
    <div class='form-group'>
      <label class='control-label col-md-3'>_{COMMENTS}_:</label>
      <div class='col-md-9'>
        <textarea  class='form-control' name='COMMENTS' rows='6' cols='60'>%COMMENTS%</textarea>
      </div>
    </div>
  </div>

  <div class='box-footer'>
    <input class='btn btn-primary' type='submit' name='%ACTION%' value='%ACTION_LNG%'>
  </div>
</div>


</FORM>
</div>
