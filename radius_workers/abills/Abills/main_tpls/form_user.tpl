<SCRIPT TYPE='text/javascript'>
  <!--
  function add_comments() {

    if (document.user_form.DISABLE.checked) {
      document.user_form.DISABLE.checked = false;

      var comments = prompt('_{COMMENTS}_', '');

      if (comments == '' || comments == null) {
        alert('Enter comments');
        document.user_form.DISABLE.checked                  = false;
        document.user_form.ACTION_COMMENTS.style.visibility = 'hidden';
      }
      else {
        document.user_form.DISABLE.checked                  = true;
        document.user_form.ACTION_COMMENTS.value            = comments;
        document.user_form.ACTION_COMMENTS.style.visibility = 'visible';
      }
    }
    else {
      document.user_form.DISABLE.checked                  = false;
      document.user_form.ACTION_COMMENTS.style.visibility = 'hidden';
      document.user_form.ACTION_COMMENTS.value            = '';
    }
  }
  -->
</SCRIPT>
<form class='form-horizontal' action='$SELF_URL' method='post' id='user_form' name='user_form' role='form'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=COMPANY_ID value='%COMPANY_ID%'>
  <input type=hidden name=step value='$FORM{step}'>
  <input type=hidden name=NOTIFY_FN value='%NOTIFY_FN%'>
  <input type=hidden name=NOTIFY_ID value='%NOTIFY_ID%'>
  <input type=hidden name=TP_ID value='%TP_ID%'>

  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h3 class='box-title'>_{USER_ACCOUNT}_</h3>
      <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='box-body' style='padding: 0'>
      <div style='padding: 10px'>
        %EXDATA%

        <line class='visible-xs visible-sm dashed'></line>

        <!-- CREDIT / DATE  -->
        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2' for='CREDIT'>_{CREDIT}_</label>
          <div class='col-xs-8 col-md-4'>
            <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%' class='form-control'
                   type='text' %CREDIT_READONLY%>
          </div>
          <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
          <label class='control-label col-xs-4 col-md-2' for='CREDIT_DATE'>_{DATE}_</label>
          <div class='col-xs-8 col-md-4'>
            <input id='CREDIT_DATE' type='text' name='CREDIT_DATE' value='%CREDIT_DATE%'
                   class='datepicker form-control' %CREDIT_DATE_READONLY%>
          </div>
        </div>
        <line class='visible-xs visible-sm dashed'></line>

        <!-- DISCOUNT / DATE  -->
        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2' for='REDUCTION'>_{REDUCTION}_(%)</label>
          <div class='col-xs-8 col-md-4'>
            <input type='number 'id='REDUCTION' name='REDUCTION' value='%REDUCTION%' placeholder='%REDUCTION%'
                   min='0' max='100'
                   class='form-control' %REDUCTION_READONLY%>
          </div>
          <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
          <label class='control-label col-xs-4 col-md-2' for='REDUCTION_DATE'>_{DATE}_</label>
          <div class='col-xs-8 col-md-4'>
            <input id='REDUCTION_DATE' type='text' name='REDUCTION_DATE' value='%REDUCTION_DATE%'
                   class='datepicker form-control' %REDUCTION_DATE_READONLY%>
          </div>
        </div>

        <line class='visible-xs visible-sm dashed'></line>
        <!-- DISABLE -->
        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2' for='DISABLE'>_{DISABLE}_</label>
          <div class='col-xs-1 col-md-1'>
            <input id='DISABLE' name='DISABLE' value='1' %DISABLE% type='checkbox'
                   onClick='add_comments();'>
            %DISABLE_MARK%
          </div>
          <div class='col-xs-6 col-md-3 panel %DISABLE_COLOR%'>
            %DISABLE_COMMENTS%
            <input class='form-control' type=text name=ACTION_COMMENTS value='%DISABLE_COMMENTS%' size=30
                   style='visibility: hidden;'>%ACTION_COMMENTS%
          </div>
          <label class='control-label col-xs-4 col-md-2' for='PASSWD'>_{PASSWD}_</label>
          <div class='col-xs-8 col-md-4' align='left'>%PASSWORD%</div>
        </div>
        <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>

        %DEL_FORM%

        <div class='col-sm-offset-2 col-sm-8'>

        </div>
      </div>
      <div class='box box-default box-big-form collapsed-box'>
        <div class='box-header with-border'>
          <h3 class='box-title'>_{EXTRA}_</h3>
          <div class='box-tools pull-right'>
            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='box-body'>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2'>_{COMPANY}_</label>
            <div class=' col-xs-8 col-md-4'>
              <div class='input-group'>
                <input type=text name='COMP' value='%COMPANY_NAME%' ID='COMP' class='form-control'
                       readonly>
                <span class='input-group-addon'><a href='$SELF_URL?index=13&amp;COMPANY_ID=%COMPANY_ID%'
                                                   class='glyphicon glyphicon-circle-arrow-left'></a></span>
                <span class='input-group-addon'><a href='$SELF_URL?index=21&UID=$FORM{UID}'
                                                   class='glyphicon glyphicon-pencil'></a></span>
              </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
            <label class='control-label col-xs-4 col-md-2' for='REG'>_{REGISTRATION}_</label>
            <div class='col-xs-8 col-md-4'>
              <input type=text name='REG' value='%REGISTRATION%' ID='REG' class='form-control' readonly>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='BILL'>_{BILL}_</label>
            <div class='col-xs-8 col-md-4'>
              <div class='input-group'>
                <input type=text name='BILL' value='%BILL_ID%' ID='BILL' class='form-control' readonly>
                <span class='input-group-addon'>%BILL_CORRECTION%</span>
              </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
            <label class='control-label col-xs-4 col-md-2' for='BILL'>_{EXTRA_ABBR}_. _{BILL}_</label>
            <div class='col-xs-8 col-md-4'>
              <input type=text name='EXT_BILL_ID' value='%EXT_BILL_ID%' ID='EXT_BILL' class='form-control' readonly>
            </div>
          </div>
          <line class='visible-xs visible-sm dashed'></line>
          <!-- ACTIVATION / EXPIRED -->
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-2' for='ACTIVATE'>_{ACTIVATE}_</label>
            <div class='col-xs-8 col-md-4'>
              <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
                     class='form-control datepicker' type='text'>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <label class='control-label col-xs-4 col-md-2' for='EXPIRE'>_{EXPIRE}_</label>
            <div class='col-xs-8 col-md-4 %EXPIRE_COLOR%'>
              <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                     class='form-control datepicker' %EXPIRE_READONLY% type='text'>
              <!--    <span class='help-block'>%EXPIRE_COMMENTS%</span> -->
            </div>
          </div>
          <line class='visible-xs visible-sm dashed'></line>

        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>
