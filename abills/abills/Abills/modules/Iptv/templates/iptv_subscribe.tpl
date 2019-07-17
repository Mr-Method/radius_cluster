<form class='form-horizontal' action='$SELF_URL' method='post' ENCTYPE='multipart/form-data'>
  <div class='box box-theme box-form'>
    <div class='box-header'>
      <h4>Subsribes</h4>
    </div>
    <div class='box-body'>
<form class='form-horizontal' action='$SELF_URL' method='post' ENCTYPE='multipart/form-data'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='$FORM{chg}'>

<fieldset>
%ID_FIELD%

<div class='form-group'>
  <label class='control-label col-md-3' for='COUNT'>_{COUNT}_</label>
  <div class='col-md-9'>
    <input id='COUNT' name='COUNT' value='%COUNT%' placeholder='%COUNT%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
  <div class='col-md-9'>
   %STATUS_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_</label>
  <div class='col-md-9'>
    %TP_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='EXT_ID'>EXT_ID</label>
  <div class='col-md-9'>
    <input id='EXT_ID' name='EXT_ID' value='%EXT_ID%' placeholder='%EXT_ID%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='PIN'>PIN</label>
  <div class='col-md-9'>
    <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='IMPORT'>_{IMPORT}_</label>
  <div class='col-md-9'>
    <input id='IMPORT' name='IMPORT' value='%IMPORT%' placeholder='%IMPORT%' class='form-control' type='file'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='EXPIRE'>_{EXPIRE}_</label>
  <div class='col-md-9 %EXPIRE_COLOR%'>
    <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%' class='form-control datepicker' rel='tcal' type='text'>
  </div>
</div>

</div>


  <div class='box-footer'>

    <input type=submit name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>

  </div>

</fieldset>

</div>

</form>