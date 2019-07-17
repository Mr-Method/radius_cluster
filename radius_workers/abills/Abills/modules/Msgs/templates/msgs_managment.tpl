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

<div class='box box-theme'>
  <div class='box-header with-border'>
    <h6 class='box-title'>_{MANAGE}_</h6>
  </div>

  <div class='box-body'>

    <div>
      %MAP%
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
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{ADDRESS}_:</label>

      <div class='col-md-12'>
        %ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{RESPOSIBLE}_:</label>

      <div class='col-md-12'>
        %RESPOSIBLE_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{EXECUTION}_:</label>
      <label class='col-md-12'>_{DATE}_:</label>

      <div class='col-md-12'>
        %PLAN_DATE%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12' for='PLAN_TIME'>_{TIME}_:</label>

      <div class='col-md-12'>
        <div class='input-group'>
          <input type='text' value='%PLAN_TIME%' name='PLAN_TIME' id='PLAN_TIME' class='form-control'>

          <div class='input-group-btn'>
            <button link='%SHEDULE_TABLE_OPEN%' id='sheduleTableBtn' class='btn btn-default'>
              <span class='glyphicon glyphicon-calendar'></span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{ADMIN}_:</label>

      <div class='col-md-12'>
        %A_NAME%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{PHONE}_:</label>

      <div class='col-md-12'>
        %PHONE%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{PRIORITY}_:</label>

      <div class='col-md-12'>
        %PRIORITY_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{DISPATCH}_:</label>

      <div class='col-md-12'>
        %DISPATCH_SEL%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{CLOSED}_:</label>

      <div class='col-md-12'>
        %CLOSED_DATE%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{DONE}_:</label>

      <div class='col-md-12'>
        %DONE_DATE%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{USER}_:</label>

      <div class='col-md-12'>
        %USER_READ%
      </div>
    </div>

    <div class='form-group'>
      <label class='col-md-12'>_{ADMIN}_:</label>

      <div class='col-md-12'>
        %ADMIN_READ%
      </div>
    </div>

    <div class='form-group'>

    </div>


  </div>
  <div class='box-footer text-center'>
    <input type=submit name=change value='_{CHANGE}_' class='btn btn-primary btn-sm'>
  </div>
</div>



