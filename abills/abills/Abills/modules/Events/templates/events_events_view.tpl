<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{EVENTS}_ (%ID%)</h4></div>
  <div class='box-body form form-horizontal'>

    <div class='form-group'>

      <div class='col-md-6'>
        <label class='control-label col-md-4'>_{MODULE}_: </label>
        <div class='col-md-8'>
          <p class='form-control-static'>%MODULE%</p>
        </div>
      </div>

      <div class='col-md-6'>
        <label class='control-label col-md-4'>_{GROUP}_: </label>
        <div class='col-md-8'>
          <p class='form-control-static'>
            <a title='%GROUP_MODULES%' href='?get_index=events_group_main&full=1&chg=%GROUP_ID%'>%GROUP_NAME%</a>
          </p>
        </div>
      </div>

    </div>

    <div class='form-group'>
      <div class='col-md-6'>
        <label class='control-label col-md-4'>_{STATE}_: </label>
        <div class='col-md-8'>
          <p class='form-control-static'>%STATE_NAME_TRANSLATED%</p>
        </div>
      </div>
      <div class='col-md-6'>
        <label class='control-label col-md-4'>_{PRIORITY}_: </label>
        <div class='col-md-8'>
          <p class='form-control-static'>%PRIORITY_NAME_TRANSLATED%</p>
        </div>
      </div>
    </div>

    <hr>

    <div class='form-group'>
      <label class='control-label col-md-4'>_{CREATED}_: </label>
      <div class='col-md-8'>
        <p class='form-control-static'><strong>%CREATED%</strong><span class='moment-insert'
                                                                       data-value='%CREATED%'></span></p>
      </div>
    </div>

    <div class='form-group' data-visible='%EXTRA%'>
      <label class='control-label col-md-4'>URL: </label>
      <div class='col-md-8'>
        <p class='form-control-static'><a href='%EXTRA%' target='_blank'>%EXTRA%</a></p>
      </div>
    </div>

    <hr>

    <div class='form-group'>
      <label class='control-label col-md-4'>_{COMMENTS}_: </label>
      <div class='col-md-8'>
        <p class='form-control-static'>%COMMENTS%</p>
      </div>
    </div>

    <!--
          <div class='form-group'>
            <label class='control-label col-md-4' for='PRIVACY'>_{ACCESS}_: </label>
            <div class='col-md-8'>
              <p class='form-control-static'>%PRIVACY_NAME_TRANSLATED%</p>
            </div>
          </div>

          -->


  </div>
</div>

