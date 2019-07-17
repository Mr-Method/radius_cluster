<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>
  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h3 class='box-title'>_{INFO}_</h3></div>
    <div class='box-body'>
      <div class='col-md-12 col-xs-12'>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-user'></span></span>
          <input class='form-control' type='text' readonly value='%FIO%' placeholder='_{FIO}_'>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-home'></span></span>
            <input class='form-control' type='text' readonly value='%CITY%, %ADDRESS_FULL%' placeholder='_{ADDRESS}_'>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-earphone'></span></span>
          <input class='form-control' type='text' readonly value='%PHONE%' placeholder='_{PHONE}_'>
        </div>
      </div>
      <div class='col-md-12 col-xs-12'>
        <div class='input-group' style='margin-top: 5px;'>
        <span class='input-group-addon'><span class='align-middle glyphicon glyphicon-exclamation-sign'></span></span>
        <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3' readonly>%COMMENTS%</textarea>
          </div>
        </div>
    </div>
  </div>
</form>
