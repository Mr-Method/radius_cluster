%SEL_TYPE%

<form action='$SELF_URL' METHOD='GET' name='form_search' id='form_search' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='search_form' value='1'>
  %HIDDEN_FIELDS%
  <fieldset>

    <!--        <button class='btn btn-primary btn-block' type='submit' name='search' value=1>
                <i class='glyphicon glyphicon-search'></i> _{SEARCH}_
            </button>-->

    <div class='col-xs-12 col-md-6'>
      <div class='box box-theme box-big-form'>
        <div class='box-header with-border'>
          <h3 class="box-title">_{USER}_</h3>
          <div class="box-tools pull-right">
            <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-minus"></i>
            </button>
          </div>
        </div>
        <div class="box-body" style="padding: 0">
          <div style="padding: 10px">

            <div class='form-group'>
              <label class='control-label col-xs-4 col-md-2' for='LOGIN'>_{LOGIN}_ (*,)</label>

              <div class='col-xs-8 col-md-4'>
                <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%'
                       class='form-control' type='text'>
              </div>
              <span class="visible-xs visible-sm col-xs-12" style="padding-top: 10px"> </span>
              <label class='control-label col-xs-4 col-md-2' for='PAGE_ROWS'>_{ROWS}_</label>

              <div class='col-xs-8 col-md-4'>
                <input id='PAGE_ROWS' name='PAGE_ROWS' value='%PAGE_ROWS%' placeholder='$PAGE_ROWS'
                       class='form-control' type='text'>
              </div>
            </div>

            <div class='form-group' align='left' %HIDE_DATE%>
              <label class='control-label col-md-2' for='FROM_DATE'>_{PERIOD}_</label>

              <div class=' col-md-4'>
                %FROM_DATE%
              </div>

              <div class='col-md-2 '> -
              </div>
              <div class='col-md-4'>
                %TO_DATE%
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-xs-2'>_{GROUP}_:</label>

              <div class='col-xs-10'>%GROUPS_SEL%</div>
            </div>

            <div class='form-group'>
              <label class='control-label col-xs-2' for='TAGS'>_{TAGS}_</label>
              <div class='col-xs-10'>
                <div class='input-group'>
                  %TAGS_SEL%
                  <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                    <i class='fa fa-exclamation'></i>
                    <input type="checkbox" name='TAGS' data-input-disables=TAGS value='!'>
                  </span>
                </div>
              </div>
            </div>
          </div>
          %ADDRESS_FORM%
        </div>
      </div>
    </div>
    <!--<div class='row'>-->
      %SEARCH_FORM%
    <!--</div>-->
    <button class='btn btn-primary btn-block' type='submit' name='search' id='go' value=1 style="margin-bottom: 10px;">
      <i class='glyphicon glyphicon-search'></i> _{SEARCH}_
    </button>

  </fieldset>
</form>
