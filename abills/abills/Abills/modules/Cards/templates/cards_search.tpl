<div class="col-md-6">
  <div class='box box-theme'>
    <div class='box-body'>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{SERIAL}_ (*):</label>

        <div class='col-md-9'><input class='form-control' type='text' name='SERIAL' value='%SERIAL%' size=8/>
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'> _{NUM}_ (<,>): </label>

        <div class='col-md-9'><input class='form-control' type='text' name='NUMBER' value='%NUMBER%'></div>


      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>PIN:</label>

        <div class='col-md-9'>
          <input class='form-control' type='text' name='PIN' value='%PIN%'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{SUM}_:</label>

        <div class='col-md-9'>
          <input class='form-control' type='text' name='SUM' value='%SUM%' size=8/>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="row">
  <div class="col-md-12">
    <div class='box box-theme'>
      <div class='box-body'>
        <div class='form-group'>
          <div class='col-md-6'>
            <label class='col-md-4 control-label'>_{USED}_:</label>

            <div class='col-md-8'>%DATE%</div>
          </div>
          <div class='col-md-6'>
            <label class='col-md-3 control-label'>_{EXPIRE}_:</label>

            <div class='col-md-9'>%EXPIRE_DATE%</div>
          </div>
        </div>

        <div class='form-group'>
          <div class='col-md-6'>
            <label class='col-md-3 control-label'>_{DILLERS}_:</label>

            <div class='col-md-9'>%DILLERS_SEL%</div>
          </div>
          <div class='col-md-6'>
            <label class='col-md-5 control-label'>_{ADMINS}_:</label>

            <div class='col-md-7'>%ADMINS_SEL%</div>
          </div>
        </div>

        <div class='box box-default collapsed-box'>
          <div class='box-header with-border'>
            <h3 class='box-title'>_{EXTRA}_</h3>
            <div class='box-tools pull-right'>
              <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='box-body'>

            <div class='form-group'>
              <label class='col-md-3 control-label'>_{STATUS}_:</label>

              <div class='col-md-9'>%STATUS_SEL%</div>
            </div>

            <div class='form-group'>
              <label class='col-md-3 control-label'>ID:</label>

              <div class='col-md-9'>
                <input class='form-control' type='text' name='ID' value='%ID%' size=8></div>
            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{DOMAIN}_:</label>

              <div class='col-md-9'>%DOMAIN_SEL%</div>
            </div>

          </div>
        </div>


      </div>
    </div>
  </div>
</div>