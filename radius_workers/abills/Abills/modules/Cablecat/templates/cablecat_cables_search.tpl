<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{CABLE}_</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_CABLE' id='form_CABLECAT_CABLE' method='post' class='form form-horizontal'>
      <!--<input type='hidden' name='index' value='$index'/>-->
      <!--<input type='hidden' name='search_form' value='1'/>-->

      <div class='form-group'>
        <label class='control-label col-md-3' for='ID_id'>ID</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='ID' value='%ID%' id='ID_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='TYPE_ID'>_{CABLE_TYPE}_</label>
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
        <div class='col-md-9'>
          <input type='text' class='form-control' name='LENGTH' value='%LENGTH%' id='LENGTH_F_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='RESERVE_id'>_{RESERVE}_, _{METERS_SHORT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='RESERVE' value='%RESERVE%' id='RESERVE_id'/>
        </div>
      </div>

    </form>
  </div>
</div>