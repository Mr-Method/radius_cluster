<form action='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>

<div class='box box-theme box-form form-horizontal'>
<div class='box-header with-border'>_{BONUS}_ Turbo</div>
<div class='box-body'>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{SERVICE}_ _{PERIOD}_ (_{MONTH}_):</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name='SERVICE_PERIOD' value='%SERVICE_PERIOD%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{REGISTRATION}_ (_{DAYS}_):</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name='REGISTRATION_DAYS' value='%REGISTRATION_DAYS%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{TURBO}_ _{COUNT}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name='TURBO_COUNT' value='%TURBO_COUNT%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{DESCRIBE}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name=COMMENTS rows=6 cols=45>%COMMENTS%</textarea>
    </div>
  </div>
</div>
<div class='box-footer'>
  <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
</div>
</div>

<!-- <table class=form>

<tr><th colspan='2' class=form_title>_{BONUS}_ Turbo</th></tr>
<tr><td>_{SERVICE}_ _{PERIOD}_ (_{MONTH}_):</td><td><input type=text name='SERVICE_PERIOD' value='%SERVICE_PERIOD%'></td></tr>
<tr><td>_{REGISTRATION}_ (_{DAYS}_):</td><td><input type=text name='REGISTRATION_DAYS' value='%REGISTRATION_DAYS%'></td></tr>
<tr><td>_{TURBO}_ _{COUNT}_:</td><td><input type=text name='TURBO_COUNT' value='%TURBO_COUNT%'></td></tr>
<tr><th color=form_title>_{DESCRIBE}_</th></tr>
<tr><th colspan=2><textarea name=COMMENTS rows=6 cols=45>%COMMENTS%</textarea></th></tr>


<tr><th colspan='3' class=even><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table> -->

</form>
