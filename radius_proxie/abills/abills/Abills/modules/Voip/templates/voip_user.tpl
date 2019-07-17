<form action=$SELF_URL method=post id='VOIP_USER_FORM' class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=UID value='$FORM{UID}'>
  <div class='box box-theme box-big-form'>

    <div class='box-header with-border'>
      <h4 class='box-title'>VOIP</h4>
    </div>

    <div class='box-body'>

      <div class='row no-padding'>
        <div class="col-md-12 text-center">
          %MENU%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NUMBER'>_{NUMBER}_:</label>
        <div class='col-md-9'>
          <input id='NUMBER' name='NUMBER' value='%NUMBER%' placeholder='%NUMBER%' class='form-control'
                 type='text'>
        </div>
      </div>


      <div class='form-group'>
        <label class='control-label col-md-3' for='TP'>_{TARIF_PLAN}_</label>
        <div class='col-md-9'>
          %TP_ADD%
          <label class='label label-primary'>%TP_NUM%</label>
          <label class='label label-default'>%TP_NAME%</label>
          %CHANGE_TP_BUTTON%
          <a href='$SELF?index=$index&UID=$FORM{UID}&pay_to=1' class='$conf{CURRENCY_ICON}' title='_{PAY_TO}_'></a>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='SIMULTANEOUSLY'>_{SIMULTANEOUSLY}_:</label>
        <div class='col-md-9'>
          <input id='SIMULTANEOUSLY' name='SIMULTANEOUSLY' value='%SIMULTANEOUSLY%'
                 placeholder='%SIMULTANEOUSLY%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='IP'>IP:</label>
        <div class='col-md-9'>
          <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CID'>CID:</label>
        <div class='col-md-9'>
          <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='ALLOW_ANSWER'>_{ALLOW_ANSWER}_:</label>
        <div class='col-md-3'>
          <input id='ALLOW_ANSWER' name='ALLOW_ANSWER' value='1' %ALLOW_ANSWER% type='checkbox'>
        </div>

        <label class='control-label col-md-3' for='ALLOW_CALLS'>_{ALLOW_CALLS}_:</label>
        <div class='col-md-3'>
          <input id='ALLOW_CALLS' name='ALLOW_CALLS' value='1' %ALLOW_CALLS% type='checkbox'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_:</label>
        <div class='col-md-9' style='background: %STATUS_COLOR%;'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='FILTER_ID'>FILTER ID:</label>
        <div class='col-md-9'>
          <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group'>
        %PROVISION%
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='VOIP_EXPIRE'>_{EXPIRE}_:</label>
        <div class='col-md-9'>
          <input id='VOIP_EXPIRE' name='VOIP_EXPIRE' value='%VOIP_EXPIRE%' placeholder='%VOIP_EXPIRE%'
                 class='tcal form-control' type='text'>
        </div>
      </div>


    </div>
    <div class='box-footer'>
      <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
      %DEL_BUTTON%
    </div>
  </div>

</form>
