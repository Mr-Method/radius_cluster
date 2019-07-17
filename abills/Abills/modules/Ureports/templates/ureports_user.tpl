%MENU%

<form action='$SELF_URL' method='post' class='form-horizontal'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>

<fieldset>

<div class='box box-theme box-form'>
  <div class='box-body'>

<div class='form-group'>
  <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_</label>
  <div class='col-md-9'>
    <div class='input-group'>
      <span class='input-group-addon bg-primary'>%TP_ID%</span>
      %TP_NAME%
      <span class='input-group-addon'>%CHANGE_TP_BUTTON%</span>
    </div>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='TYPE'>_{TYPE}_</label>
  <div class='col-md-9'>
    %TYPE_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='DESTINATION'>_{DESTINATION}_</label>
  <div class='col-md-9'>
    <input type='text' name='DESTINATION' id='DESTINATION' value='%DESTINATION%' placeholder='%DESTINATION%' class='form-control' >
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
  <div class='col-md-9'>
    %STATUS_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for=''>_{REGISTRATION}_</label>
  <div class='col-md-9'>
    %REGISTRATION%
  </div>
</div>

</div>

    <div class='box-footer'>
        <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        %HISTORY_BTN%
    </div>


</div>

<div>%REPORTS_LIST%</div>


</fieldset>
</form>
