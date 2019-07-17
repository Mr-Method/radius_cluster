<form action='$SELF_URL' METHOD='POST' class='form-horizontal' name=admin_form>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='%ID%'>

<fieldset>

<div class='box box-theme box-form'>
<div class='box-body'>

<legend>billd</legend>
<div class='form-group'>
  <label class='control-label col-md-3' for='PLUGIN_NAME'>_{NAME}_:</label>
  <div class='col-md-9'>
    <input id='PLUGIN_NAME' name='PLUGIN_NAME' value='%PLUGIN_NAME%' placeholder='_{PLUGIN_NAME}_' class='form-control' type='text'>
   </div>
</div> 

<div class='form-group'>
  <label class='control-label col-md-3' for='PERIOD'>_{PERIOD}_ (Sec:):</label>
  <div class='col-md-9'>
    <input id='PERIOD' name='PERIOD' value='%PERIOD%' placeholder='300' class='form-control' type='text'>
  </div>
</div> 
  
<div class='form-group'>
  <label class='control-label col-md-3' for='STATUS'>_{STATUS}_:</label>
  <div class='col-md-9'>
    %STATUS_SEL%
  </div>
</div> 
   
<div class='form-group'>
  <label class='control-label col-md-3' for='THREADS'>_{THREADS}_:</label>
  <div class='col-md-9'>
    %THREADS_SEL%
  </div>
</div> 

<div class='form-group'>
  <label class='control-label col-md-3' for='MAKE_LOCK'>_{LOCK}_:</label>
  <div class='col-md-9'>
    <input id='MAKE_LOCK' name='MAKE_LOCK' value='1' %MAKE_LOCK% type='checkbox'>
  </div>
</div> 

<div class='form-group'>
  <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_:</label>
  <div class='col-md-9'>
    %PRIORITY_SEL%
  </div>
</div> 

<input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>

</div>
</div>

</fieldset>
</form>

