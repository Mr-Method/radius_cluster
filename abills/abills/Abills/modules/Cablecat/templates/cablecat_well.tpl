<div class='row'>
  <div class='%MAIN_FORM_SIZE%'>
    <div class='box box-theme'>
      <div class='box-header with-border'><h4 class='box-title'>_{WELL}_</h4></div>
      <div class='box-body'>
        <form name='CABLECAT_WELLS' id='form_CABLECAT_WELLS' method='post' class='form form-horizontal'>
          <input type='hidden' name='index' value='$index'/>
          <input type='hidden' name='ID' value='%ID%'/>
          <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
          %EXTRA_INPUTS%

          <div class='form-group'>
            <label class='control-label col-md-3 required' for='NAME_ID'>_{NAME}_</label>

            <div class='col-md-9'>
              <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID'/>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3 required' for='TYPE_ID_SELECT'>_{TYPE}_</label>
            <div class='col-md-9'>
              %TYPE_ID_SELECT%
            </div>
          </div>


          <div class='form-group'>
            <label class='control-label col-md-3' for='INSTALLED_ID'>_{INSTALLED}_</label>
            <div class='col-md-9'>
              <input type='text' class='form-control datepicker' value='%INSTALLED%' name='INSTALLED'
                     id='INSTALLED_ID'/>
            </div>
          </div>

          <div class='form-group should-be-hidden'>
            <label class='control-label col-md-3' for='POINT_ID'>_{OBJECT}_</label>
            <div class='col-md-9'>
              %POINT_ID_SELECT%
            </div>
          </div>

          <div class='checkbox text-center should-be-hidden' data-visible='%ADD_OBJECT_VISIBLE%'>
            <label>
              <!-- Here 1 is WELL map type_id -->
              <input type='checkbox' name='ADD_OBJECT' value='1'
                     data-return='1' data-checked='%ADD_OBJECT%'
                     data-input-disables='POINT_ID'
              />
              <strong>_{CREATE}_ _{OBJECT}_</strong>
            </label>
          </div>

          <hr/>

          <div class='form-group'>
            <label class='control-label col-md-3' for='PARENT_ID'>_{INSIDE}_</label>
            <div class='col-md-9'>
              %PARENT_ID_SELECT%
            </div>
          </div>
        </form>

      </div>
      <div class='box-footer'>
        <input type='submit' form='form_CABLECAT_WELLS' class='btn btn-primary' name='submit'
               value='%SUBMIT_BTN_NAME%'>
      </div>
    </div>
  </div>

  <div class='col-md-6'>
    <div class='box box-theme' data-visible='%HAS_LINKED%'>
      <div class='box-header with-border'><h4 class='box-title'>_{LINKED}_ _{CABLES}_ -> _{WELLS}_</h4></div>
      <div class='box-body text-left'>
        %LINKED%
      </div>
    </div>
  </div>

  <div class='col-md-6'>
    <div class='box box-theme' style='display: none' data-visible='%CONNECTERS_VISIBLE%' id='CONNECTERS_BOX'>
      <div class='box-header with-border'><h4 class='box-title'>_{CONNECTERS}_</h4></div>
      <div class='box-body'>
        %CONNECTERS%
      </div>
    </div>
  </div>
</div>

<script>
  jQuery(function () {
    var form_id        = 'form_CABLECAT_CONNECTERS';
    var connecters_box = jQuery('div#CONNECTERS_BOX');

    if (connecters_box.length) {
      // Add connecter form opened on modal
      var add_btn = jQuery('#add_connecter');
      modify_add_connecter_btn();

      function modify_add_connecter_btn() {
        if (!add_btn.length) return false;

        add_btn.on('click', function (event) {
          cancelEvent(event);

          var href = add_btn.attr('href');
          href     = href.replace(/\?index=/, '\?qindex=');
          href += '&header=2&TEMPLATE_ONLY=1';

          Events.once('modal_loaded', setup_modal_connecter_add_form);
          loadToModal(href);
        });

        add_btn.addClass('btn btn-default');
      }

      function setup_modal_connecter_add_form(modal) {

        var form = modal.find('form#' + form_id);

        // If wrong form was loaded, do nothing
        if (!form.length) return false;

        var holder = modal.find('#CONNECTER_FORM_CONTAINER_DIV');

        // Make form wider
        holder.attr('class', 'col-md-12');

        // Make form submitted via POST
        form.off('submit');
        form.on('submit', ajaxFormSubmit);
      }

      function refreshConnectersView() {
        aModal.hide();

        console.log('box_refresh');
        setBoxRefreshingState(connecters_box, true);
        console.log(connecters_box, true);
        jQuery('#WELL_CONNECTERS_LIST').load(' #WELL_CONNECTERS_LIST', function () {
          setBoxRefreshingState(connecters_box, false);
        });
      }

      // Refresh list each time it has been changed
      Events.on('form_CABLECAT_CONNECTERS', refreshConnectersView);
      Events.on('AJAX_SUBMIT.' + form_id, refreshConnectersView);
    }

    // Auto max_prev_type name
    {
      // Select id
      var select_id     = 'TYPE_ID';
      var count_of_type = JSON.parse('%COUNT_FOR_TYPE%');

      var name_input  = jQuery('input#NAME_ID');
      var type_select = jQuery('select#' + select_id);
      type_select.on('change', function () {
        var name = type_select.find('option[value="' + this.value + '"]').text();
        name_input.val(name + '_' + (+count_of_type[this.value] + 1));
      });
    }
  });

</script>