<SCRIPT type='text/javascript'>

function samechanged(what) {
  if ( what.value == 3 ) {
    what.form.RESPOSIBLE.disabled = false;
    what.form.RESPOSIBLE.style.backgroundColor = '$_COLORS[2]';
  } else {
    what.form.RESPOSIBLE.disabled = true;
    what.form.RESPOSIBLE.style.backgroundColor = '$_COLORS[3]';
  }
}

samechanged('RESPOSIBLE');

</SCRIPT>
<div class='box box-theme box-form'>
  <div class='box-body'>

<FORM action='$SELF_URL' METHOD='POST'  name='add_message' class='form-horizontal' >
    <legend>_{DISPATCH}_</legend>
<fieldset>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>


<div class='form-group'>
    <label class='control-label col-md-3' for='PLAN_DATE'>_{EXECUTION}_</label>
	 	  <div class='col-md-9'>
	 	  	  <input type='text' name='PLAN_DATE' value='%PLAN_DATE%' placeholder='%PLAN_DATE%' class='form-control datepicker' >
 	  	</div>
</div>

<div class='form-group'>
    <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3' class='form-control' >%COMMENTS%</textarea>
    </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
	 	  <div class='col-md-9'>
	 	  	  %STATE_SEL%
 	  	</div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='RESPOSIBLE'>_{RESPOSIBLE}_</label>
	 	  <div class='col-md-9'>
	 	  	 %RESPOSIBLE_SEL%
 	  	</div>
</div>

</div>
<div class='box-footer text-center'>
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>
</fieldset>
</form>
</div>