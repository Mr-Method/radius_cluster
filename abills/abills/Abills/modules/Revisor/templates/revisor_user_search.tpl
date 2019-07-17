<form class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
  <div class='row'>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'><h3 class='box-title'>%TITLE%</h3>
        <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>  
        <div class='form-group' %DATE_FIELD%>
          <label class='control-label col-md-2' for='FROM_DATE'>_{FROM}_</label>
          <div class='col-md-4'>
            <input class='form-control' data-provide='datepicker' data-date-format="yyyy-mm-dd" value="%FROM_DATE%" name='FROM_DATE'>
          </div>
          <label class='control-label col-md-2' for='TO_DATE'>_{TO}_</label>
          <div class='col-md-4'>
            <input class='form-control' data-provide='datepicker' data-date-format="yyyy-mm-dd" value="%TO_DATE%" name='TO_DATE'>
          </div>
        </div>
      
        <div class="form-group" %IP_FIELD%>
          <label class='control-label col-md-2' for='IP_NUM'>IP</label>
          <div class='col-md-10'>
            <input name='IP_NUM' value='%IP_NUM%' class='form-control' type='text'>
          </div>
        </div>
        
        <div class="form-group" %IP_FIELD%>
          <label class='control-label col-md-2' for='CID'>CID</label>
          <div class='col-md-10'>
            <input name='CID' value='%CID%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class="form-group">
          <label class='control-label col-md-2' for='LOGIN'>_{LOGIN}_</label>
          <div class='col-md-10'>
            <input name='LOGIN' value='%LOGIN%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class="form-group">
          <label class='control-label col-md-2' for='FIO'>_{FIO}_</label>
          <div class='col-md-10'>
            <input name='FIO' value='%FIO%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class="form-group">
          <label class='control-label col-md-2' for='COMPANY_NAME'>_{COMPANY}_</label>
          <div class='col-md-10'>
            <input name='COMPANY_NAME' value='%COMPANY_NAME%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class="form-group">
          <label class='control-label col-md-2' for='ADDRESS_FULL'>_{ADDRESS}_</label>
          <div class='col-md-10'>
            <input name='ADDRESS_FULL' value='%ADDRESS_FULL%' class='form-control' type='text'>
          </div>
        </div>
      </div>
      <div class='box-footer'>
        <input type=submit name=search value='_{SEARCH}_' class='btn btn-primary'>
      </div>  
    </div>
  </div>
</form>