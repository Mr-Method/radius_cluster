<form action='$SELF_URL' class='form-horizontal'>
<input type=hidden  name=index value='$index'>
<input type=hidden  name=LOCATION_ID value='%LOCATION_ID%'>
<input type=hidden  name=ADDRESS_FLAT value='%ADDRESS_FLAT%'>
<input type=hidden  name=NOTIFY_FN value='msgs_unreg_requests_list'>
<input type=hidden  name=NOTIFY_ID value='%ID%'>
<input type=hidden  name=add_user value='%ID%'>

%EXT_FIELDS%

<fieldset>

    <div class='box box-theme box-big-form'>
        <div class='box-header'><h4 class='box-title'>_{ADD_USER}_</h4></div>
        <div class='box-body'>

<div class='form-group'>
  <label class='control-label col-md-4' for='ID'>#</label>
  <label class='control-label col-md-8 text-left' for='ID'>%ID%</label>
</div>

<div class='form-group'>
    <label class='control-label col-md-4' for='LOGIN'>_{LOGIN}_:</label>
  <div class=' col-md-8'>
    <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%' class='form-control' type='text'>
  </div>
</div> 

<div class='form-group'>
    <label class='control-label col-md-4' for='FIO'>_{FIO}_:</label>
  <div class=' col-md-8'>
    <input id='FIO' name='FIO' value='%FIO%' placeholder='%FIO%' class='form-control' type='text'>
  </div>
</div> 

<div class='form-group'>
    <label class='control-label col-md-4' for='TP_ID'>_{TARIF_PLAN}_:</label>
  <div class=' col-md-8'>%TP_SEL%</div>
</div> 

<div class='form-group'>
    <label class='control-label col-md-4' for='GID'>_{GROUP}_:</label>
  <div class=' col-md-8'>
  	%GID_SEL%
  </div>
</div> 

<div class='form-group'>
    <label class='control-label col-md-4' for='PHONE'>_{PHONE}_:</label>
  <div class=' col-md-8'>
    <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control' type='text'>
  </div>
</div> 

<div class='form-group'>
  <label class='control-label col-md-4' for='EMAIL'>E-MAIL:</label>
  <div class=' col-md-8'>
    <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control' type='text'>
  </div>
</div>

<div class='box-footer'><input type='submit' class='btn btn-primary' name='add_user_' value='%ACTION_LNG%'></div>


</div></div>

</fieldset>
</form>