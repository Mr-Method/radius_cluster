<form class='form-horizontal' action='$SELF_URL' method='post' id='admin_info'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=aedit value=1>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h3 class='box-title'>_{ADMIN}_</h3>
      <div class='box-tools pull-right'>
        %CLEAR_SETTINGS%
        %CHG_PSW%
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3' for='email'>E-mail</label>
        <div class='col-md-9'>
          <input id='email' name='email' value='%EMAIL%' class='form-control' type='text'>
        </div>
      </div>
          
      <div class='form-group'>
        <label class='control-label col-md-3' for='FIO'>_{FIO}_</label>
        <div class='col-md-9'>
          <input id='FIO' name='name' value='%A_FIO%' class='form-control' type='text'>
        </div>
      </div>
    </div>

    <div class='box-footer'>
      <input type='submit' name='change' value='_{CHANGE}_' class='btn btn-primary'>
    </div>
  </div>
</form>
      