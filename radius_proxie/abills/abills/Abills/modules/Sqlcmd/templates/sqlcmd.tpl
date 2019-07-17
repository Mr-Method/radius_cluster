<form action='$SELF_URL' METHOD=POST class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=HOST_ID value='$FORM{HOST_ID}'>




<div class=row>
	
	
<div  class='col-md-7'> 
<div class='form-group'>
	<label class='control-label'>SQL QUERY:</label>
	<textarea name='QUERY' cols=70 rows=10 onkeydown='keyDown(event)' onkeyup='keyUp(event)' class='form-control'>%QUERY%</textarea>	
</div>
<div class='form-group'>
	<label class='control-label col-md-2'>_{ROWS}_:</label>
	<div class='col-md-2'><input type=text class='form-control' name='ROWS' value='%ROWS%'></div>
	<label class='control-label col-md-3'>_{SAVE}_:<input type=checkbox name='HISTORY' value='1'></label>
	<label class='control-label col-md-2'>XML: <input type=checkbox name='xml' value='1'></label>
</div>
<div class='form-group'>
	<label class='control-label col-md-3'>_{COMMENTS}_:</label>
	<div class='col-md-6'><input type=text name='COMMENTS' value='%COMMENTS%' class='form-control'></div>
</div>

<div><input type=submit name=show value='QUERY' id='go' title='Ctrl+C' class='btn btn-primary'></div>
</div>

<div class='col-md-5'>
<div class='form-group'>
	<label class='control-label'>QUERIES</label>
	%SQL_HISTORY%
</div>
</div>


</div>



</form>


