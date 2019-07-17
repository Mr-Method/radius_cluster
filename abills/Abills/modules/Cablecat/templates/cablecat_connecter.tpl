<div class='row'>
  <div class='%CLASS_FOR_MAIN_FORM%' id='CONNECTER_FORM_CONTAINER_DIV'>
    <div class='box box-theme'>
      <div class='box-header with-border'><h4 class='box-title'>_{CONNECTER}_</h4></div>
      <div class='box-body'>
        <form name='CABLECAT_CONNECTERS' id='form_CABLECAT_CONNECTERS' method='post' class='form form-horizontal'>
          <input type='hidden' name='index' value='$index'/>
          <input type='hidden' name='ID' value='%ID%'/>
          <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

          <div class='form-group'>
            <label class='control-label col-md-3' for='NAME_ID'>_{NAME}_</label>
            <div class='col-md-9'>
              <input type='text' class='form-control' value='%NAME%' name='NAME'
                     id='NAME_ID'/>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3 required' for='TYPE_ID'>_{CONNECTER_TYPE}_</label>
            <div class='col-md-9'>
              %TYPE_ID_SELECT%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3 required' for='WELL_ID'>_{WELL}_</label>
            <div class='col-md-9'>
              %WELL_ID_SELECT%
            </div>
          </div>

          %OBJECT_INFO%

        </form>

      </div>
      <div class='box-footer text-center'>
        <input type='submit' form='form_CABLECAT_CONNECTERS' class='btn btn-primary' name='submit'
               value='%SUBMIT_BTN_NAME%'>
      </div>
    </div>
  </div>

  <div class='col-md-6' data-visible='%HAS_COMMUTATION_FORM%'>
    <div class='box box-theme'>
      <div class='box-header with-border'><h4 class='box-title'>_{COMMUTATION}_</h4></div>
      <div class='box-body'>
        %COMMUTATION_FORM%
      </div>
    </div>
  </div>
  <div class='col-md-6' data-visible='%HAS_LINKED%'>
    <div class='box box-theme'>
      <div class='box-header with-border'><h4 class='box-title'>_{LINKED}_ _{CONNECTERS}_</h4></div>
      <div class='box-body'>
        %LINKED%
      </div>
    </div>
  </div>
</div>

%INFO_DOCS%

<script>
  jQuery(function () {
    /**
     *  Sets up listener to refresh table,
     *  when new commutation has been added
     */
    var table_selector = 'table#CONNECTER_COMMUTATION_TABLE_ID_';
    var table          = jQuery('' + table_selector);
    Events.on('AJAX_SUBMIT.CABLECAT_CREATE_COMMUTATION_FORM', function () {
      table.load(window.location.href + ' ' + table_selector, function () {
        // For "del" button functionality
        defineCommentModalLogic(table);
      });
    });
  })
</script>