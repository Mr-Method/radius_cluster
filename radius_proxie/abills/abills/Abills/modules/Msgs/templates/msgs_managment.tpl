<script>
  jQuery(function () {
    //cache DOM
    var shedule_link  = jQuery('#sheduleTableBtn');
    var plan_time     = jQuery('#PLAN_TIME');
    var plan_date     = jQuery('#PLAN_DATE');
    var plan_datetime = jQuery('#PLAN_DATETIME');

    var update_shedule_link = function (new_date) {
      if (!new_date || new_date === '0000-00-00'){
        shedule_link.prop('disabled', true);
        shedule_link.addClass('disabled');
        return;
      }

      shedule_link.prop('disabled', false);
      shedule_link.removeClass('disabled');

      shedule_link.attr('href', shedule_link.attr('data-link') + new_date);
    };

    update_shedule_link(plan_date.val());

    plan_datetime.on('dp.change', function (datetimepicker_change_event) {
      var new_moment = datetimepicker_change_event.date;
      var new_date = '';
      var new_time = '';

      if (new_moment){
        new_date   = new_moment.format('YYYY-MM-DD');
        new_time   = new_moment.format('HH:MM:SS');
      }

      plan_date.val(new_date);
      plan_time.val(new_time);

      update_shedule_link(new_date);
    });

  });
</script>

<div class='box box-theme form form-horizontal'>
  <div class='box-header with-border'>
    <h6 class='box-title'>_{MANAGE}_</h6>
  </div>

  <div class='box-body'>

    <div class='form-group'>
      <div class='col-md-12'>
      %MAP%
      </div>
    </div>

    <div class='form-group'>
      <div class='col-md-12'>
        <div class="btn-group" role="group" aria-label="Basic example">
        %WATCH_BTN% %EXPORT_BTN% %HISTORY_BTN%
        <a href='$SELF_URL?index=$index&deligate=$FORM{chg}&level=%DELIGATED_DOWN%'
           class='btn btn-default ' TITLE='_{COMPETENCE}_ _{DOWN}_ (%DELIGATED_DOWN%)'>
          <span class="glyphicon glyphicon-hand-down"></span>
        </a>
        <a href='$SELF_URL?index=$index&deligate=$FORM{chg}&level=%DELIGATED%'
           class='btn btn-default ' TITLE='_{COMPETENCE}_ _{UP}_ (%DELIGATED%)'>
          <span class="glyphicon glyphicon-hand-up"></span>
        </a>
        %INNER_MSG_TEXT%
        %WORK_BTN%
        %MSG_PRINT_BTN%
        %ADD_TAGS_BTN%
        %WORKPLANNING_BTN%
        %MSGS_TASK_BTN%
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='col-md-12 text-left'>
        <p class='form-control-static' title='_{ADDRESS}_'>
          <span class='glyphicon glyphicon-home'></span>
          %ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%
        </p>
        <p class='form-control-static' title='_{PHONE}_' data-visible='_{PHONE}_'>
          <span class='glyphicon glyphicon-phone'></span>
          %PHONE%
        </p>
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{RESPOSIBLE}_:</label>
      <div class='col-md-12'>
        %RESPOSIBLE_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{PRIORITY}_:</label>
      <div class='col-md-12'>
        %PRIORITY_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12' for='PLAN_TIME'>_{EXECUTION}_:</label>
      <div class='col-md-12'>
        <input type='hidden' value='%PLAN_TIME%' name='PLAN_TIME' id='PLAN_TIME'/>
        <input type='hidden' value='%PLAN_DATE%' name='PLAN_DATE' id='PLAN_DATE'/>
        %PLAN_DATETIME_INPUT%
      </div>
      <div class='col-md-12'>
        <a data-link='%SHEDULE_TABLE_OPEN%' id='sheduleTableBtn' class='btn btn-default btn-sm form-control'>
          <span class='glyphicon glyphicon-tasks'></span>
          _{SHEDULE_BOARD}_
        </a>
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{DISPATCH}_:</label>
      <div class='col-md-12'>
        %DISPATCH_SEL%
      </div>
    </div>

    <div class='form-group'>
      <div class='box collapsed-box col-md-12'>
        <div class='box-header'><h4 class='box-title'>
          <span class='glyphicon glyphicon-time'></span>
          _{EXTRA}_
        </h4>
          <div class='box-tools pull-right'>
            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>

        <div class='box-body'>

          <div class='form-group' data-visible='%A_NAME%'>
            <label class='col-md-12'>_{ADMIN}_:</label>
            <div class='col-md-12'>
              %A_NAME%
            </div>
          </div>


          <div class='form-group'>
            <label class='col-md-12'>_{UPDATED}_:</label>
            <div class='col-md-12'>
              <p class='form-control-static'>
                %LAST_REPLIE_DATE%
              </p>
            </div>
          </div>

          <div class='form-group'>
            <label class='col-md-12'>_{CLOSED}_:</label>
            <div class='col-md-12'>
              <p class='form-control-static'>
                %CLOSED_DATE%
              </p>
            </div>
          </div>

          <div class='form-group'>
            <label class='col-md-12'>_{DONE}_:</label>
            <div class='col-md-12'>
              <p class='form-control-static'>
                %DONE_DATE%
              </p>
            </div>
          </div>

          <div class='form-group'>
            <label class='col-md-12'>
            <span class='glyphicon glyphicon-eye-open'></span>
              _{USER}_:
            </label>

            <div class='col-md-12'>
              <p class='form-control-static'>
                %USER_READ%
              </p>
            </div>
          </div>

          <div class='form-group'>
            <label class='col-md-12'>
              <span class='glyphicon glyphicon-eye-open'></span>
              _{ADMIN}_:
            </label>

            <div class='col-md-12'>
              <p class='form-control-static'>
                %ADMIN_READ%
              </p>
            </div>
          </div>

          <div class='form-group'>
            <label class='col-md-12'>_{TIME_IN_WORK}_:</label>

            <div class='col-md-12'>
              <p class='form-control-static'>
                %TICKET_RUN_TIME%
              </p>
            </div>
          </div>


        </div>

      </div>
      <div>%TASKS_LIST%</div>
    </div>


  </div>
  <div class='box-footer'>
    <input type=submit name=change value='_{CHANGE}_' class='btn btn-primary btn-sm'>
  </div>
</div>



