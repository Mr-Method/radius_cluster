<form action=$SELF_URL name='portal_form' method=POST class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>


<div class='box box-theme box-form'>
<div class='box-header with-border'>%TITLE_NAME%</div>
<div class='box-body'>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{DATE_PUBLICATE}_:</label>
    <div class='col-md-9'>
      <input class='form-control datepicker' placeholder='0000-00-00' name='DATE' value='%DATE%'>
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{DATE_END}_:</label>
    <div class='col-md-9'>
      <input class='form-control datepicker' placeholder='0000-00-00' name='END_DATE' value='%END_DATE%'>
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{MENU}_:</label>
    <div class='col-md-9'>%PORTAL_MENU_ID%</div>
  </div>
  <div class='form-group'>
      <label class='col-md-12 label-primary'>_{CONTENT}_</label>
  </div>

  <div class='form-group'>
      <label class='col-md-12'>_{TITLE}_:</label>
    <div class='col-md-12'>
      <input class='form-control' name='TITLE' type='text' value='%TITLE%' size=90 align=%ALIGN% />
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-12'>_{SHORT_DESCRIPTION}_:</label>
    <div class='col-md-12'>
      <textarea class='form-control' name='SHORT_DESCRIPTION' cols=90 rows=5>%SHORT_DESCRIPTION%</textarea>
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-12'>_{TEXT}_:</label>
    <div class='col-md-12'>
      <textarea class='form-control' name='CONTENT' cols=90 rows=21>%CONTENT%</textarea>
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-12'>_{SHOW}_:</label>
    <div class='col-md-12'>
      <div class='col-md-6'>
          <input type='radio' name='STATUS' value=1 %SHOWED%>_{SHOW}_
      </div>
      <div class='col-md-6'>
          <input type='checkbox' name='ON_MAIN_PAGE' value=1 %ON_MAIN_PAGE_CHECKED%>_{ON_MAIN_PAGE}_
      </div>
      <div class='col-md-6'>
          <input type='radio' name='STATUS' value=0 %HIDDEN%>_{HIDE}_
      </div>
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-12 label-primary'>_{USER_CONF}_</label>
  </div>

  <div class='form-group'>
      <label class='col-md-4'>_{USER_PORTAL}_</label>

      <div class='col-md-4'>
          <input type='radio' name='ARCHIVE' value=1 %SHOWED_ARCHIVE%>_{SHOW}_
      </div>
      <div class='col-md-4'>
          <input type='radio' name='ARCHIVE' value=0 %HIDDEN_ARCHIVE%>_{TO_ARCHIVE}_
      </div>

  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{IMPORTANCE}_:</label>
    <div class='col-md-9'>
      %IMPORTANCE_STATUS%
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{GROUPS}_:</label>
    <div class='col-md-9'>
      %GROUPS%
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{TAGS}_:</label>
    <div class='col-md-9'>
      %TAGS%
    </div>
  </div>

    %ADRESS_FORM%

  <div class='form-group'>
      <label class='checkbox-inline'><input type='checkbox' name='RESET' value='1'>_{RESET_ADDRESS}_</label>
  </div>

  </div>


<div class='box-footer'>
  <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
</div>

</div>
</form>
