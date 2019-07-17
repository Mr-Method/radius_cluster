<form action=$SELF_URL class='form-horizontal' method='post'>
<input type=hidden name=index value=$index>

<div class='box box-theme box-form'>
<div class='box-header with-border'><h4 class='box-title'>_{SHEDULE}_</h4></div>
<div class='box-body'>


   <div class='form-group'>
    <label for='SEL_D' class='control-label col-sm-3'>_{DAY}_:</label>
    <div class='col-md-9'>
     %SEL_D%
     </div>
  </div>

   <div class='form-group'>
    <label for='SEL_M' class='control-label col-sm-3'>_{MONTH}_:</label>
    <div class='col-md-9'>
      %SEL_M%
     </div>
  </div>

   <div class='form-group'>
    <label for='SEL_Y' class='control-label col-sm-3'>_{YEAR}_:</label>
    <div class='col-md-9'>
     %SEL_Y%
     </div>
  </div>

  <div class='form-group'>
    <label for='COUNTS' class='control-label col-sm-3'>_{COUNT}_:</label>
    <div class='col-md-9'>
      <input class='form-control' id='COUNTS' placeholder='%COUNTS%' name='COUNTS' value='%COUNTS%'>
     </div>
  </div>

   <div class='form-group'>
    <label for='SEL_TYPE' class='control-label col-sm-3'>_{TYPE}_:</label>
    <div class='col-md-9'>
     %SEL_TYPE%
     </div>
  </div>

  <div class='form-group'>

          <label class='col-md-12'>_{ACTION}_</label>
            <div class='col-md-12'>
            <textarea cols='30' rows='4' name='ACTION' class='form-control'>%ACTION%</textarea>
                </div>
              </div>

   <div class='form-group'>
    <label class='col-md-12'>_{COMMENTS}_</label>
            <div class='col-md-12'>
            <textarea cols='30' rows='4' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
                </div>
              </div>




  </div>
  <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name=add value='_{ADD}_'>
    </div>


  </fieldset>
</div>
<!--
<table width=400 class=form>
<tr><th class=form_title colspan=2>_{SHEDULE}_</th></tr>
<tr><td>_{DAY}_:</td><td>%SEL_D%</td></tr>
<tr><td>_{MONTH}_:</td><td>%SEL_M%</td></tr>
<tr><td>_{YEAR}_:</td><td>%SEL_Y%</td></tr>
<tr><td>_{COUNT}_:</td><td><input type=text name=COUNT value='%COUNT%'></td></tr>
<tr><td>_{TYPE}_:</td><td>%SEL_TYPE%</td></tr>
<tr><th colspan=2>_{ACTION}_:</td></tr>
<tr><th colspan=2><__textarea__ cols=60 rows=10 name=ACTION >%ACTION%</__textarea__></td></tr>
<tr><th colspan=2>_{COMMENTS}_:</td></tr>
<tr><th colspan=2><__textarea__ cols=60 rows=3 name=COMMENTS>%COMMENTS%</__textarea__></td></tr>
<tr><th class=even colspan=2><input type=submit name=add value=_{ADD}_></th></tr>
</table>
-->
</form>