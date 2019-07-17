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

<form class='form-horizontal' action='$SELF_URL' id='user_form' name='user_form' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='$index'>
  %MAIN_USER_TPL%
  <input type=hidden name=UID value='%UID%'>

  
  
  <!-- General panel -->
  <div id='form_1' class='box box-theme box-big-form for_sort'>
    <div class='box-header with-border'><h3 class='box-title'>_{USER_ACCOUNT}_ %DISABLE_MARK%</h3>
      <div class='box-tools pull-right'>
      <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
      <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>
    <div class='row' style='padding-bottom: 10px;'>
      <label class='control-label col-md-3 col-xs-3'>_{DEPOSIT}_</label>
      
      <div class='col-md-9 col-xs-9'>
        <div class='input-group'>
            <input class='form-control %DEPOSIT_MARK%' type='text' readonly value='%SHOW_DEPOSIT%' placeholder='0'>
        <span class='input-group-addon'>%PAYMENTS_BUTTON%</span>
        <span class='input-group-addon'>%FEES_BUTTON%</span>
        <span class='input-group-addon'>%PRINT_BUTTON%</span>
        </div>
      </div>
    </div>
    <div class='row' style='padding-bottom: 10px;'>
      <label class='control-label col-md-3 col-xs-3'>_{CREDIT}_</label>
      <div class='col-md-3 col-xs-3'>
        <input id='CREDIT' name='CREDIT' class='form-control' type='number' step='0.01' min='0' %CREDIT_READONLY% value='%CREDIT%'>
      </div>
      <label class='control-label col-md-3 col-xs-3'>_{DATE}_</label>
      <div class='col-md-3 col-xs-3'>
        <input id='CREDIT_DATE' name='CREDIT_DATE' class='datepicker form-control' type='text' %CREDIT_DATE_READONLY% value='%CREDIT_DATE%'>
      </div>
    </div>
    <div class='row' style='padding-bottom: 10px;'>
        <label class='control-label col-xs-3 col-md-3'>_{REDUCTION}_(%)</label>
        <div class=' col-xs-3 col-md-3'>
          <input id='REDUCTION' name='REDUCTION' class='form-control' type='number' 
                min='0' max='100' %REDUCTION_READONLY% value='%REDUCTION%' step='0.01'>
        </div>
        <label class='control-label col-md-3 col-xs-3'>_{DATE}_</label>
        <div class='col-md-3 col-xs-3'>
            <input id='REDUCTION_DATE' name='REDUCTION_DATE' class='datepicker form-control' type='text' %REDUCTION_DATE_READONLY% value='%REDUCTION_DATE%'>
        </div>
      </div>
        <!-- ACTIVATION / EXPIRED -->
        <div class='row' style='margin-bottom: 15px;'>
          <label class='control-label col-xs-3 col-md-3' for='ACTIVATE'>_{ACTIVATE}_</label>
          <div class='col-xs-9 col-md-3' style='margin-bottom: -1px;'>
            <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
                   class='form-control datepicker' %ACTIVATE_READONLY% type='text'>
          </div>
          <label class='control-label col-xs-3 col-md-3' for='EXPIRE'>_{EXPIRE}_</label>
          <div class='col-xs-9 col-md-3 %EXPIRE_COLOR%'>
            <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                   class='form-control datepicker' %EXPIRE_READONLY% type='text'>
          </div>
        </div>
  </div>

    <div class='box box-default collapsed-box' style='margin-bottom: 0px; border-top-width: 1px;'>
        <div class='box-header with-border'>
          <h3 class='box-title'>_{EXTRA}_</h3>
          <div class='box-tools pull-right'>
            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='box-body'>
          <div class='form-group'>
            <label class='control-label col-xs-4 col-md-4'>_{COMPANY}_</label>
            <div class=' col-xs-8 col-md-8'>
              <div class='input-group'>
                <input type=text name='COMP' value='%COMPANY_NAME%' ID='COMP' class='form-control'
                       readonly>
                <span class='input-group-addon'><a href='$SELF_URL?index=13&amp;COMPANY_ID=%COMPANY_ID%'
                                                   class='glyphicon glyphicon-circle-arrow-left'></a></span>
                <span class='input-group-addon'><a href='$SELF_URL?index=21&UID=$FORM{UID}'
                                                   class='glyphicon glyphicon-pencil'></a></span>
              </div>
            </div>
      
      <label class='control-label col-xs-4 col-md-4'>_{GROUP}_</label>
      <div class='col-md-8 col-xs-8'>
          <div class='input-group'>
                <input type=text name='GRP' value='%GID%:%G_NAME%' ID='GRP' %GRP_ERR% class='form-control' readonly>
                <span class='input-group-addon'><a href='$SELF_URL?index=12&UID=$FORM{UID}'
                                         class='glyphicon glyphicon glyphicon-pencil'></a></span>
              </div>
        </div>
      
  
      
            <label class='control-label col-xs-4 col-md-4' for='REG'>_{REGISTRATION}_</label>
            <div class='col-xs-8 col-md-8'>
              <input type=text name='REG' value='%REGISTRATION%' ID='REG' class='form-control' readonly>
            </div>
            <label class='control-label col-xs-4 col-md-4' for='BILL'>_{BILL}_</label>
            <div class='col-xs-8 col-md-8'>
              <div class='input-group'>
                <input type=text name='BILL' value='%BILL_ID%' ID='BILL' class='form-control' readonly>
                <span class='input-group-addon'>%BILL_CORRECTION%</span>
              </div>
            </div>
      </div>
      <div class='form-group'>
          <label class='control-label col-xs-4 col-md-4'>_{PASSWD}_</label>
      <div class='col-md-4 col-xs-4'>%PASSWORD%</div>
      </div>    
      
      <div class='col-md-4 col-xs-4' %DISABLE_HIDEN%>
          <label class='btn btn-default'>
            <input id='DISABLE' name='DISABLE' value='1' %DISABLE_CHECKBOX% type='checkbox' onClick='add_comments();'>
          _{DISABLE}_
        </label>
      </div>
        
              
      <div class='col-md-8 col-xs-8 %DISABLE_COLOR%' %DISABLE_HIDEN%>
        %DISABLE_COMMENTS%
        <input class='form-control' type=text name=ACTION_COMMENTS value='%DISABLE_COMMENTS%' size=30
               style='visibility: hidden;'>%ACTION_COMMENTS%
      </div>
      %DEL_FORM%
    
    
    

    </div>
    </div>


    <div class='box-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>
