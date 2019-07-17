<div id='POINT_INFO_BLOCK'>
  <hr/>

  <!--<div class='form-group'>
    <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
    </div>
  </div>-->
  <div class='form-group'>
    <div class='col-md-1 col-md-offset-11'>
      <a id='point_info_edit_btn' title='_{EDIT}_' target='_blank'>
        <span class='glyphicon glyphicon-edit'></span>
      </a>
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-3'>_{CREATED}_</label>
    <div class='col-md-9'>
      <p class='form-control-static'>%CREATED%</p>
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-3'>_{PLANNED}_</label>
    <div class='col-md-9'>
      <p class='form-control-static'>%PLANNED_NAMED%</p>
    </div>

    <div class='form-group' data-visible='%SHOW_MAP_BTN%'>
      <label class='form-control-label col-md-3'>_{MAP}_</label>
      <div class='col-md-9'>%MAP_BTN%</div>
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-3'>_{ADDRESS}_</label>
    <div class='col-md-9'>
      <p class='form-control-static'>%ADDRESS_NAME%</p>
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <p class='form-control-static'>%COMMENTS%</p>
    </div>
  </div>
</div>
<script>
  jQuery(function () {

    var btn = jQuery('#point_info_edit_btn');
    btn.on('click', function () {
      // Load modal
      loadToModal('$SELF_URL?get_index=maps_objects_main&TEMPLATE_ONLY=1&header=2&chg=%ID%');

      // When submitted, renew
      Events.once('AJAX_SUBMIT.form_MAPS_OBJECT', function () {
        aModal.hide();
        jQuery('#POINT_INFO_BLOCK').load(' #POINT_INFO_BLOCK');
      })
    });
  })
</script>
