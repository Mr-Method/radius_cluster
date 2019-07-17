<input type='hidden' name='MAIN_INNER_MESSAGE' value='%MAIN_INNER_MSG%'/>
<input type='hidden' name='SUBJECT' value='%SUBJECT%' size=50/>
<a name='reply' class='anchor'></a>

<div class='box box-theme'>
  <div class='box-header with-border'>
    <h5 class='box-title'>_{REPLY}_</h5>
  </div>
  <div class='box-body form form-horizontal'>

    <div class='form-group'>
      <textarea name='REPLY_TEXT' class='form-control' rows=10 style='width:90%; margin-left:auto;margin-right:auto'>%QUOTING%%REPLY_TEXT%</textarea>
    </div>
    <div class='form-group'>
      <label class='col-md-12'>%ATTACHMENT%</label>
    </div>

    <div class='form-group'>

      <div class='col-md-6'>
        <label class='col-md-3 control-label'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATE_SEL%
        </div>
      </div>

      <div class='col-md-6'>
        <div class='checkbox'>
          <label>
            <input type='checkbox' name=REPLY_INNER_MSG value=1 %INNER_MSG% style=/>
            <strong>_{INNER}_</strong>
          </label>
        </div>
      </div>

    </div>


    <div class='box box-theme collapsed-box'>
      <div class='box-header with-border'><h3 class='box-title'>_{EXTRA}_</h3>
        <div class='box-tools pull-right'>
          <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='box-body'>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{ATTACHMENT}_:</label>
          <div class='input-group'>
            <input name='FILE_UPLOAD' type='file' class='form-control'/>
            <span class='input-group-addon'><a
                href='$SELF_URL?UID=$FORM{UID}&index=$index&PHOTO=$FORM{chg}&webcam=1'
                class='glyphicon glyphicon-camera'></a></span>
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3'>_{TEMPLATES}_ (_{SURVEY}_):</label>

          <div class='col-md-9'>
            %SURVEY_SEL%
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label'>_{CHANGE}_ _{CHAPTERS}_:</label>

          <div class='col-md-9'>
            %CHAPTERS_SEL%
          </div>
        </div>
        <div class='form-group'>
          <label class='col-md-3 control-label text-left'>_{RUN_TIME}_:</label>

          <div class='col-md-9'>
            <input class='form-control' type='text' name='RUN_TIME' value='%RUN_TIME%' %RUN_TIME_STATUS%>
          </div>
        </div>
      </div>
    </div>
  </div>


  <div class='box-footer'>
    <input type='hidden' name='sid' value='$sid'/>
    <input type='submit' class='btn btn-primary' name='%ACTION%' value='  %LNG_ACTION%  ' id='go' title='Ctrl+C'/>
  </div>
</div>
<script>
  jQuery(function () {
    var status_select = jQuery('select#STATE');
    var wrapper       = jQuery('div.content-wrapper');

    if (status_select.chosen) {
      status_select.on('chosen:showing_dropdown', function () {
        setTimeout(function () {
          wrapper.scrollTop(wrapper.height());
        }, 100);
      });
    }
  });
</script>