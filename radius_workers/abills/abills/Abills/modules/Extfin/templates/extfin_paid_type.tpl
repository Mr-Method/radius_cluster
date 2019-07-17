<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>

<div class='box box-theme box-form form-horizontal'>
  <div class='box-body'>
    <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=NAME value='%NAME%'>
    </div>
    </div>
    <div class='form-group'>
      <div class='checkbox'>
      <label>
      <input type='checkbox' name=PERIODIC value='1' %PERIODIC%> _{PERIOD}_
      </label>
  </div>
    </div>
  </div>
  <div class='box-footer'>
    <input class='btn btn-primary' type=submit name=%ACTION% value='%ACTION_LNG%'>
  </div>
</div>

<!-- <TABLE class=form>
<TR><TD>_{NAME}_:</TD><TD><input type=text name=NAME value='%NAME%'></TD></TR>
<TR><TD>_{PERIOD}_:</TD><TD><input type=checkbox name=PERIODIC value='1' %PERIODIC%></TD></TR>
<TR><TH colspan=2><input type=submit name=%ACTION% value='%ACTION_LNG%'></TH></TR>
</TABLE> -->

</form>
</div>
