<form action=$SELF_URL name='inventory_form' method=GET class='form-horizontal'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name=inventory_main value=1>
  <input type=hidden name=ID value='$FORM{chg}'>

<div class='box box-theme box-big-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{EQUIPMENT}_</h4></div>

  <div class='box-body'>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='HOSTNAME'>_{HOSTNAME}_</label>
      <div class='col-xs-8'>
        <input type=text name=HOSTNAME  value='%HOSTNAME%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='IP'>IP:</label>
      <div class='col-xs-8'>
        <input type=text name=IP  value='%IP%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='WEB_ACCESS_INFO'>WEB: _{ACCESS}_</label>
      <div class='col-xs-8'>
        <input type=text name=WEB_ACCESS_INFO  value='%WEB_ACCESS_INFO%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='ACCESS_INFO'>SSH: _{ACCESS}_</label>
      <div class='col-xs-8'>
        <input type=text name=ACCESS_INFO  value='%ACCESS_INFO%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='LOGIN'>_{LOGIN}_</label>
      <div class='col-xs-8'>
        <input type=text name=LOGIN  value='%LOGIN%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='PASSWORD'>_{PASSWD}_</label>
      <div class='col-xs-8'>
        <input type=text name=PASSWORD  value='%PASSWORD%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='SUPERPASSWORD'>root _{PASSWD}_</label>
      <div class='col-xs-8'>
        <input type=text name=SUPERPASSWORD  value='%SUPERPASSWORD%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='INTEGRATION_DATE'>_{INTEGRATION_DATE}_</label>
      <div class='col-xs-8'>
        <input type=text name=INTEGRATION_DATE  value='%INTEGRATION_DATE%' class='form-control datepicker'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='ADMIN_MAIL'>_{ADMIN_MAIL}_</label>
      <div class='col-xs-8'>
        <input type=text name=ADMIN_MAIL  value='%ADMIN_MAIL%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='BENCHMARK_INFO'>Benchmark _{INFO}_</label>
      <div class='col-xs-8'>
        <input type=text name=BENCHMARK_INFO  value='%BENCHMARK_INFO%' class='form-control'/>
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='RESPONSIBLE'>_{RESPONSIBLE}_</label>
      <div class='col-xs-8'>
        %ADMINS_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='STATUS_SEL'>_{STATUS}_</label>
      <div class='col-xs-8'>
        %STATUS_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label class='control-label col-xs-4' for='COMMENTS'>_{COMMENTS}_</label>
      <div class='col-xs-8'>
        <textarea name=COMMENTS rows=4 class='form-control'>%COMMENTS%</textarea>
      </div>
    </div>


  <div class='box box-default box-big-form collapsed-box'>
    <div class='box-header with-border'>
      <h3 class='box-title'>Hardware</h3>
      <div class='box-tools pull-right'>
        <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>
    %HARDWARE%
  </div>
  </div>



<div class='box box-default box-big-form collapsed-box'>
<div class='box-header with-border'>
  <h3 class='box-title'>Software</h3>
  <div class='box-tools pull-right'>
    <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
    </button>
  </div>
</div>
<div class='box-body'>
 %SOFTWARE%
</div>
</div>


  </div>

  <div class='box-footer'>
    <input type=submit name=%ACTION% value=%ACTION_LNG% class='btn btn-primary'> %DEL_BUTTON%
  </div>

</div>

</form>