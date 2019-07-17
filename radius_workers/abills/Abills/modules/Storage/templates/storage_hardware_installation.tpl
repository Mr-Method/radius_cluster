<script language='JavaScript'>
  function autoReload() {
    document.storage_hardware_form.type.value = 'prihod';
    document.storage_hardware_form.submit();
  }
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

        <div class='form-group'>
          <label class='col-md-3 control-label'>_{SERIAL}_:</label>
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
        <input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
      </div>
    </div>
  </fieldset>
</form>
