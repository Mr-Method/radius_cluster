<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{CABLE}_</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_CABLE' id='form_CABLECAT_CABLE' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='TYPE_ID'>_{CABLE_TYPE}_</label>
        <div class='col-md-9'>
          %CABLE_TYPE_SELECT%
        </div>
      </div>

      <hr>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{WELL}_ 1</label>
        <div class='col-md-9'>
          %WELL_1_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{WELL}_ 2</label>
        <div class='col-md-9'>
          %WELL_2_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='LENGTH_F_id'>_{LENGTH}_, _{METERS_SHORT}_</label>
        <div class='col-md-6'>
          <input type='text' class='form-control' name='LENGTH' value='%LENGTH%' id='LENGTH_F_id'/>
        </div>
        <div class='col-md-3' data-tooltip='_{CALCULATED}_'>
          <button type='button' class='btn btn-default' id='COPY_LENGTH_CALCULATED'>
            <span class='glyphicon glyphicon-arrow-left'></span>
            %LENGTH_CALCULATED%
          </button>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='RESERVE_id'>_{RESERVE}_, _{METERS_SHORT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='RESERVE' value='%RESERVE%' id='RESERVE_id'/>
        </div>
      </div>

      %OBJECT_INFO%

    </form>
  </div>
  <div class='box-footer'>
    <input type='submit' form='form_CABLECAT_CABLE' id='go' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

<script>

  jQuery(function () {

    jQuery('button#COPY_LENGTH_CALCULATED').on('click', function () {
      jQuery('input#LENGTH_F_id').val('%LENGTH_CALCULATED%');
    });

    function get_well_name(well_select, callback){
      var well_id = well_select.val();
      var well_name = well_select.find('option[value="' + well_id + '"]').text();

      if (well_name){
        callback(well_name);
      }
      else {
        return '';
//        jQuery.getJSON('?get_index=cablecat_wells&header=2&chg=' + well_id + '&json=1&TEMPLATE_ONLY=1', function(response){
//          if (response && response.NAME){
//            callback(response.NAME);
//          }
//        });
      }
    }

    function update_cable_name(well_1_name, well_2_name){
      jQuery('input#NAME_id').val(well_1_name + '-' + well_2_name);
    }

    function on_well_changed(){
      get_well_name(jQuery('select#WELL_1'), function(well_1_name){
        get_well_name(jQuery('select#WELL_2'), function(well_2_name){
          update_cable_name(well_1_name, well_2_name);
        });
      })
    }

    jQuery('select#WELL_1').on('change', on_well_changed);
    jQuery('select#WELL_2').on('change', on_well_changed);

  });



</script>

