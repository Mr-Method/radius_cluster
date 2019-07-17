<div class='form-address'>
  <input type='hidden' name='DISTRICT_ID' value='%DISTRICT_ID%' class='HIDDEN-DISTRICT'>
  <input type='hidden' name='STREET_ID' value='%STREET_ID%' class='HIDDEN-STREET'>
  <input type='hidden' name='LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

  <div class='form-group'>

    <div class='col-xs-12 col-md-4'>
      <select name='ADDRESS_DISTRICT' class='form-control SELECT-DISTRICT'
              data-fieldname='DISTRICT' data-download-on-click='1'>
        <option value='%DISTRICT_ID%' selected>%ADDRESS_DISTRICT%</option>
      </select>
    </div>

    <div class='col-xs-12 col-md-4'>
      <select name='ADDRESS_STREET' class='form-control SELECT-STREET'
              data-fieldname='STREET' data-download-on-click='1'>
        <option value='%STREET_ID%' selected>%ADDRESS_STREET%</option>
      </select>
    </div>

    <div class='col-xs-12 col-md-4'>

      <div class='addBuildMenu' >
        <div class='input-group'>
          <select name='ADDRESS_BUILD' class='form-control SELECT-BUILD'
                  data-fieldname='BUILD' data-download-on-click='1'>
            <option value='%ADDRESS_BUILD%' selected>%ADDRESS_BUILD%</option>
          </select>

          <!-- Control for toggle build mode SELECT/ADD -->
          <span class='input-group-addon' %HIDE_ADD_BUILD_BUTTON%>
            <a title='_{ADD}_ _{BUILDS}_' class='BUTTON-ENABLE-ADD'>
              <span class='glyphicon glyphicon-plus'></span>
            </a>
          </span>

        </div>
      </div>

      <div class='changeBuildMenu' style='display : none'>
        <div class='input-group'>
          <input type='text' name='ADD_ADDRESS_BUILD' class='form-control INPUT-ADD-BUILD'/>

          <span class='input-group-addon'>
            <a class='BUTTON-ENABLE-SEL'>
              <span class='glyphicon glyphicon-list'></span>
            </a>
           </span>

        </div>
      </div>

    </div>

  </div>
</div>

<script src='/styles/default_adm/js/searchLocation.js'></script>

