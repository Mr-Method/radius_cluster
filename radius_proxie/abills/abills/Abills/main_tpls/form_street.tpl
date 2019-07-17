<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'>_{ADDRESS_STREET}_</div>

    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-sm-3' for='NAME'>_{NAME}_:</label>
        <div class='col-sm-9'>
            <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group' data-visible='%STREET_TYPE_VISIBLE%' style='display:none;'>
        <label class='control-label col-sm-3' for='NAME'>_{TYPE}_:</label>
        <div class='col-sm-9'>
          %STREET_TYPE_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-sm-3' for='DISTRICTS_SEL'>_{DISTRICTS}_:</label>
        <div class='col-sm-9'>
          %DISTRICTS_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-sm-3' for='SECOND_NAME'>_{SECOND_NAME}_</label>
        <div class='col-sm-9'>
        <input id='SECOND_NAME' name='SECOND_NAME' value='%SECOND_NAME%' placeholder='_{NAME}_' class='form-control' type='text'>
        </div>
      </div>
    </div>
    <div class='box-footer'>
     <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
