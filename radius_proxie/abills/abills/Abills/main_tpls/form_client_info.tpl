<style type="text/css">
  .rules {
    left: 0;
  }

  .social-auth-links > .btn-group {
    width: 100%;
    max-width: 150px;
    margin-bottom: 10px;
  }

  .social-auth-links > .btn-group > a.btn.btn-social {
    width: 80%;
  }

  .social-auth-links > .btn-group > a.btn.btn-social-unreg {
    width: 20%;
  }

  div#notifications-subscribe-block {
    margin-bottom: 10px;
  }
</style>

<div class='modal fade' id='changeCreditModal' data-open='%OPEN_CREDIT_MODAL%'>
  <div class='modal-dialog modal-sm'>
    <form action=$SELF_URL class='form form-horizontal text-center pswd-confirm' id='changeCreditForm'>
      <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
              aria-hidden='true'>&times;</span></button>
          <h4 class='modal-title text-center'>_{SET_CREDIT}_</h4>
        </div>
        <div class='modal-body' style='padding: 30px;'>
          <input type=hidden name='index' value='10'>
          <input type=hidden name='sid' value='$sid'>

          <div class='form-group'>
            <label class='col-md-7'>_{CREDIT_SUM}_: </label>
            <label class='col-md-3'> %CREDIT_SUM%</label>
          </div>
          <div class='form-group'>
            <label class='col-md-7'>_{CREDIT_PRICE}_:</label>
            <label class='col-md-3'>%CREDIT_CHG_PRICE%</label>
          </div>
          <div class='form-group'>
            <label class='col-md-7'>_{ACCEPT}_:</label>

            <div class='col-md-3'>
              <input type='checkbox' required='required' value='%CREDIT_SUM%' name='change_credit'>
            </div>
          </div>
        </div>
        <div class='modal-footer'>
          <input type=submit class='btn btn-primary' value='_{SET}_' name='set'>
        </div>
      </div>
    </form>
  </div>
</div>
<!-- /.modal -->

<div class='modal fade' id='confirmationClientInfo' tabindex='-1' role='dialog' data-open='%CONFIRMATION_CLIENT_PHONE_OPEN_INFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %FORM_CONFIRMATION_CLIENT_PHONE%
    </div>
  </div>
</div>

<div class='modal fade' id='confirmationClientInfo' tabindex='-1' role='dialog' data-open='%CONFIRMATION_EMAIL_OPEN_INFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %FORM_CONFIRMATION_CLIENT_EMAIL%
    </div>
  </div>
</div>

<div class='modal fade' id='changePersonalInfo' tabindex='-1' role='dialog' data-open='%PINFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %TEMPLATE_BODY%
    </div>
  </div>
</div>

<div class='modal fade' id='rulesModal' tabindex='-1' role='dialog' aria-labelledby='myModalLabel'>
  <div class='modal-dialog modal-lg' role='document'>
    <div class='modal-content'>
      %ACCEPT_RULES%
    </div>
  </div>
</div>

<div class="row">
  <div class="col-md-12">%NEWS%</div>

  <div class="col-md-12" data-visible="%SHOW_SUBSCRIBE_BLOCK%" id="notifications-subscribe-block">
    %SENDER_SUBSCRIBE_BLOCK%
  </div>

  <div class="%INFO_TABLE_CLASS%">
    <div class='box box-theme'>
      <div class='box-header with-border text-center'>
        <button type='button' class='btn btn-success pull-left'
                data-visible='%SHOW_ACCEPT_RULES%' data-toggle='modal' data-target='#rulesModal'>
          _{RULES}_
        </button>
        <span class='extra'>%FORM_CHG_INFO%</span>
        <h4>
          _{INFO}_
        </h4>
      </div>
      <div class='panel-body'>
        <div class='table table-hover table-striped'>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{LOGIN}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%LOGIN% <i>(UID: %UID%)</i>
              <div class='extra'>%CHANGE_PASSWORD%</div>
            </div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{DEPOSIT}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%DEPOSIT% %MONEY_UNIT_NAMES%
              <div class='extra'>%DOCS_ACCOUNT% %PAYSYS_PAYMENTS% %CARDS_PAYMENTS% </div>
            </div>
          </div>
          <div class='row'>
            %EXT_DATA%
          </div>

          <!--Each info field row is wrapped in div.row-->
          %INFO_FIELDS%

          <div class='row' style='display: none' data-visible='%SHOW_REDUCTION%'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{REDUCTION}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>
              <span class='strong'>%REDUCTION% %</span>
              <div class='extra'>_{DATE}_: %REDUCTION_DATE%</div>
            </div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{CREDIT}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>
              <span class='strong'>%CREDIT% %MONEY_UNIT_NAMES% ( %CREDIT_DATE% )</span>
              <div class='extra'>
                %CREDIT_CHG_BUTTON%
              </div>
            </div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{FIO}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%FIO%</div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{PHONE}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%PHONE%</div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{ADDRESS}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%</div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>E-mail</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%EMAIL%</div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{CONTRACT}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%CONTRACT_ID%%CONTRACT_SUFIX%%NO_CONTRACT_MSG%
              <div class='extra '>
                <a %NO_DISPLAY% class='btn' target='new'
                  href='$SELF_URL?qindex=10&PRINT_CONTRACT=%CONTRACT_ID%&sid=$sid&pdf=$conf{DOCS_PDF_PRINT}'
                  title='_{PRINT}_'><span class='glyphicon glyphicon glyphicon-print'></span></a>
                <a class='btn' href='$SELF_URL?index=10&CONTRACT_LIST=1%&sid=$sid'
                  title='_{LIST}_'><span class='glyphicon glyphicon glyphicon-list'></span></a>
              </div>
            </div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{CONTRACT}_ _{DATE}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%CONTRACT_DATE%</div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{STATUS}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%STATUS%</div>
          </div>
          <!--            <div class='row'>
                          <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{ACTIVATE}_</div>
                          <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%ACTIVATE%</div>
                      </div>
                      <div class='row'>
                          <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{EXPIRE}_</div>
                          <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%EXPIRE%</div>
                      </div>
          -->
          <div class='row'>
            <div class='bg-success text-center'><strong>_{PAYMENTS}_</strong></div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{DATE}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%PAYMENT_DATE%</div>
          </div>
          <div class='row'>
            <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{SUM}_</div>
            <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%PAYMENT_SUM%</div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='col-md-2 no-padding' data-visible='%HAS_SOCIAL_BUTTONS%' style='display : none'>
    <div class="social-auth-links text-center">
      %SOCIAL_AUTH_BUTTONS_BLOCK%
    </div>
  </div>

</div>