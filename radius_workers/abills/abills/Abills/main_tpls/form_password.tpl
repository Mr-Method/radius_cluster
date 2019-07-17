<script src='/styles/default_adm/js/modules/config/password_generator.js'></script>

<script>
  jQuery(function () {
    var password_configuration_string = '$conf{CONFIG_PASSWORD}';

    var password_config_params = {
      LENGTH : '$conf{PASSWD_LENGTH}',
      SYMBOLS : '$conf{PASSWD_SYMBOLS}' || '1234567890abcdefgjhiklmnopqrstyquvwxyz'
    };

    if (password_configuration_string !== ''){
      var password_params_arr           = password_configuration_string.split(':') || [];

      if (password_params_arr.length === 3){
        password_config_params.CASE = password_params_arr[1] || 0;
        password_config_params.CHARS = password_params_arr[2] || 0;
      }
      else {
        password_config_params.CASE = password_params_arr[0] || 0;
        password_config_params.CHARS = password_params_arr[1] || 0;
      }

      password_config_params.LENGTH = '$conf{PASSWD_LENGTH}';
      delete password_config_params['SYMBOLS'];
    }

    var gen_btn = jQuery('#GENERATE_BTN');
    var gen_psw = jQuery('#GENERATED_PW');
    var cp_btn  = jQuery('#COPY_BTN');

    var passw_field1 = jQuery('#FIRST_PASSWORD_INPUT');
    var passw_field2 = jQuery('#SECOND_PASSWORD_INPUT');

    gen_btn.on('click', function () {
      var password = generatePassword(password_config_params);
      gen_psw.val(password);
    });

    cp_btn.on('click', function () {
      var generated_passw = gen_psw.val();
      passw_field1.val(generated_passw);
      passw_field2.val(generated_passw);
    });

  });
</script>

<form action='$SELF_URL' METHOD='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  %HIDDDEN_INPUT%
  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{PASSWD}_: %ID%</h4></div>
    <div class='box-body'>

      %EXTRA_ROW%

      <div class='form-group'>
        <label class='control-label col-md-4' for='FIRST_PASSWORD_INPUT'>_{NEW}_ _{PASSWD}_</label>

        <div class='col-md-8'>
          <input type='password' class='form-control' id='FIRST_PASSWORD_INPUT' name='newpassword' value='%newpassword%' title='_{PASSWD}_'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-4' for='SECOND_PASSWORD_INPUT'>_{CONFIRM_PASSWD}_</label>

        <div class='col-md-8'>
          <input type='password' class='form-control' name='confirm' value='%confirm%' id='SECOND_PASSWORD_INPUT' title='_{CONFIRM}_'/>
        </div>
      </div>


      <div class='form-group'>
        <label class='control-label col-md-6' for='GENERATED_PW'>
          <input type='button' id='GENERATE_BTN' class='btn btn-info btn-xs' value='_{GENERED_PARRWORD}_'>
          <input type='button' id='COPY_BTN' class='btn btn-info btn-xs' value='Copy'>

        </label>

        <div class='col-md-6'>
          <input type='text' class='form-control' name='generated_pw' id='GENERATED_PW' autocomplete='off'/>
        </div>
      </div>

      <div class='form-group' data-visible='%RESET_INPUT_VISIBLE%'>
        <label class='control-label col-md-5'>_{RESET}_</label>
        <div class='col-md-7'>
          <input type='checkbox' name='RESET' class='control-element' style='margin-top: 7px;'/>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>

<link rel='stylesheet' href='/styles/default_adm/css/client_social_icons.css'>
<div class='row col-md-offset-2'>
  <ul class='social-network social-circle'>
    %SOCIAL_AUTH_BLOCK%
  </ul>
</div>

%EXTRA_FORM%
