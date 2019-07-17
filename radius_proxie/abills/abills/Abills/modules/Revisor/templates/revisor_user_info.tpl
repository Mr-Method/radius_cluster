<form class='form-horizontal' name='users_pi'>
<div class='row'>
  <div class='col-md-6'>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'><h3 class='box-title'>%LOGIN%</h3>
        <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-user'></span></span>
          <input class='form-control' type='text' disabled value='%FIO%' placeholder='_{NO}_'>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-home'></span></span>
          <input class='form-control' type='text' readonly value='%ADDRESS_FULL%' placeholder='_{NO}_'>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='glyphicon glyphicon-earphone'></span></span>
          <input class='form-control' type='text' readonly value='%PHONE%' placeholder='_{NO}_'>
        </div>
      </div>
    
      <div class='box collapsed-box' style='margin-bottom: 0px; border-top-width: 1px;'>
        <div class='box-header with-border'>
          <h3 class='box-title'>_{PASPORT}_</h3>
          <div class='box-tools pull-right'>
            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='box-body'>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='PASPORT_NUM'>_{NUM}_</label>
            <div class='col-xs-8 col-sm-4'>
              <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                     placeholder='%PASPORT_NUM%'
                     class='form-control' type='text'>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
            <label class='control-label col-xs-4 col-md-2' for='PASPORT_DATE'>_{DATE}_</label>
            <div class='col-xs-8 col-sm-4'>
              <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                     class='datepicker form-control'>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='PASPORT_GRANT'>_{GRANT}_</label>
            <div class='col-xs-8 col-md-10'>
                    <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT'
                              rows='2'>%PASPORT_GRANT%</textarea>
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>
  <div class='col-md-6'>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'><h3 class='box-title'>_{STATUS}_</h3>
        <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>
        <div class='form-group'>
          <label class='control-label col-md-4' for='STATUS'>_{STATUS}_</label>
          <div class='col-md-8'>
            <input class='form-control' type='text' readonly value='%STATUS%' placeholder='_{NO}_'>
          </div>
        </div>
        <div class='form-group'>
          <label class='control-label col-md-4' for='IP_NUM'>%IP_TEXT%</label>
          <div class='col-md-8'>
            <input class='form-control' type='text' readonly value='%IP_NUM%' placeholder='_{NO}_'>
          </div>
        </div>
        <div class='form-group' %STATIC_IP_HIDDEN% >
          <label class='control-label col-md-4' for='STATIC_IP'>%STATIC_IP_TEXT%</label>
          <div class='col-md-8'>
            <input class='form-control' type='text' readonly value='%STATIC_IP%' placeholder='_{NO}_'>
          </div>
        </div>
        %BUTTON%
      </div>
    </div>  
  </div>
</div>  
</form>