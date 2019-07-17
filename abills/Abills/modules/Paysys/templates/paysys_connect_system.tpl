<form name='PAYSYS_CONNECT_SYSTEM' id='form_PAYSYS_CONNECT_SYSTEM' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='OLD_NAME' value='%NAME%'>

  <div class='box big-box'>
    <div class='box-header'>
      <h4>_{ADD}_ _{PAY_SYSTEM}_</h4>
    </div>

    <div class='box-body'>
      <div class='form-group %HIDE_SELECT%'>
        <label class='control-label col-md-3'>_{PAY_SYSTEM}_</label>
        <div class='col-md-9'>
          %PAYSYS_SELECT%
        </div>
      </div>
      <div id='paysys_connect_system_body'>

      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>ID:</label>
        <div class='col-md-9'>
          <input type='number' class='form-control' name='PAYSYS_ID' value='%PAYSYS_ID%' id='paysys_id' required>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='paysys_name' required pattern='[A-Za-z0-9_]{1,30}' data-tooltip="Только лат. буквы, цифры и подчеркивание">
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>IP</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='IP'>%IP%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{PAYMENT_TYPE}_</label>
        <div class='col-md-9'>
          %PAYMENT_METHOD_SEL%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{PRIORITY}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='PRIORITY' value='%PRIORITY%' >
        </div>
      </div>
      <div class='checkbox'>
        <label>
          <input type='checkbox' name='STATUS' data-return='1' value='1' data-checked='%ACTIVE%'> _{LOGON}_
        </label>
      </div>

    </div>

    <div class='box-footer'>
      <input class='btn btn-primary' type='submit' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
  }
  catch (err) {
    console.log('JSON parse error.');
  }

  function rebuild_form(type) {
    jQuery('.appended_field').remove();
    var keys = Object.keys(arr[type]['CONF']);
    var sorted = keys.sort();

    for (var i=0; i< sorted.length;i++){
      var val = arr[type]['CONF'][sorted[i]];
      var param = sorted[i];

      console.log(sorted[i] + " - " + val);

      var element = jQuery("<div></div>").addClass("form-group appended_field");
      element.append(jQuery("<label for=''></label>").text(param).addClass("col-md-3 control-label"));
      element.append(jQuery("<div></div>").addClass("col-md-9").append(
        jQuery("<input name='" + param + "' id='" + param + "' value='" + (val || '') + "'>").addClass("form-control")));

      jQuery('#paysys_connect_system_body').append(element);
    }
    jQuery('#paysys_id').val(arr[type]['ID']);
    var paysys_name_input =  document.getElementById("paysys_name").value;
    if(!paysys_name_input){
      jQuery('#paysys_name').val(arr[type]['NAME']);
    }
  }

  jQuery(function () {
    if(jQuery('#MODULE').val()) {
      rebuild_form(jQuery('#MODULE').val());
    }

    jQuery("#MODULE").change(function () {
      rebuild_form(jQuery('#MODULE').val());

    });
  });
</script>