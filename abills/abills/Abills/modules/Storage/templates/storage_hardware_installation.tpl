<script language='JavaScript'>
  function autoReload() {
    document.storage_hardware_form.type.value = 'prihod';
    document.storage_hardware_form.submit();
  }

  function rebuild_form(status){
    console.log(status);
    if(status == 3){
      console.log("Add monthes input");
      var element = jQuery("<div></div>").addClass("form-group appended_field");
      element.append(jQuery("<label for=''></label>").text("_{MONTHES}_").addClass("col-md-3 control-label"));
      element.append(jQuery("<div></div>").addClass("col-md-9").append(
        jQuery("<input name='MONTHES' id='MONTHES' value='%MONTHES%'>").addClass("form-control")));

      jQuery('#storage_monthes_by_installments').append(element);
    }
    else{
      console.log("Remove monthes input");
      jQuery('.appended_field').remove();
    }
  }

  jQuery(function () {
    if(jQuery('#STATUS').val()) {
      rebuild_form(jQuery('#STATUS').val());
    }

    jQuery("#STATUS").change(function () {
      rebuild_form(jQuery('#STATUS').val());

    });
  });
</script>

<form action=$SELF_URL name='storage_hardware_form' method=POST class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=%ID%>
  <input type=hidden name='type' value='prihod2'>
  <input type=hidden name=ajax_index value=$index>
  <input type=hidden name=UID value=$FORM{UID}>
  <input type=hidden name=OLD_MAC value=%OLD_MAC%>
  <input type=hidden name=COUNT1 value=%COUNT1%>
  <input type=hidden name=ARTICLE_ID1 value=%ARTICLE_ID1%>
  <input type=hidden name='step' value='$FORM{step}'>
  <fieldset>
    <div class='box box-theme box-form'>
      <div class='box-body form'>

        <legend>_{STORAGE}_</legend>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{TYPE}_:</label>
          <div class='col-md-9'>%ARTICLE_TYPES%</div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{NAME}_:</label>
          <div class='col-md-9'>%ARTICLE_ID%</div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{COUNT}_:</label>
          <div class='col-md-9'><input class='form-control' name='COUNT' type='text' value='%COUNT%' %DISABLE%/></div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{ACTION}_:</label>
          <div class='col-md-9'>%STATUS% %STORAGE_DOC_CONTRACT% %STORAGE_DOC_RECEIPT%</div>
        </div>
        <div id='storage_monthes_by_installments'>

        </div>

        <div class='form-group'>
          <label class='col-md-3 control-label'>SN:</label>
          <div class='col-md-9'><textarea class='form-control col-xs-12' name='SERIAL'>%SERIAL%</textarea></div>
        </div>

        <div class='form-group'>
          <label class='col-md-3 control-label'>_{INSTALLED}_:</label>
          <div class='col-md-9'>%INSTALLED_AID_SEL%</div>
        </div>
<!--
        <div class='form-group'>
          <label class='col-md-3 control-label'>Grounds:</label>
          <div class='col-md-9'><input class='form-control' name='GROUNDS' type='text' value='%GROUNDS%'/></div>
        </div>
-->
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
          <div class='col-md-9'><input name='COMMENTS' class='form-control' type='text' value='%COMMENTS%'/></div>
        </div>

        %DHCP_ADD_FORM%

      </div>
      <div class='box-footer'>
        %BACK_BUTTON% <input type=submit name='%ACTION%' value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
      </div>
    </div>
  </fieldset>
</form>
