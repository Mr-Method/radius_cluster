
<div class="box collapsed-box">
  <div class="box-header with-border">
    <h3 class="box-title">_{DOCS}_</h3>
	<div class="box-tools pull-right">
      <button type="button" class="btn btn-default btn-xs" data-widget="collapse">
	    <i class="fa fa-plus"></i>
      </button>
    </div>
  </div>
  <div class='box-body'>
    <div class='form-group'>
      <label class='control-label col-md-4' for='APPLY_TO_INVOICE'>_{APPLY_TO_INVOICE}_</label>
      <div class='col-md-8'>
        <select name='APPLY_TO_INVOICE' ID='APPLY_TO_INVOICE' class='form-control'>
          <option value=1>_{YES}_</option>
          <option value=0>_{NO}_</option>
		</select>
	  </div>
	</div>

    <div class='form-group'>
      <label class='control-label col-md-4' for='INVOICE_ID'>_{INVOICE}_</label>
      <div class='col-md-8'>
        %INVOICE_SEL%
      </div>
	</div>

	<div class='form-group'>
	  <label class='control-label col-md-4' for='CREATE_RECEIPT'>_{RECEIPT}_</label>
	  <div class='col-md-3'>
		<input type=checkbox name=CREATE_RECEIPT   value='1' %CREATE_RECEIPT_CHECKED% id='CREATE_RECEIPT'>
	  </div>
	</div>
	<input type=hidden name=SEND_EMAIL value='%SEND_MAIL%'>

  </div>
</div>