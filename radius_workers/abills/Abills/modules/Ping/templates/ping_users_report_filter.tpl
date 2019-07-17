<form action='$SELF_URL' class='form-horizontal'>
  <input type=hidden  name=index value='$index'>

  <fieldset>

  <div class='box box-theme collapsed-box'>
        <div class="box-header with-border">
          <h3 class="box-title"><i class='fa fa-fw fa-filter'></i>_{FILTERS}_</h3>
          <div class="box-tools pull-right">
            <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
            </button>
          </div>
        </div>

        <div class='box-body' style="padding: 0px">

        <div style="padding: 10px">

            <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>Ping _{STATUS}_</label>
              <div class='col-md-10'>
                %PING_STATUS%
              </div>
            </div>

           <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>_{DATE}_</label>
              <div class='col-md-10'>
                %DATE_RANGE%
              </div>
            </div>
            <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>_{GROUP}_</label>
              <div class='col-md-10'>
                %GROUP_SEL%
              </div>
            </div>
            <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>_{LOGIN}_</label>
              <div class='col-md-10'>
                %USER_LOGIN%
              </div>
            </div>
        </div>

          <div class="box box-theme collapsed-box">
            <div class="box-header with-border">
              <h4 class="box-title">_{ADDRESS}_</h4>
              <div class="box-tools pull-right">
                <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
                </button>
              </div>
            </div>
            <div class="box-body">
              %ADDRESS_FORM%
            </div>
          </div>

          <div style="padding: 10px">
         <input name="apply" value="_{APPLY}_" class="btn btn-primary" type="submit">
         </div>
        </div>
      </div>
  </fieldset>
</form>