<FORM action=$SELF_URL METHOD=POST name='extfin'>
<input type=hidden name=index value=$index>

<div class='box box-form box-primary form-horizontal'>
<div class='box-header with-border'>_{EXPORT}_ : _{USERS}_</div>
<div class='box-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{GROUP}_:</label>
    <div class='col-md-9'>
      %GROUP_SEL%
    </div>
  </div>
  <label class='col-md-12'>_{DATE}_:</label>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{FROM}_:</label>
    <div class='col-md-9'>
      %FROM_DATE%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{TO}_:</label>
    <div class='col-md-9'>
      %TO_DATE%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{REPORT}_ _{TYPE}_::</label>
    <div class='col-md-9'>
      %TYPE_SEL%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{USER}_ _{TYPE}_:</label>
    <div class='col-md-9'>
      %USER_TYPE_SEL%
    </div>
  </div>
  <div class='checkbox'>
    <label>
      <input type='checkbox' name=TOTAL_ONLY value=1><strong>_{TOTAL}_</strong>
    </label>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{INFO_FIELDS}_(_{USERS}_)</label>
    <div class='col-md-9'>
      %INFO_FIELDS%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{INFO_FIELDS}_(_{COMPANIES}_)</label>
    <div class='col-md-9'>
      %INFO_FIELDS_COMPANIES%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ROWS}_</label>
    <div class='col-md-9'>
      <input type=text class='form-control' name=PAGE_ROWS value='$PAGE_ROWS'>
    </div>
  </div>
</div>
<div class='box-footer'>
<input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
</div>
</div>


<!-- <table class=form>
<tr><th colspan=2 class=form_title>_{EXPORT}_ : _{USERS}_</th></tr>
<tr><td>_{GROUP}_:</td><td>%GROUP_SEL%</td></tr>
<tr><td>_{DATE}_:</td><td><TABLE width=100%>
<tr><td>_{FROM}_:</td><td>%FROM_DATE%</td></tr>
<tr><td>_{TO}_:</td><td>%TO_DATE%</td></tr>
</table>

</td></tr>
<tr><td>_{REPORT}_ _{TYPE}_:</td><td>%TYPE_SEL%</td></tr>

<tr class=even><td>_{USER}_ _{TYPE}_:</td><td>%USER_TYPE_SEL%</td></tr>
<tr class=even><td>_{TOTAL}_:</td><td><input type=checkbox name=TOTAL_ONLY value=1></td></tr>

<tr><td>_{INFO_FIELDS}_ <br>(_{USERS}_):</td><td>%INFO_FIELDS%</td></tr>
<tr class=even><td>_{INFO_FIELDS}_ <br>(_{COMPANIES}_):</td><td>%INFO_FIELDS_COMPANIES%</td></tr>

<tr><td>_{ROWS}_:</td><td><input type=text name=PAGE_ROWS value='$PAGE_ROWS'></td></tr>
<tr><th colspan=2 class=even><input type=submit name=%ACTION% value=%ACTION_LNG%></th></tr>
</table> -->

</FORM>
