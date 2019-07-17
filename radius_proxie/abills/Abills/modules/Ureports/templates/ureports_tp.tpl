<div class='noprint' id='UREPORTS'>
<form action='$SELF_URL' METHOD='POST' ID='FORM_UREPORTS'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>

<div class='box box-theme box-form'>
	<legend>_{TARIF_PLAN}_ #%ID%</legend>
<div class='box-body form form-horizontal'>
 
  <div class='form-group'>
  	<label class='control-label col-md-3'>_{NAME}_:</label>
  	<div class='col-md-9'><input type=text name=NAME value='%NAME%' class='form-control'></div>
  </div>

   <div class='form-group'>
   	<label class='col-md-3'>_{MSG_PRICE}_:</label>
   	<div class='col-md-9'><input type=text name=MSG_PRICE value='%MSG_PRICE%' class='form-control'></div>
   </div>
   
  <div class='form-group'>
  	<label class='col-md-12 bg-primary'>_{ABON}_</label>
  </div> 
  <!-- 
  <tr><td>_{DAY_FEE}_:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>_{POSTPAID}_:</td><td><input type=checkbox name=POSTPAID_DAY_FEE value=1 %POSTPAID_DAY_FEE%></td></tr>
  -->
  <div class='form-group'>
  	<label class='col-md-3'>_{MONTH_FEE}_:</label>
  	<div class='col-md-9'><input type=text name=MONTH_FEE value='%MONTH_FEE%' class='form-control'></div>
  </div>
  
  <div class='form-group'>
  	<div class='col-md-3'>
  	</div>
  	<label class='col-md-3'>_{POSTPAID}_:</label>
  	<div class='col-md-1'>
  		<input type=checkbox name=POSTPAID_MONTH_FEE value=1 %POSTPAID_MONTH_FEE%>
  	</div>
  	<label class='col-md-3'>_{REDUCTION}_:</label>
  	<div class='col-md-1'><input type=checkbox name=REDUCTION_FEE value=1 %REDUCTION_FEE%></div>
  </div>
  <!--
  <tr class=even><td>_{MONTH_ALIGNMENT}_:</td><td><input type=checkbox name='PERIOD_ALIGNMENT' value='1' %PERIOD_ALIGNMENT%></td></tr>
  <tr class=even><td>_{ABON_DISTRIBUTION}_:</td><td><input type=checkbox name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%></td></tr>
  -->

  
  
  %EXT_BILL_ACCOUNT%
  
  <div class='form-group'>
  	<label class='col-md-12 bg-primary'>_{OTHER}_</label>
  </div>
  <div class='form-group'>
  	<label class='col-md-3 control-label'>_{ACTIVATE}_:</label>
  	<div class='col-md-9'>
  		<input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%' class='form-control'>
  	</div>
  </div>
  
  <div class='form-group'>
  	<label class='col-md-3 control-label'>_{CHANGE}_:</label>
  	<div class='col-md-9'>
  		<input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%' class='form-control'>
  	</div>
  </div>
  
  <div class='form-group'>
  	<label class='col-md-3 control-label'>_{CREDIT}_:</label>
  	<div class='col-md-9'>
  		<input type=text name=CREDIT value='%CREDIT%' class='form-control'>
  	</div>
  </div>
  
  <div class='form-group'>
  	<label class='col-md-3'>_{AGE}_ (_{DAYS}_):</label>
  	<div class='col-md-9'>
  		<input type=text name=AGE value='%AGE%' class='form-control'>
  	</div>
 	</div>
  
  <div class='form-group'>
  	<label class='col-md-3 control-label'>_{MIN_USE}_:</label>
  	<div class='col-md-9'>
  		<input type=text name=MIN_USE value='%MIN_USE%' class='form-control'>
  	</div>
  </div>
  
</div>
<div class='box-footer'>
	<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>
</div>

</form>
</div>
