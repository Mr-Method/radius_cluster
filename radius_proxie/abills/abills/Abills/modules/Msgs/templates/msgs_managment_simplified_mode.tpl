<script>
  jQuery(function () {
    //cache DOM
    var sheduleBtn = jQuery('#sheduleTableBtn');
    var dateField  = jQuery('#PLAN_DATE');

    //bindEvents
    sheduleBtn.on('click', function (event) {
      event.preventDefault();
      var date = dateField.val();

      var href = sheduleBtn.attr('link') + date;

      console.log(href);
      location.replace(href, false);
    });

  });
</script>

<div class="col-md-6">
<div class='box box-theme form form-horizontal col-md-6'>

   <div class='box-header with-border'><h4 class='box-title'>_{MANAGE}_</h4></div>
  
   <div class="box-body">
    <div class='form-group'>
      <div class='col-md-12'>
      %MAP%
      </div>
    </div>

    <div class='form-group'>
      <div class='col-md-12'>
        %WATCH_BTN% %EXPORT_BTN% %HISTORY_BTN%
        <a href='$SELF_URL?index=$index&deligate=$FORM{chg}&level=%DELIGATED_DOWN%'
           class='btn btn-default glyphicon glyphicon-hand-down' TITLE='_{COMPETENCE}_ _{DOWN}_ (%DELIGATED_DOWN%)'></a>
        <a href='$SELF_URL?index=$index&deligate=$FORM{chg}&level=%DELIGATED%'
           class='btn btn-default glyphicon glyphicon-hand-up' TITLE='_{COMPETENCE}_ _{UP}_ (%DELIGATED%)'></a>
        %INNER_MSG_TEXT%
        %WORK_BTN%
        %MSG_PRINT_BTN%
        %ADD_TAGS_BTN%
        %WORKPLANNING_BTN%
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
    <br>

  </div>
</div>
</div>

<div class="col-md-6">
<div class='box box-theme form form-horizontal'>

   <div class='box-header with-border'><h4 class='box-title'><span class='glyphicon glyphicon-time'></span> _{EXTRA}_</h4></div>
  
   <div class="box-body">

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
</div>
  <div class='box-footer text-center col-md-12'>
    <input type=submit name=change value='_{CHANGE}_' class='btn btn-primary'>
  </div>



