<form class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
  <div class='row'>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'><h3 class='box-title'>Период</h3>
        <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>  

        <div class='form-group' %DATE_FIELD%>
          <label class='control-label col-md-2' for='FROM_DATE'>с</label>
          <div class='col-md-4'>
            <input class='form-control' data-provide='datepicker' data-date-format="yyyy-mm-dd" value="%FROM_DATE%" name='FROM_DATE'>
          </div>
          <label class='control-label col-md-2' for='TO_DATE'>по</label>
          <div class='col-md-4'>
            <input class='form-control' data-provide='datepicker' data-date-format="yyyy-mm-dd" value="%TO_DATE%" name='TO_DATE'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-2' for='NAME_id'>Hotspot</label>
          <div class='col-md-10'>
            <input type='text' class='form-control' value='%HOSTNAME%' name='HOSTNAME' id='NAME_id'/>
          </div>
        </div>

      </div>
      <div class='box-footer'>
        <input type=submit name=search value='_{SHOW}_' class='btn btn-primary'>
      </div>  
    </div>
  </div>
</form>
