<form action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='AWEB_OPTIONS' value='1'/>
  <input id="skin" type='hidden' name='SKIN' value="%SKIN%"/>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class="box-title">_{PROFILE}_</h4></div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{LANGUAGE}_:</label>

        <div class='col-md-9'>
          %SEL_LANGUAGE%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-4'>_{REFRESH}_ (sec.):</label>

        <div class='col-md-3'>
          <input type='text' name='REFRESH' value='$admin->{SETTINGS}{REFRESH}' class='form-control'/>
        </div>
        <label class='control-label col-md-2'>_{ROWS}_:</label>

        <div class='col-md-3'>
          <input type='text' name='PAGE_ROWS' value='$PAGE_ROWS' class='form-control'/>
        </div>
      </div>

      <div class='form-group'>
        <legend>_{EVENTS}_</legend>
      </div>

      <div class='row'>
        %SUBSCRIBE_BLOCK%
      </div>

      <div class="row">

        <div class='checkbox col-md-6'>
          <label>
            <input type='checkbox' data-return='1' name='NO_EVENT' value='1' data-checked='%NO_EVENT%'/>
            <strong>_{DISABLE}_</strong>
          </label>
        </div>
        <div class='checkbox col-md-6'>
          <label>
            <input type='checkbox' data-return='1' name='NO_EVENT_SOUND' value='1' data-checked='%NO_EVENT_SOUND%'/>
            <strong>_{DISABLE}_ _{SOUND}_</strong>
          </label>
        </div>

      </div>

      <hr>

      <div class='form-group'>
        <label class='control-label col-md-3 %EVENTS_GROUPS_HIDDEN%' for='GROUP'>_{GROUP}_</label>
        <div class='col-md-9'>
          %EVENT_GROUPS_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <legend>_{COLOR}_</legend>
      </div>


      <ul class="list-unstyled clearfix">
        <li>
          <a href="javascript:void(0);" data-skin="skin-blue" class="clearfix full-opacity-hover">
            <div>
              <span class='skin skin-logo' style="background: #367fa9;"></span>
              <span class='skin skin-header bg-light-blue'></span>
            </div>
            <div>
              <span class='skin skin-sidebar' style="background: #222;"></span>
              <span class='skin skin-content' style="background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin">Blue</p>
        </li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-black" class="clearfix full-opacity-hover">
            <div style="box-shadow: 0 0 2px rgba(0,0,0,0.1)" class="clearfix">
              <span class='skin skin-logo' style="background: #fefefe;"></span>
              <span class='skin skin-header' style="background: #fefefe;"></span>
            </div>
            <div>
              <span class='skin skin-sidebar' style="background: #222;"></span>
              <span class='skin skin-content' style="background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin">White</p>
        </li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-purple" class="clearfix full-opacity-hover">
            <div>
<span style="display:block; width: 20%; float: left; height: 7px;"
      class="bg-purple-active"></span>
              <span
                  class="bg-purple" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #222;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin">Purple</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-green" class="clearfix full-opacity-hover">
            <div>
              <span style="display:block; width: 20%; float: left; height: 7px;" class="bg-green-active"></span>
              <span class="bg-green" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #222;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin">Green</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-red" class="clearfix full-opacity-hover">
            <div>
<span style="display:block; width: 20%; float: left; height: 7px;"
      class="bg-red-active"></span>
              <span class="bg-red" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #222;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin">Red</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-yellow" class="clearfix full-opacity-hover">
            <div>
              <span style="display:block; width: 20%; float: left; height: 7px;" class="bg-yellow-active"></span>
              <span class="bg-yellow" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #222;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin">Yellow</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-blue-light" class="clearfix full-opacity-hover">
            <div>
              <span style="display:block; width: 20%; float: left; height: 7px; background: #367fa9;"></span>
              <span
                  class="bg-light-blue" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #f9fafc;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin" style="font-size: 12px">Blue Light</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-black-light" class="clearfix full-opacity-hover">
            <div style="box-shadow: 0 0 2px rgba(0,0,0,0.1)" class="clearfix">
              <span style="display:block; width: 20%; float: left; height: 7px; background: #fefefe;"></span>
              <span style="display:block; width: 80%; float: left; height: 7px; background: #fefefe;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #f9fafc;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin" style="font-size: 12px">White Light</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-purple-light" class="clearfix full-opacity-hover">
            <div>
              <span style="display:block; width: 20%; float: left; height: 7px;" class="bg-purple-active"></span>
              <span class="bg-purple" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #f9fafc;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin" style="font-size: 12px">Purple Light</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-green-light" class="clearfix full-opacity-hover">
            <div>
<span style="display:block; width: 20%; float: left; height: 7px;"
      class="bg-green-active"></span>
              <span class="bg-green" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #f9fafc;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin" style="font-size: 12px">Green Light</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-red-light" class="clearfix full-opacity-hover">
            <div>
<span style="display:block; width: 20%; float: left; height: 7px;"
      class="bg-red-active"></span>
              <span class="bg-red"
                    style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #f9fafc;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin" style="font-size: 12px">Red Light</p></li>
        <li>
          <a href="javascript:void(0);" data-skin="skin-yellow-light"
             style="display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)"
             class="clearfix full-opacity-hover">
            <div>
<span style="display:block; width: 20%; float: left; height: 7px;"
      class="bg-yellow-active"></span>
              <span
                  class="bg-yellow" style="display:block; width: 80%; float: left; height: 7px;"></span>
            </div>
            <div>
              <span style="display:block; width: 20%; float: left; height: 40px; background: #f9fafc;"></span>
              <span style="display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;"></span>
            </div>
          </a>
          <p class="text-center no-margin" style="font-size: 12px;">Yellow Light</p></li>
      </ul>
    </div>

    <div class='box-footer'>
      <input type='submit' name='set' value='_{SET}_' class='btn btn-primary'/>
    </div>
  </div>


  %QUICK_REPORTS%


  <input type='submit' name='set' value='_{SET}_' class='btn btn-primary'/>
  <input type='submit' name='default' value='_{DEFAULT}_' class='btn btn-default'/>
  <span class="col-xs-12" style="margin-top: 10px"> </span>
</form>

<style>
  ul.list-unstyled > li {
    float: left;
    width: calc(100% / 3);
    padding: 5px 5%;
  }

  ul.list-unstyled > li > a {
    display: block;
    box-shadow: 0 0 3px rgba(0, 0, 0, 0.4);
  }

  a[data-skin] .skin {
    display: block;
    float: left;
  }

  a[data-skin] span.skin-logo {
    width: 20%;
    height: 7px;
  }

  a[data-skin] span.skin-header {
    width: 80%;
    height: 7px;
  }

  a[data-skin] span.skin-sidebar {
    width: 20%;
    height: 40px;
  }

  a[data-skin] span.skin-content {
    width: 80%;
    height: 40px;
  }

</style>

<script>
  window['ENABLE_PUSH'] = '_{ENABLE_PUSH}_';
  window['DISABLE_PUSH'] = '_{DISABLE_PUSH}_';
  window['PUSH_IS_NOT_SUPPORTED'] = '_{PUSH_IS_NOT_SUPPORTED}_';
  window['PUSH_IS_DISABLED'] = '_{PUSH_IS_DISABLED}_';
</script>