

<form action='$SELF_URL' METHOD='POST' class='form-horizontal '>

<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='MBOX_ID' value='%MBOX_ID%'>

<div class='box box-theme box-form box-big-form'>
	<div class='box-header with-border'>
		<h4 class='box-title'>E-Mail</h4>
		<div class='box-tools pull-right'>
			<button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-minus'></i>
			</button>
		</div>
	</div>


	<div class='box-body form form-horizontal'>

<fieldset>

%MENU%

    <div class='form-group'>
        <div class='col-md-6'>
            <div class='input-group'>
              <input type='text' id='USERNAME' name='USERNAME' value='%USERNAME%' class='form-control' placeholder='E-mail' />
              <span class='input-group-addon'>@</span>
            </div>
        </div>
        <div class='col-md-6'>
            %DOMAINS_SEL%
        </div>
    </div>

  	<div class='form-group'>
    	<label for='COMMENTS' class='control-label col-md-3'>_{DESCRIBE}_:</label>
    	<div class='col-md-9'>
      	<input class='form-control' id='COMMENTS' placeholder='%COMMENTS%' name='COMMENTS' value='%COMMENTS%'>
     	</div>
 		 </div>

  	<div class='form-group'>
    	<label for='' class='col-md-12 bg-primary'>_{LIMIT}_:</label>
    </div>

    <div class='form-group'>
    	<div class='col-md-3'>
    		<label for='MAILS_LIMIT' class='control-label col-md-3'>_{COUNT}_:</label>
    	</div>
    	<div class='col-md-3'>
      	<input class='form-control' id='MAILS_LIMIT' placeholder='%MAILS_LIMIT%' name='MAILS_LIMIT' value='%MAILS_LIMIT%'>
     	</div>
      <div class='col-md-3'>
      	<label for='BOX_SIZE' class='control-label col-sm-3'>_{SIZE}_(Mb):</label>
      </div>
      <div class='col-md-3'>
      	<input class='form-control' id='BOX_SIZE' placeholder='%BOX_SIZE%' name='BOX_SIZE' value='%BOX_SIZE%'>
     	</div>
  	</div>

  <div class='form-group'>
  	<div class='col-md-4'>
  	 	<label  for='ANTIVIRUS'>_{ANTIVIRUS}_:</label>
  	</div>
  	<div class='col-md-2'>
     	<input id='ANTIVIRUS' name='ANTIVIRUS' value='1' %ANTIVIRUS%  type='checkbox'>
    </div>
  	<div class='col-md-3'>
  		<label for='ANTISPAM'>_{ANTISPAM}_:</label>
  	</div>
  	<div class='col-md-3'>
    	<input id='ANTISPAM' name='ANTISPAM' value='1' %ANTISPAM%  type='checkbox'>
    </div>
  </div>
	<div class='form-group'>
    <div class='col-md-4'>
    	<label  for='SEND_MAIL'>_{SEND_MAIL}_:</label>
    </div>
  	<div class='col-md-2'>
  		<input id='SEND_MAIL' name='SEND_MAIL' value='1' %SEND_MAIL%  type='checkbox'>
  	</div>
  	<div class='col-md-3'>
  		<label for='DISABLE'>_{DISABLE}_:</label>
  	</div>
  	<div class='col-md-3'>
  		<input id='DISABLE' name='DISABLE' value='1' %DISABLE%  type='checkbox'>
  	</div>
  </div>
	<div class='form-group'>
    <div class='col-md-3'>
    	<label for='EXPIRE' class='control-label'>_{EXPIRE}_</label>
    </div>
    <div class='col-md-9'>
    	<input class='form-control datepicker' id='EXPIRE' placeholder='%EXPIRE%' name='EXPIRE' value='%EXPIRE%'>
    </div>
  </div>


  <div class='form-group'>
  	<div class='col-md-3'>
  	  <label for='CREATE_DATE' class='control-label'>_{REGISTRATION}_:</label>
  	</div>
  	<div class='col-md-3'>
       %CREATE_DATE%
    </div>

  	<div class='col-md-3'>
  		<label for='CHANGE_DATE'>_{CHANGED}_:</label>
    </div>
  	<div class='col-md-3'>
      %CHANGE_DATE%
    </div>
  </div>

  <div class='form-group'>
    	<label for='' class='col-md-12 bg-primary'>_{PASSWD}_:</label>
  </div>

  <div class='form-group'>
 		%PASSWORD%
  </div>

</fieldset>
</div>

<div class='box-footer'>
	<input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
</div>

</div>
</form>
