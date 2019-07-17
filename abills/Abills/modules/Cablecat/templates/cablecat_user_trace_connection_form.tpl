<div class='row'>
  <div class='col-md-3'>
    <div class='form-group'>
      <label class='control-label col-md-12' for='UID'>_{USER}_</label>
      <div class='col-md-12'>
        <div class='input-group'>
          %USER_SELECT%
          <span class='input-group-btn'>
           %SEARCH_BTN%
          </span>
        </div>
      </div>
    </div>
  </div>
  <div class='col-md-6'>
    <div class='form-group'>
      <label class='control-label col-md-12' for='ENDPOINT_NAS_ID'>_{TRACE_UP_TO}_</label>
      <div class='col-md-12'>
        %USER_SERVICE_SELECT%
      </div>
    </div>
  </div>
  <div class='col-md-3'>
    <div class='col-md-12'></div>
    <div class='col-md-12'>
      <input type='submit' class='btn btn-primary btn-lg' name='action' value='_{SHOW}_' />
    </div>
  </div>
</div>

<div class='text-left'>
  %PATH_VIEW%
</div>

<script>
  jQuery(function () {
    var index            = '$index';
    var uid_input        = jQuery('input#UID');
    var equipment_select = jQuery('select#NAS_ID');
    var endpoint_select  = jQuery('select#ENDPOINT_NAS_ID');

    function updateSelectValues(select, new_options_html){

      var old_value = select.val();
      select.empty().html(new_options_html);
      updateChosen(function(){
        select.trigger('change');
        if (old_value){
          renewChosenValue(select, old_value);
        }
      });
    }

    function requestEquipment() {
      var uid = uid_input.val();

      jQuery.get('?qindex=' + index + '&header=2&UID=' + uid + '&get_nases=1&as_option=1', function (data) {
        updateSelectValues(equipment_select, data);
      });
    }

    function requestEndPoints() {
      var nas_id = equipment_select.val();

      jQuery.get('?qindex=' + index + '&header=2&NAS_ID=' + nas_id + '&get_endpoints=1&as_option=1', function (data) {
        updateSelectValues(endpoint_select, data);
      });
    }

    if (uid_input.val() && !equipment_select.val()) {
      requestEquipment();
    }
    else if (equipment_select.val()) {
      requestEndPoints();
    }

    uid_input.on('change', requestEquipment);
    equipment_select.on('change', requestEndPoints);
  });
</script>