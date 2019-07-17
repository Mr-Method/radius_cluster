<!--Abon_apon_tp.tpl-->

<form action='$SELF_URL' method='post' class='form-horizontal'>
  <input class='form-control' type='hidden' name='index' value='$index' />
  <input class='form-control' type='hidden' name='ABON_ID' value='$FORM{ABON_ID}' />

  <div class='box box-form box-theme'>
   <div class='box-header with-border'>
        <legend>%ACTION_LNG% _{ABON}_</legend>
   </div>

	<div class='box-body'>
	  <div class='form-group'>
		<div class='col-md-3'>
			<label for='%NAME%'>_{NAME}_:</label>
		</div>
		<div class='col-md-9'>
			<input class='form-control' type='text' name='NAME' value='%NAME%' maxlength='45'  />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-3'>
			<label for='PRICE'>_{SUM}_:</label>
		</div>
		<div class='col-md-9'>
			<input class='form-control' type='text' name='PRICE' value='%PRICE%' maxlength='10' />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-3'>
			<label for='PERIOD_SEL'>_{PERIOD}_:</label>
		</div>
		<div class='col-md-9'>
			%PERIOD_SEL%
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-3'>
			<label for='PAYMENT_TYPE_SEL'>_{PAYMENT_TYPE}_:</label>
		</div>
		<div class='col-md-9'>
			%PAYMENT_TYPE_SEL%
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='NONFIX_PERIOD'>_{NONFIX_PERIOD}_:</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='NONFIX_PERIOD' data-return='1' value='1' %NONFIX_PERIOD% />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='MANUAL_ACTIVATE'>_{MANUAL_ACTIVATE}_:</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='MANUAL_ACTIVATE' data-return='1' %MANUAL_ACTIVATE% value='1' />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='USER_PORTAL'>_{USER_PORTAL}_:</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='USER_PORTAL' data-return='1' %USER_PORTAL% value='1' />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='PERIOD_ALIGNMENT' data-return='1' %PERIOD_ALIGNMENT% value='1' />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='DISCOUNT'>_{REDUCTION}_:</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='DISCOUNT' data-return='1' %DISCOUNT% value='1' />
		</div>
      </div>

		<div class='form-group'>
			<div class='col-md-7'>

		%EXT_BILL_ACCOUNT%
			</div>
		</div>

      <div class='form-group'>
	  	<div class='col-md-3'>
			<label for='PRIORITY'>_{PRIORITY}_:</label>
		</div>
		<div class='col-md-9'>
			%PRIORITY%
		</div>
      </div>

        <!-- <div class='form-group'><td>_{ACCOUNT}_ _{FEES}_:</td><td>%ACCOUNT_SEL%</td></div> -->

      <div class='form-group'>
	  	<div class='col-md-3'>
			<label for='FEES_TYPES_SEL'>_{FEES}_ _{TYPE}_:</label>
		</div>
		<div class='col-md-9'>
			%FEES_TYPES_SEL%
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='CREATE_ACCOUNT'>_{CREATE}_, _{SEND_ACCOUNT}_:</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='CREATE_ACCOUNT' %CREATE_ACCOUNT% value='1' />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='VAT'>_{VAT_INCLUDE}_:</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='VAT' %VAT% value='1' />
		</div>
      </div>

      <div class='form-group'>
	  	<div class='col-md-7'>
			<label for='ACTIVATE_NOTIFICATION'>_{SERVICE_ACTIVATE_NOTIFICATION}_</label>
		</div>
		<div class='col-md-5'>
			<input type='checkbox' name='ACTIVATE_NOTIFICATION' %ACTIVATE_NOTIFICATION% value='1' />
		</div>
      </div>

	<div class='form-group'>
		<button class='btn btn-secondary' type='button' data-toggle='collapse' data-target='#notification' aria-expanded='true' aria-controls='collapseExample'>
			_{NOTIFICATION}_ (E-mail)
		</button>
	</div>
		<div class='collapse' id='notification'>
		  <div class='well'>
			<div class='form-group'>
				<div class='col-md-4'>
					<label for='NOTIFICATION1'>1: _{DAYS_TO_END}_:</label>
				</div>
				<div class='col-md-2'>
					<input class='form-control' type='text' name='NOTIFICATION1' value='%NOTIFICATION1%' maxlength='2'/>
				</div>

				<div class='col-md-4'>
					<label for='NOTIFICATION_ACCOUNT'>_{CREATE}_, _{SEND_ACCOUNT}_: </label>
				</div>
				<div class='col-md-2'>
					<input type='checkbox' name='NOTIFICATION_ACCOUNT' %NOTIFICATION_ACCOUNT% value='1' />
				</div>
			</div>

			<div class='form-group'>
				<div class='col-md-4'>
					<label for='NOTIFICATION2'>2: _{DAYS_TO_END}_:</label>
				</div>
				<div class='col-md-2'>
					<input class='form-control' type='text' name='NOTIFICATION2' value='%NOTIFICATION2%' maxlength='2'/>
				</div>
				<div class='clearfix-visible-xs-6'></div>
			</div>

			<div class='form-group'>
				<div class='col-md-4'>
					<label for='ALERT'>3: _{ENDED}_:</label>
				</div>
				<div class='col-md-2'>
					<input type='checkbox' name='ALERT' %ALERT% value='1'/>
				</div>

				<div class='col-md-4'>
					<label for='ALERT_ACCOUNT'>_{SEND_ACCOUNT}_:</label>
				</div>
				<div class='col-md-2'>
					<input type='checkbox' name='ALERT_ACCOUNT' %ALERT_ACCOUNT% value='1'/>
				</div>
			</div>
		  </div>
		</div>




<div class='form-group'>
	<div class='col-md-3'>
	  <label for='EXT_CMD'>_{EXT_CMD}_:</label>
	</div>
	<div class='col-md-9'>
	<input class='form-control'  type='text' name='EXT_CMD' value='%EXT_CMD%' maxlength='60' />
</div>
</div>

<div class='form-group'>
	<div class='col-md-3'>
	  <label for='SERVICE_LINK'>URL:(caption|url)</label>
	</div>
	<div class='col-md-9'>
	<input class='form-control'  type='text' name='SERVICE_LINK' value='%SERVICE_LINK%' maxlength='60' />
</div>
</div>

<div class='form-group'>
	<div class='col-md-3'>
	  <label for='SERVICE_LINK'>_{DESCRIPTION}_</label>
	</div>
	<div class='col-md-9'>
	<textarea rows="2" name='DESCRIPTION' class='form-control' value='%DESCRIPTION%'></textarea>
</div>
</div>

  </div>
	<div class='box-footer'>
        <th colspan='3' class='even'>
          <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%' />
        </th>
      </div>
	</div>
</form>

