<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{AUTO_COORDS}_</h4></div>
  <div class='box-body'>

    <form id='form_GMA' class='form form-horizontal'>


      <div class='form-group'>
        <label class='control-label col-md-7 required' for='COUNTRY_CODE_id'>_{COUNTRY}_ (2 letters)</label>
        <div class='col-md-5'>
          <input type='text' class='form-control' required name='COUNTRY_CODE' value='%COUNTRY_ABBR%'
                 id='COUNTRY_CODE_id'
                 placeholder='IANA format'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='DISCTRICT_ID'>_{DISTRICT}_</label>
        <div class='col-md-9'>
          %DISTRICT_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='STREET_ID'>_{STREET}_</label>
        <div class='col-md-9'>
          %STREET_SELECT%
        </div>
      </div>

      <div class='checkbox'>
        <label>
          <input type='checkbox' name='DISTRICTS_ARE_NOT_REAL' id='DISTRICTS_ARE_NO_REAL' data-return='1' value='1' data-checked='%DISTRICTS_ARE_NOT_REAL%' />
          <strong>_{FAKE}_ _{DISTRICTS}_</strong>
        </label>
      </div>

    </form>

  </div>
  <div class='box-footer text-center'>
    <button id='GMA_STOP_BTN' class='btn btn-danger' style='display: none'>_{HOLD_UP}_</button>
    <button id='GMA_EXECUTE_BTN' class='btn btn-primary'>_{START}_</button>
  </div>
</div>

<div class='progress'>
  <div class='progress-bar progress-bar-success progress-bar-striped' aria-valuenow='0' id='progress_status'
       style='width: 0'></div>
</div>

<script id='GMA_JSON'>%GMA_JSON%</script>

<script src='/styles/default_adm/js/maps/gma.js'></script>