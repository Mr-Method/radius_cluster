<form action='$SELF_URL' method='POST'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ARTICLE_ID' value='%ARTICLE_ID%'>
  <input type='hidden' name='MAIN_ARTICLE_ID' value='%SIA_ID%'>
  <input type='hidden' name='INCOMING_ARTICLE_ID' value='%STORAGE_INCOMING_ID%'>
  <input type='hidden' name='SELL_PRICE' value='%SELL_PRICE%'>
  <input type='hidden' name='RENT_PRICE' value='%RENT_PRICE%'>
  <input type='hidden' name='IN_INSTALLMENTS_PRICE' value='%IN_INSTALLMENTS_PRICE%'>
  <input type='hidden' name='SUM' value='%SUM%'>
  <input type='hidden' name='SUM_TOTAL' value='%TOTAL_SUM%'>
  <input type='hidden' name='TOTAL_COUNT' value='%TOTAL%'>

  %DIVIDE_TABLE%

  <input type='submit' name='divide_all' value='_{DIVIDE}_' class='btn btn-primary'>
</form>



<script>
  //    jQuery('#REG_REQUEST_BTN').prop('disabled', true);
  var timeout = null;

  function doDelayedSearch(val, element) {
    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function() {
      doSearch(val, element); //this is your existing function
    }, 500);
  };

  function doSearch(val, element) {
    if(!val){
      jQuery(element).parent().parent().removeClass('has-success').addClass('has-error');
      return 1;
    }
    jQuery.post('$SELF_URL', 'header=2&qindex=' + '%CHECK_SN_INDEX%' + '&sn_check=' + val, function (data) {
      console.log(data);
      if(data === 'success'){
        jQuery(element).parent().removeClass('has-error').addClass('has-success');
        jQuery(element).css('border', '3px solid green');
      }
      else{
        jQuery(element).parent().removeClass('has-success').addClass('has-error');
        jQuery(element).css('border', '3px solid red');
      }
    });
  }

  jQuery('.sn_check_class').on('input', function(event){
    console.log(this);
    var element = event.target;
    var value = jQuery(element).val();
    console.log(value);
    doDelayedSearch(value, element);
  });
</script>