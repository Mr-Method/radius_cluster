<div class='box box-theme box-form'>
  <div class='box-body'>

<FORM action='$SELF_URL' METHOD='POST'  name='add_message' class='form-horizontal' >
    <legend>_{EXPORT}_</legend>
<fieldset>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='UID' value='%UID%'/>
<input type='hidden' name='export' value='1'/>

<div class='form-group'>
    <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_</label>
	 	  <div class='col-md-9'>
	 	  	  <input type='text' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%' class='form-control' >
 	  	</div>
</div>


<div class='form-group'>
    <label class='control-label col-sm-3' for='MESSAGE'>_{MESSAGE}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' id='MESSAGE' name='MESSAGE' rows='3' class='form-control' >%MESSAGE%</textarea>
    </div>
</div>

<div class='form-group'>
      <label class='control-label col-md-3' for='STATUS'>_{PRIORITY}_</label>
      <div class='col-md-9'>
         %PRIORITY_SEL%
     </div>
</div>


    <div class='form-group'>
    <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
	 	  <div class='col-md-9'>
	 	  	  %STATE_SEL%
 	  	</div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='EXPORT_SYSTEM'>_{EXPORT}_</label>
	 	  <div class='col-md-9'>
	 	  	 %EXPORT_SYSTEM_SEL%
 	  	</div>
</div>

    <div class='box-footer' >
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
  </div>

</fieldset>
</form>

</div>
</div>