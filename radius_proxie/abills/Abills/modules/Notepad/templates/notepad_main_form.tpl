<form class='form-horizontal' action=$SELF_URL name='notepad_form' method=POST>
  <input type=hidden name=index value=$index>
  <input type=hidden name=inventory_main value=1>
  <input type=hidden name=ID value=$FORM{chg}>


  <div class='box box-theme box-form'>
    <div class='box-body'>

      <!-- TAB NAVIGATION -->
      <ul class='nav nav-tabs' role='tablist'>
        <li class='active'>
          <a href='#time_explicit_tab' role='tab' data-toggle='tab'>_{ONCE}_</a>
        </li>
        <li>
          <a href='#time_custom_tab' role='tab' data-toggle='tab'>_{PERIODICALLY}_</a>
        </li>
      </ul>

      <hr/>

      <!-- TAB CONTENT -->
      <div class='tab-content'>
        <div class='active tab-pane' id='time_explicit_tab'>
          <input type='hidden' name='EXPLICIT_TIME' value='1'/>

          <div class='form-group'>
            <label class='control-label col-md-2' for='NOTIFIED'>_{DATE}_:</label>
            <div class='col-md-10'>
              %DATETIMEPICKER%
            </div>
          </div>

        </div>
        <div class='tab-pane' id='time_custom_tab'>
          <input type='hidden' name='CUSTOM_TIME' disabled='disabled' value='1'/>


          <div class='form-group'>
            <div class='col-md-4'>
              <input type='text' class='form-control' name='MONTH_DAY' value='%MONTH_DAY%'
                     data-tooltip='_{DAY}_ : 1 <br /> _{DAYS}_ : 1,2,3,6'
                     data-tooltip-position='left'
                     placeholder='_{DAY}_' disabled='disabled'/>
            </div>
            <div class='col-md-4'>
              %MONTH_SELECT%
            </div>
            <div class='col-md-4'>
              <input type='text' class='form-control' name='YEAR' value='%YEAR%' placeholder='_{YEAR}_'
                     disabled='disabled'/>
            </div>
          </div>

          <hr/>

          <div class='form-group'>
            <div class='col-md-7'>
              <label class='control-label col-md-6'>_{DAY}_ _{WEEK}_</label>
              <div class='col-md-6'>
                %WEEK_DAY_SELECT%
              </div>
            </div>
            <div class='col-md-5'>
              <div class='checkbox text-center'>
                <label>
                  <input type='checkbox' data-return='1' data-checked='%HOLIDAYS%' name='HOLIDAYS' id='INCLUDING_HOLIDAYS' value='1' disabled='disabled'/>
                  <strong>_{HOLIDAY}_</strong>
                </label>
              </div>
            </div>
          </div>

          <hr/>

          <div class='form-group'>
            <label class='control-label col-md-3'>_{TIME}_</label>
            <div class='col-md-9'>
              <div class='col-md-5'>
                <input class='form-control' type='text' id='HOUR' name='HOUR' placeholder='09'
                       value='%HOUR%'/>
              </div>
              <div class='col-md-1 control-element'>
                <span>:</span>
              </div>
              <div class='col-md-5'>
                <input class='form-control' type='text' id='MINUTE' name='MINUTE' placeholder='00'
                       value='%MINUTE%'/>
              </div>
            </div>
          </div>
        </div>
      </div>

      <hr/>

      <div class='form-group'>
        <label class='control-label col-md-2'>_{STATUS}_:</label>
        <div class='col-md-10'>
          %STATUS%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-2' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-10'>
          <input class='form-control' type='text' name='SUBJECT' id='SUBJECT' required='required' value='%SUBJECT%'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-2' for='TEXT'>_{TEXT}_:</label>
        <div class='col-md-10'>
          <textarea name='TEXT' id='TEXT' rows='4' class='form-control'>%TEXT%</textarea>
        </div>
      </div>

    </div>
    <div class='box-footer'>
      <input class='btn btn-primary' type='submit' name='%ACTION%' value='%ACTION_LNG%'/>
    </div>
  </div>

</form>

<script>
  function disableInputs(context) {
    var inputs_wrapper = jQuery(jQuery(context).attr('href'));
    inputs_wrapper.find('input').prop('disabled', true);
    inputs_wrapper.find('select').prop('disabled', true);
    updateChosen();
  }

  function enableInputs(context) {
    var inputs_wrapper = jQuery(jQuery(context).attr('href'));
    inputs_wrapper.find('input').prop('disabled', false);
    inputs_wrapper.find('select').prop('disabled', false);
    updateChosen();
  }

  jQuery(function () {
    jQuery('a[data-toggle=\"tab\"]').on('shown.bs.tab', function (e) {
      enableInputs(e.target);
      disableInputs(e.relatedTarget);
    })
  });


</script>