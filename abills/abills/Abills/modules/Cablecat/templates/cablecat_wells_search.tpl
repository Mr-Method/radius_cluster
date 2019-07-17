<div class='box box-theme'>
  <div class='box-header with-border'><h4 class='box-title'>_{WELL}_</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_WELLS' id='form_CABLECAT_WELLS' method='post' class='form form-horizontal'>
      <!--<input type='hidden' name='index' value='$index'/>-->
      <!--<input type='hidden' name='search_form' value='1'/>-->

      <div class='form-group'>
        <label class='control-label col-md-3' for='ID_id'>ID</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='ID' value='%ID%' id='ID_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 ' for='NAME_ID'>_{NAME}_</label>

        <div class='col-md-9'>
          <input type='text' class='form-control' value='%NAME%'  name='NAME' id='NAME_ID'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 ' for='TYPE_ID_SELECT'>_{TYPE}_</label>
        <div class='col-md-9'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='INSTALLED_ID'>_{INSTALLED}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control datepicker' value='%INSTALLED%' name='INSTALLED'
                 id='INSTALLED_ID'/>
        </div>
      </div>

      <div class='form-group should-be-hidden'>
        <label class='control-label col-md-3' for='POINT_ID'>_{OBJECT}_</label>
        <div class='col-md-9'>
          %POINT_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PARENT_ID'>_{INSIDE}_</label>
        <div class='col-md-9'>
          %PARENT_ID_SELECT%
        </div>
      </div>
    </form>

  </div>
</div>
