<div class='box box-theme box-form'>
<div class='box-body'>

<form action=$SELF_URL method=post class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value='$FORM{chg}'>
<input type=hidden name=TP_ID value='$FORM{TP_ID}'>
<input type=hidden name=subf value='$FORM{subf}'>

<fieldset>
<legend>_{SCREENS}_</legend>
<div class='form-group'>
  <label class='control-label col-md-3' for='NUM'>_{NUM}_:</label>
  <div class='col-md-9'>
      <input id='NUM' name='NUM' value='%NUM%' placeholder='%NUM%' class='form-control' type='text'>
    </div>
   </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
  <div class='col-md-9'>
      <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
    </div>
   </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='MONTH_FEE'>_{MONTH_FEE}_:</label>
  <div class='col-md-9'>
      <input id='MONTH_FEE' name='MONTH_FEE' value='%MONTH_FEE%' placeholder='%MONTH_FEE%' class='form-control' type='text'>
    </div>
   </div>


<div class='form-group'>
  <label class='control-label col-md-3' for='DAY_FEE'>_{DAY_FEE}_:</label>
  <div class='col-md-9'>
      <input id='DAY_FEE' name='DAY_FEE' value='%DAY_FEE%' placeholder='%DAY_FEE%' class='form-control' type='text'>
    </div>
   </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='FILTER_ID'>Filter-ID:</label>
  <div class='col-md-9'>
      <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%' class='form-control' type='text'>
    </div>
</div>

    <div class='box-footer'>
        <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>


</fieldset>

</form>

</div>
</div>
