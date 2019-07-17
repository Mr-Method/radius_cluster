<input type='hidden' name='UID' value='$FORM{UID}'/>
<div class='form-group'>
  <!--DEPOSIT-->
  <label class='control-label col-md-2'>_{DEPOSIT}_</label>
  <div class='col-md-3'>
    <h4>
      <span class='label %DEPOSIT_MARK% pull-left' title='%DEPOSIT%'>%SHOW_DEPOSIT%</span>
    </h4>
  </div>
  <!--DEPOSIT-->

  <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>

  <!--FINANCES-->
  <label class='control-label col-md-2'>_{FINANCES}_</label>
  <div class='col-md-5' align='left'>
    <div class='btn-group'>
      %PAYMENTS_BUTTON% %FEES_BUTTON% %PRINT_BUTTON%
    </div>
  </div>
  <!--FINANCES-->

</div>

<!-- COMPANY -->
<div class='form-group'>

  <!--EX_DEPOSIT-->
  <label class='control-label col-md-2'>_{EXTRA_ABBR}_. _{DEPOSIT}_</label>
  <div class='col-md-3'>
    <h4>
      <span class='label %EXT_DEPOSIT_MARK% pull-left'>%EXT_BILL_DEPOSIT%</span>
    </h4>
  </div>
  <!--EX_DEPOSIT-->

  <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>

  <!--GROUPS-->
  <label class='control-label col-md-2' for='GRP'>_{GROUPS}_</label>
  <div class='col-md-5'>
    <div class='input-group'>
      <input type=text name='GRP' value='%GID%:%G_NAME%' ID='GRP' %GRP_ERR% class='form-control' readonly='readonly'/>
      <span class='input-group-addon'>
        <a href='$SELF_URL?index=12&UID=$FORM{UID}'>
          <span class='glyphicon glyphicon-pencil'></span>
        </a>
      </span>
    </div>
  </div>
  <!--GROUPS-->

</div>