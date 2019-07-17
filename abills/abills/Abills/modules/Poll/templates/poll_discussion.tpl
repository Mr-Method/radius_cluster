<form method='post' class='form'>

<input type='hidden' name='poll' value='$FORM{poll}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='LOGIN'   value='%LOGIN%'>
<input type='hidden' name='DISCUSSION' value='1'>

<div class='box box-theme'>
	<div class='box-header with-border text-primary'><h3>%SUBJECT%</h3></div>
	<div class='box-body text-left'>
		%MESSAGE%
	</div>
	<div class='box-footer'>
	  <div class='form-group'>
		  <textarea class='form-control' name='MESSAGE' rows='10'></textarea>
	  </div>
	  <div class='form-group'>
          <input type='submit' class='btn btn-primary' value='_{SEND}_'>
	  </div>
	</div>
</div>

</form>