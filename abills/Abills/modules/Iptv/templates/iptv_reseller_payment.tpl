<form class='form-horizontal' METHOD='POST'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='%UID%'>
  
  <div class='box box-theme box-big-form' data-action="wizard">
    <div class='box-header with-border'><h3 class="box-title">_{PAYMENTS}_</h3>
      <div class="box-tools pull-right">
      </div>
    </div>

    <div class="box-body">

      <div class='form-group'>
        <label class='control-label col-xs-3' for='SUM'>_{SUM}_</label>
        <div class='col-xs-9'>
          <input name='SUM' class='form-control' id='SUM' type='number' step='0.01'>
        </div>
      </div>  

      <div class='form-group'>
        <label class='control-label col-sm-2 col-md-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-sm-10 col-md-9'>
           <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>
    <div class='box-footer'>
      <input type=submit class='btn btn-primary' name='make_payment' value='_{BALANCE_RECHARCHE}_'>
    </div>
  </div>

</form>