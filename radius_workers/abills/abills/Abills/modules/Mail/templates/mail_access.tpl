<form action='$SELF_URL'>
<input type=hidden name='index' value='$index'>
<input type=hidden name=MAIL_ACCESS_ID value=%MAIL_ACCESS_ID%>

<div class='box box-theme box-form form-horizontal'>
<div class='box-header with-border'>_{ACCESS}_</div>
<div class='box-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{VALUE}_:</label>
    <div class='col-md-9'>
    <input class='form-control' type=text name=PATTERN value='%PATTERN%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{PARAMS}_:</label>
    <div class='col-md-9'>
    %ACCESS_ACTIONS%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ERROR}_:</label>
    <div class='col-md-9'>
    <input class='form-control' type=text name=CODE value='%CODE%' size=4>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{MESSAGE}_:</label>
    <div class='col-md-9'>
    <input class='form-control' type=text name=MESSAGE value='%MESSAGE%'>
    </div>
  </div>
  <div class='form-group'>
    <div class='checkbox'>
    <label>
      <input type='checkbox' name=DISABLE value='1' %DISABLE%> <strong>_{DISABLE}_</strong>
    </label>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
    <div class='col-md-9'>
      <textarea class='form-control' name=COMMENTS cols=40 rows=5>%COMMENTS%</textarea>
    </div>
  </div>
</div>
<div class='box-footer'>
  <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
</div>
</div>




<!-- <table class=form>
<tr><td>_{VALUE}_:</td><td><input type=text name=PATTERN value='%PATTERN%'></td></tr>
<tr><td>_{PARAMS}_:</td><td>%ACCESS_ACTIONS%
_{ERROR}_:<input type=text name=CODE value='%CODE%' size=4> _{MESSAGE}_:<input type=text name=MESSAGE value='%MESSAGE%'></td></tr>
<tr><td>_{DISABLE}_:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><th colspan=2>_{COMMENTS}_:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS cols=40 rows=5>%COMMENTS%</textarea></th></tr>
<tr><th class=even colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>
 --></form>
