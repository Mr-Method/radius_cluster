
<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data' id='CARDS_ADD' class='form-horizontal'>
<input type='hidden' name='index' value='$index'>


<div class='box box-theme box-big-form'>
  <div class='box-body'>

<legend>_{ICARDS}_ : %TYPE_CAPTION%</legend>

<div class='form-group'>
  <label class='control-label col-md-3' for='SERIAL'>_{SERIAL}_</label>
  <div class='col-md-9'>
    <input id='SERIAL' name='SERIAL' value='%SERIAL%' placeholder='_{SERIAL}_' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='BEGIN'>_{BEGIN}_</label>
  <div class='col-md-9'>
    <input id='BEGIN' name='BEGIN' value='%BEGIN%' placeholder='_{BEGIN}_' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='COUNT'>_{COUNT}_</label>
  <div class='col-md-9'>
    <input id='COUNT' name='COUNT' value='%COUNT%' placeholder='_{COUNT}_' class='form-control' type='text'>
  </div>
</div>

<!-- Card type payment or service -->
%CARDS_TYPE%

<div class='form-group'>
  <label class='control-label col-md-12'><p class='text-center'>_{PASSWD}_ / PIN</p></label>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='PASSWD_SYMBOLS'>_{SYMBOLS}_</label>
  <div class='col-md-9'>
    <input id='PASSWD_SYMBOLS' name='PASSWD_SYMBOLS' value='%PASSWD_SYMBOLS%' placeholder='%PASSWD_SYMBOLS%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='PASSWD_LENGTH'>_{SIZE}_</label>
  <div class='col-md-9'>
    <input id='PASSWD_LENGTH' name='PASSWD_LENGTH' value='%PASSWD_LENGTH%' placeholder='%PASSWD_LENGTH%' class='form-control' type='text'>
  </div>
</div>

</div>
</div>


  <!-- Card type payment or service end -->
<div>

    %EXPARAMS%

</div>


<div class='box box-theme box-big-form'>
  <div class='box-body'>

<div class='form-group'>
  <label class='control-label col-md-3' for='EXPIRE'>_{EXPIRE}_</label>
  <div class='col-md-9'>
    <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%' class='form-control datepicker' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='EXPORT'>_{EXPORT}_</label>
  <div class='col-md-9'>
     <input type='radio' class='form-control-sm' name='EXPORT' value='TEXT' checked> Text<br>
     <input type='radio' class='form-control-sm' name='EXPORT' value='XML'> XML
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='DILLER_ID'>_{DILLERS}_</label>
  <div class='col-md-9'>
     %DILLERS_SEL%
  </div>
</div>

</div>

<div class='box-footer'>

  <input type='submit' name='create' value='_{CREATE}_' class='btn btn-primary'>

</div>
</div>

</form>