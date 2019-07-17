<form action=$SELF_URL METHOD=post>
<input type=hidden name=chg value='$FORM{chg}'>
<input type=hidden name=index value='$index'>

<table class=form>
<tr>
  <th>_{VARIABLE}_:</th>
  <th>_{TYPE}_</th>
  <th>_{DEFAULT_VALUE}_</th>
  <th>_{DESCRIBE}_</th>
</tr>
<tr>
  <td><input type=text name=PARAM value='%PARAM%' size=30 class='form-control'></td>
  <td>%TYPE_SEL%</td>
  <td><textarea name=VALUE cols=40 rows=6 class='form-control'>%VALUE%</textarea></td>
  <td><textarea name=COMMENTS cols=40 rows=6 class='form-control'>%COMMENTS%</textarea></td>
</tr>
<tr><th colspan=4 class=even><input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'></th></tr>
</table>

</form>

