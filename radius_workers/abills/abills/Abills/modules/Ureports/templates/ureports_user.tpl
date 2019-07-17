<script src='/styles/default_adm/js/modules/ureports/sender_contact_choose.js'></script>
<script>
  var LANG = {
    NO_CONTACTS_FOR_TYPE : '_{NO_CONTACTS_FOR_TYPE}_'
  };

  var contacts_list;
  try {
    contacts_list = JSON.parse('%UID_CONTACTS%');
  }
  catch (Error) {
    console.log(Error);
    alert("Error while parsing contacts. Please contact support system");
  }

  var current_destination = '%DESTINATION%';

  jQuery(function () {

    var type_select = jQuery('select#TYPE');
    var result_wrapper = jQuery('div#DESTINATION_SELECT_WRAPPER');

    var chooser = new ContactChooser(true, contacts_list, type_select, result_wrapper);
    chooser.setValue(current_destination);
  })

</script>

%MENU%

<form action='$SELF_URL' method='post' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='step' value='$FORM{step}'>

  <fieldset>

    <div class='box box-theme box-form'>
      <div class='box-body'>

        <div class='form-group'>
          <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_</label>
          <div class='col-md-9'>
            <div class='input-group'>
              <span class='input-group-addon bg-primary'>%TP_ID%</span>
              %TP_NAME%
              <span class='input-group-addon'>%CHANGE_TP_BUTTON%</span>
            </div>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-4' for='TYPE'>_{TYPE}_</label>
          <div class='col-md-8'>
            %TYPE_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-4' for='DESTINATION'>_{DESTINATION}_</label>
          <div class='col-md-6' id='DESTINATION_SELECT_WRAPPER'>
            %DESTINATION_VIEW%
          </div>
          <div class="col-md-2">
            <button class='btn btn-sm btn-default' id='MANUAL_EDIT_CONTACT_BTN'>
              <span class="glyphicon glyphicon-pencil"></span>
            </button>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-4' for='STATUS'>_{STATUS}_</label>
          <div class='col-md-8'>
            %STATUS_SEL%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-4'>_{REGISTRATION}_</label>
          <div class='col-md-8'>
            <p class="form-control-static">%REGISTRATION%</p>
          </div>
        </div>

      </div>

      <div class='box-footer'>
        <input type=submit class='btn btn-primary' id='SUBMIT_UREPORTS_USER' name='%ACTION%' value='%LNG_ACTION%'>
        %HISTORY_BTN%
      </div>

    </div>

    <div>%REPORTS_LIST%</div>

  </fieldset>
</form>
