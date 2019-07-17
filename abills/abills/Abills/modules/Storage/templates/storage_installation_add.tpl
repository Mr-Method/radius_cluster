<form action='$SELF_URL' id='storage_installation_form' name='storage_installation_name' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='INSTALLED_AID' value='%INSTALLED_AID%'/>
  <!--
      <input type=hidden name=STREET_ID value='%STREET_ID%' ID='STREET_ID'>
      <input type=hidden name=LOCATION_ID value='%LOCATION_ID%' ID='LOCATION_ID'>
      <input type=hidden name=DISTRICT_ID value='%DISTRICT_ID%' ID='DISTRICT_ID'>
      -->

  <div class='box box-theme box-form'>
    <div class='box-header with-title'>
      <h4>_{INSTALLATION}_</h4>
    </div>
    <div class='box-body form'>

      <div id='address_form_source'>
        %ADDRESS_FORM%
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label' for='COUNT_id'>_{COUNT}_:</label>
        <div class='col-md-8'><input class='form-control' name='COUNT' id='COUNT_id' value='%COUNT%' type='number'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label' for='DATE_id'>_{DATE}_:</label>
        <div class='col-md-8'>
          <input class='form-control datepicker' name='DATE' id='DATE_id' value='%DATE%' type='text'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{SERIAL}_:</label>
        <div class='col-md-8'><textarea class='form-control' name='SERIAL'>%SERIAL%</textarea></div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{NAS}_:</label>
        <div class='col-md-8'>%NAS%</div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label' for='LOGIN'>_{USER}_:</label>
        <div class='col-md-9'>
          <input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
          <div class='col-md-10'>
            <input type='text' form='unexistent' class='form-control' name='LOGIN' value='%USER_LOGIN%' id='LOGIN' readonly='readonly'/>
          </div>
          <div class='col-md-2'>
            %USER_SEARCH%
          </div>
        </div>
      </div>
      <!--
      <div class='form-group'>
          <label class='col-md-3 control-label'>_{USER}_:</label>
          <div class='col-md-8'>%USER_SEL%</div>
      </div>
-->
    </div>
    <div class='box-footer'>
      <input type=submit name=install value='_{INSTALL}_' class='btn btn-primary'>
    </div>
  </div>

</form>
