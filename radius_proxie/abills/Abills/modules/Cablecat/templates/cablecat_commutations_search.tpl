<div class="col-md-6">
  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{COMMUTATION}_ _{SEARCH}_</h4></div>
    <div class='box-body'>

      <!--<input type='hidden' name='index' value='$index'/>-->

      <div class='form-group'>
        <label class='control-label col-md-3' for='ID_ID'>ID</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%ID%' name='ID' id='ID_ID'/>
        </div>
      </div>


      <div class='form-group'>
        <label class='control-label col-md-3' for='CONNECTER'>_{CONNECTER}_</label>
        <div class='col-md-9'>
          %CONNECTER_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='WELL'>_{WELL}_</label>
        <div class='col-md-9'>
          %WELL_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CABLE'>_{CABLE}_</label>
        <div class='col-md-9'>
          %CABLE_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CREATED_ID'>_{CREATED}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control datepicker' value='%CREATED%' name='CREATED' id='CREATED_ID'/>
        </div>
      </div>

    </div>
  </div>
</div>