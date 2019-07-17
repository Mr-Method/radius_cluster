<script language='JavaScript'>
	function autoReload()	{
  	document.depot_form.type.value='prihod';
    document.depot_form.submit();
	}	
</script>

<form action='$SELF_URL'  name='depot_form' method=POST class='form-horizontal'>

<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type=hidden name=INCOMING_ID value=%STORAGE_INCOMING_ID%>
<input type=hidden name=type value=prihod2>
<input type=hidden name=add_article value=1>
<fieldset>

<div class='box box-theme box-form'>
<div class='box-body'>
<legend>_{ARTICLE}_</legend>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{TYPE}_:</label>
    <div class='col-md-9'>
    	%ARTICLE_TYPES%
    </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_:</label>
    <div class='col-md-9'>
    	%ARTICLE_ID%
    </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'>_{SUPPLIERS}_:</label>
    <div class='col-md-9'>%SUPPLIER_ID%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{DATE}_:</label>
    <div class='col-md-9'><input class='tcal form-control datepickerActive' name='DATE' type='text' value='%DATE%' /></div>
  </div>
   <div class='form-group'>
    <label class='col-md-3'>_{QUANTITY_OF_GOODS}_: </label>
    <div class='col-md-9'><input class='form-control' name='COUNT' type='text' value='%COUNT%' %DISABLED% /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{SUM_ALL}_: </label>
    <div class='col-md-9'><input class='form-control' name='SUM' type='text' value='%SUM%'  %DISABLED% /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{SELL_PRICE}_ (1 _{UNIT}_): </label>
    <div class='col-md-9'><input class='form-control' name='SELL_PRICE' type='text' value='%SELL_PRICE%'   /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{RENT_PRICE}_ (_{MONTH}_): </label>
    <div class='col-md-9'><input class='form-control' name='RENT_PRICE' type='text' value='%RENT_PRICE%'   /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{DEPOT_NUM}_: </label>
    <div class='col-md-9'>%STORAGE_STORAGES%
		</div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>SN: </label>
    <div class='col-md-9'>
      <input class='form-control' name='SN' type='hidden' value='%SN%' />
      <input class='form-control' name='SERIAL' type='%INPUT_TYPE%' value='%SERIAL%' /> %DIVIDE_BTN% </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9'><textarea class='form-control col-xs-12' name='COMMENTS'>%COMMENTS%</textarea></div>
  </div>
  
 	
</div>

	<div class='box-footer'>
    <input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
  </div>

</div>


</fieldset>
</form>
