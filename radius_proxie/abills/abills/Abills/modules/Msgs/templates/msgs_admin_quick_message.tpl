<div class='modal-content' id='modal_MSGS_QUICK_MESSAGE'>
  <div class='box box-theme'>
    <div class='box-header with-border'><h4 class='box-title'>_{MESSAGE}_</h4></div>
    <div class='box-body'>

      <form name='form_MSGS_QUICK_MESSAGE' id='form_MSGS_QUICK_MESSAGE' method='post'
            class='form form-horizontal ajax-submit-form'>
        <input type='hidden' name='qindex' value='$index'/>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='header' value='2'/>

        <div class='form-group'>
          <label class='control-label col-md-3' for='CHECKBOXES'>_{SEND}_</label>
          <div class='col-md-9'>
            %CHECKBOXES%
          </div>
        </div>

        <div class="col-md-9 col-md-offset-3">
          <div class='radio' data-visible='%PUSH_RADIO_VISIBLE%'>
            <label>
              <input type='radio' name='SEND_TYPE' id='SEND_TYPE_PUSH' value='Push' checked='checked'>
              <strong>Push</strong>
            </label>
          </div>
          <div class='radio' data-visible='%BROWSER_RADIO_VISIBLE%'>
            <label>
              <input type='radio' name='SEND_TYPE' id='SEND_TYPE_BROWSER' value='Browser'>
              <strong>Browser</strong>
            </label>
          </div>
        </div>


        <div class='form-group'>
          <label for='MESSAGE' class='col-md-3 control-label'>_{MESSAGE}_</label>
          <div class='col-md-9'>
            <textarea class='form-control' name='MESSAGE' id='MESSAGE' rows='3'></textarea>
          </div>
        </div>


      </form>

    </div>
    <div class='box-footer'>
      <input type='submit' form='form_MSGS_QUICK_MESSAGE' class='btn btn-primary' name='submit' value='_{SEND}_'>
    </div>
  </div>

</div>

<script>
  pageInit(jQuery('#modal_MSGS_QUICK_MESSAGE'));

//  jQuery('form#form_MSGS_QUICK_MESSAGE').on('submit', function (e) {
//    ajaxFormSubmit(e);
//  });
    Events.on('AJAX_SUBMIT.form_MSGS_QUICK_MESSAGE', aModal.hide.bind(aModal));
</script>