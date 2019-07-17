<form  class='form-horizontal'>

<input type='hidden' name='index' value=$index>
<input type='hidden' name=NAS_ID value=$FORM{NAS_ID}>
<input type='hidden' name='radtest' value='1'>

  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h4 class='box-title'>RADIUS _{REQUEST}_</h4></div>
    <div class='box-body'>


    <div class='form-group'>
  <label class='col-md-3'>RAD_PAIRS</label>
  <div class='col-md-9'>
    <textarea class='form-control' name='RAD_REQUEST' cols='45' rows='10'>%RAD_PAIRS%</textarea>
  </div>
</div>

<div class='form-group'>
  <label class='col-md-3 control-element'>_{COMMENTS}_</label>
  <div class='col-md-6'>
    <input type='text' class='form-control' name='COMMENTS' value=%COMMENTS%>
  </div>
  <div class='checkbox col-md-2'>
    <label>
      <input type='checkbox' name='SAVE'> _{SAVE}_
    </label>
  </div>
</div>

<div class='form-group'>
    <label class='col-md-3 control-element'>_{TYPE}_ _{QUERY}_</label>
    <div class='col-md-9'>
      %QUERY_TYPE%
    </div>
</div>
    </div>
<div class='box-footer'>
<input type='submit' class='btn btn-primary' name='runtest' value='_{SHOW}_'>
</div>
  </div>

</form>