<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{EQUIPMENT}_ : %WELL%</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_COMMUTATION_ADD_EQUIPMENT_MODAL' id='CABLECAT_COMMUTATION_ADD_EQUIPMENT_MODAL' method='post'
          class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='operation' value='ADD'/>
      <input type='hidden' name='entity' value='EQUIPMENT'/>
      <input type='hidden' name='COMMUTATION_ID' value='%COMMUTATION_ID%'/>

      <div class="form-group">
        <label class="control-label col-md-3">_{EQUIPMENT}_</label>
        <div class="col-md-9">
          %EQUIPMENT_SELECT%
        </div>
      </div>

    </form>

  </div>

  <div class='box-footer'>
    <input type='submit' form='CABLECAT_COMMUTATION_ADD_EQUIPMENT_MODAL' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>

</div>
<script>
  jQuery(function () {
    jQuery('#CABLECAT_COMMUTATION_ADD_EQUIPMENT_MODAL').on('submit', ajaxFormSubmit);

    Events.off('AJAX_SUBMIT.CABLECAT_COMMUTATION_ADD_EQUIPMENT_MODAL');
    Events.once('AJAX_SUBMIT.CABLECAT_COMMUTATION_ADD_EQUIPMENT_MODAL', function (response) {
      if (response.MESSAGE_EQUIPMENT_ADDED) {
        aTooltip.displayMessage(response.MESSAGE_EQUIPMENT_ADDED, 2000);
        location.reload();
      }
    });
  });
</script>