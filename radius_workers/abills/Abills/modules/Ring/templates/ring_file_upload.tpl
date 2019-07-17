<form action=$SELF_URL METHOD=POST class='form-horizontal' enctype=multipart/form-data>

<input type='hidden' name='index' value=%INDEX%>

<div class='box box-theme box-form'>
<div class='box-header with-border text-primary'>_{UPLOAD}_</div>

<div class='box-body'>
	<label class='col-md-3'>_{FILE}_</label>
	<div class='col-md-9'><input type='file' name=FILE></div>
</div>

<div class='box-footer text-center'>
	<button type='submit' class='btn btn-primary'>_{ADD}_</button>
</div>
</div>

</form>