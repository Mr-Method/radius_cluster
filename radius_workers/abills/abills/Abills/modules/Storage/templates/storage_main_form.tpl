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
    <div class='col-md-9'>%DATE_TIME_PICKER%</div>
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
    <label class='col-md-3'>_{SELL_PRICE}_ (_{PER_ONE_ITEM}_): </label>
    <div class='col-md-9'><input class='form-control' name='SELL_PRICE' type='text' value='%SELL_PRICE%'   /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{RENT_PRICE}_ (_{MONTH}_): </label>
    <div class='col-md-9'><input class='form-control' name='RENT_PRICE' type='text' value='%RENT_PRICE%'   /></div>
  </div>
  <div class='form-group'>
    <label class='col-md-3'>_{BY_INSTALLMENTS}_: </label>
    <div class='col-md-9'><input class='form-control' name='IN_INSTALLMENTS_PRICE' type='text' value='%IN_INSTALLMENTS_PRICE%'   /></div>
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
      <input class='form-control' id='SN' name='SERIAL' type='%INPUT_TYPE%' value='%SERIAL%' /> %DIVIDE_BTN% </div>
  </div>
  <div class='form-group' %SN_COMMENTS_HIDDEN%>
    <label class='col-md-3 control-label'>_{NOTES}_: </label>
    <div class='col-md-9'>
      <textarea class='form-control' name='SN_COMMENTS'>%SN_COMMENTS%</textarea>
    </div>
  </div>
  %PROPERTIES%
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

<script>
  //    jQuery('#REG_REQUEST_BTN').prop('disabled', true);
  var timeout = null;
  var start_value = jQuery('#SN').val();
  console.log("Start value - " + start_value);

  function doDelayedSearch(val) {
    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function() {
      doSearch(val); //this is your existing function
    }, 500);
  };

  function doSearch(val) {
    if(!val){
      jQuery('#SN').parent().parent().removeClass('has-success').addClass('has-error');
      return 1;
    }
    jQuery.post('$SELF_URL', 'header=2&qindex=' + '%CHECK_SN_INDEX%' + '&sn_check=' + val, function (data) {
      console.log(data);
      console.log( val + " - " + start_value);
      if(data === 'success'){
        jQuery('#SN').parent().parent().removeClass('has-error').addClass('has-success');
        jQuery('#SN').css('border', '3px solid green');
      }
      else if(val === start_value){
        jQuery('#SN').parent().parent().removeClass('has-error').addClass('has-success');
        jQuery('#SN').css('border', '3px solid green');
      }
      else{
        jQuery('#SN').parent().parent().removeClass('has-success').addClass('has-error');
        jQuery('#SN').css('border', '3px solid red');
      }

    });
  }
  jQuery('#SN').on('input', function(){
    var value = jQuery('#SN').val();
    doDelayedSearch(value)
  });
</script>