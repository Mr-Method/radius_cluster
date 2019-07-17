<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
<input type='hidden' name='index' value='27'/>
<input type='hidden' name='chg' value='%GID%'/>

<fieldset>
<div class='box box-theme box-form'>
<div class='box-header with-border'><h4 class='box-title'>_{GROUPS}_</h4></div>
<div class='box-body'>

<div class='form-group'>
    <label class='control-label col-md-3 required' for='GID'>GID:</label>
  <div class='col-md-9'>
      <input id='GID' name='GID' value='%GID%' required placeholder='%GID%' class='form-control' type='text'>
   </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
  <div class='col-md-9'>
    <input id='NAME' type='text' name='NAME' value='%NAME%' class='form-control'>
  </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='DESCR'>_{DESCRIBE}_:</label>
  <div class='col-md-9'>
     <input id='DESCR' type='text' name='DESCR' value='%DESCR%' class='form-control'>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-6' for='ALLOW_CREDIT'>_{ALLOW}_ _{CREDIT}_</label>
  <div class='col-md-2'>
    <input id='ALLOW_CREDIT' name='ALLOW_CREDIT' value='1' %ALLOW_CREDIT%  type='checkbox'>
  </div>
   </div>
    <div class='form-group'>
  <label class='control-label col-md-6' for='DISABLE_PAYSYS'>_{DISABLE}_ PAYSYS</label>
  <div class='col-md-2'>
    <input id='DISABLE_PAYSYS' name='DISABLE_PAYSYS' value='1' %DISABLE_PAYSYS%  type='checkbox'>
  </div>
   </div>
    <div class='form-group'>
  <label class='control-label col-md-6' for='DISABLE_CHG_TP'>_{DISABLE}__{USER_CHG_TP}_:</label>
  <div class='col-md-2'>
    <input id='DISABLE_CHG_TP' name='DISABLE_CHG_TP' value='1' %DISABLE_CHG_TP%  type='checkbox'>
  </div>
   </div>
    <div class='form-group'>
  <label class='control-label col-md-6' for='SEPARATE_DOCS'>_{SEPARATE_DOCS}_:</label>
  <div class='col-md-2'>
    <input id='SEPARATE_DOCS' name='SEPARATE_DOCS' value='1' %SEPARATE_DOCS%  type='checkbox'>
  </div>
   </div>

    <div class='form-group'>
        <label class='control-label col-md-6' for='BONUS'>_{BONUS}_:</label>
        <div class='col-md-2'>
            <input id='BONUS' name='BONUS' value='1' %BONUS%  type='checkbox'>
        </div>
    </div>

    %DOMAIN_FORM%

  </div>
  <div class='box-footer'>
    <input type='submit' name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
  </div>
</div>
   </fieldset>
</form>
