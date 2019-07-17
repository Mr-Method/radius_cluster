<form action='$SELF_URL' ID='mapUserShow' name='mapUserShow' class='form-inline'>
  <input type='hidden' name='index' value='$index'>

  <div class='navbar navbar-default form-inline'>
    <div class='form-group'>

      <a href='$SELF_URL?get_index=maps_add_2&header=1' target=_map class='btn btn-default'>
        <span class='glyphicon glyphicon-pencil'></span>&nbsp;_{EDIT}_
      </a>

      <a class='btn btn-default' id='districtButton2' onclick=fullScreenDistrict()>
        <span class='glyphicon glyphicon-new-window'></span>&nbsp;_{IN_NEW_WINDOW}_
      </a>

    </div>

    <div class='form-group'>
      %UFILTER%
    </div>

    <div class='form-group'>
      %GROUP_SEL%
    </div>

    <div class='form-group'>
      %INFO_MODULE%
    </div>


    %FILTER_ROWS%

    <input type=submit name=show value='_{SHOW}_' class='btn btn-default'>
  </div>
</form>