<form action='$SELF_URL' id='map_user_form' name='map_user_form' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <div class='row'>
    <div class='col-md-6'>
      <p class='text-left'>
        <a data-toggle='collapse' href='#maps_panel_filters' aria-expanded='false' class='collapsed'>
          <strong>_{FILTERS}_</strong>&nbsp;<span class='glyphicon glyphicon-chevron-down'></span>
        </a>
      </p>

      <div id='maps_panel_filters' class='panel-collapse collapse' aria-expanded='false'>
        <div class='box-body'>
          %FILTER_ROWS%
          <div class='form-group'>
            <input type='submit' name='show' value='_{APPLY}_' class='btn btn-primary'>
          </div>
        </div>
      </div>

    </div>

    <div class='col-md-6'>
      <p class='text-left'>

        <a data-toggle='collapse' href='#maps_panel_info' aria-expanded='false' class='collapsed'>
          <strong>_{INFO}_</strong>&nbsp;<span class='glyphicon glyphicon-chevron-down'></span>
        </a>
      </p>
      <div id='maps_panel_info' class='panel-collapse collapse' aria-expanded='false'>
        <div class='box-body'>
          %INFO_ROWS%
          <div class='form-group'>
            <input type='submit' name='show' value='_{APPLY}_' class='btn btn-primary'>
          </div>
        </div>
      </div>
    </div>
  </div>
</form>

<div class='row'>

  <div class='col-md-3 btn-group text-left' id='map_edit_controls'>

    <div data-visible='%SHOW_EDIT_CONTROLS%'>
      <a href='$SELF_URL?get_index=maps_edit&full=1' role='button' class='btn btn-sm btn-success'>
        <span class='glyphicon glyphicon-pencil'></span>&nbsp;_{EDIT}_
      </a>
      <!--<a class='btn btn-sm btn-default' role='button'>
        <span class='glyphicon glyphicon-new-window'></span>&nbsp;_{IN_NEW_WINDOW}_
      </a>-->
    </div>

  </div>

  <div class='col-md-3 btn-group' id='map_view_controls'></div>

</div>

<div class='row'>
  <div class='col-md-12'>
    <div class='btn-group btn-group-xs btn-group-justified' id='map_layer_controls'></div>
  </div>
</div>
