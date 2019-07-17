<input type='hidden' name='UID' value='$FORM{UID}'/>

<div class='form-group'>
  <label class='control-label col-xs-4 col-md-2'>_{DEPOSIT}_</label>
  <div class='col-xs-8 col-md-4'>
    <h4>
      <span class='label %DEPOSIT_MARK% pull-left' title='%DEPOSIT%'>%SHOW_DEPOSIT%</span>
    </h4>

  </div>
  <span class="visible-xs visible-sm col-xs-12" style="padding-top: 10px"></span>
  <label class='control-label  col-xs-4 col-md-2'>_{FINANCES}_</label>
  <div class='col-xs-8 col-md-4' align='left'>
    %PAYMENTS_BUTTON% %FEES_BUTTON% %PRINT_BUTTON%
  </div>
</div>


<!-- COMPANY -->
<div class='form-group'>
  <label class='control-label col-xs-4 col-md-2'>_{EXTRA_ABBR}_. _{DEPOSIT}_</label>
  <div class='col-xs-8 col-md-4'>
    <h4>
      <span class='label %EXT_DEPOSIT_MARK% pull-left'>%EXT_BILL_DEPOSIT%</span>
    </h4>

  </div>
  <span class="visible-xs visible-sm col-xs-12" style="padding-top: 10px"> </span>
  <label class='control-label  col-xs-4 col-md-2'>_{GROUPS}_</label>
  <div class='col-xs-8 col-md-4'>
    <div class='input-group col-xs-12'>
      <input type=text name='GRP' value='%GID%:%G_NAME%' ID='GRP' class='form-control' readonly>
      <span class='input-group-addon'><a href='$SELF_URL?index=12&UID=$FORM{UID}'
                                         class='glyphicon glyphicon glyphicon-pencil'></a></span>
    </div>
  </div>
  <span class="visible-xs visible-sm col-xs-12" style="padding-top: 10px"> </span>

</div>
