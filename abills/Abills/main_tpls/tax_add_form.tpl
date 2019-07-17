<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{TAX_MAGAZINE}_</h4></div>
  <div class='box-body'>
        <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='GET' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='ID' value='%ID%' />

      <div class='form-group'>
        <label class='control-label col-md-3' for='RATECODE_ID'>_{CODE}_ _{_TAX}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control'  required name='RATECODE'  id='RATECODE_ID' value='%RATECODE%' />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='RATEAMOUNT_ID'>_{PERCENT}_ _{_TAX}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control'  name='RATEAMOUNT'  id='RATEAMOUNT_ID' value='%RATEAMOUNT%' />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='RATEDESCR_ID'>_{DESCRIPTION}_</label>
        <div class='col-md-9'>
            <textarea rows="2" class='form-control' cols="45" name="RATEDESCR"  id='RATEDESCR_ID' value='%RATEDESCR%' ></textarea>
        </div>
      </div>

      <div class='checkbox text-center'>
        <label>
            <input type='checkbox' data-return='1' value = "1" data-checked='%CURRENT%' name='CURRENT'  id='CURRENT_ID'  />
            <strong>_{IN_USING}_</strong>
        </label>
      </div>

        </form>

  </div>
  <div class='box-footer text-center'>
      <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='%ACTION%' value="%BTN%">
  </div>
</div>     