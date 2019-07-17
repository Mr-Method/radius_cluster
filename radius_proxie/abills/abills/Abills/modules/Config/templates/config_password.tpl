<script src='/styles/default_adm/js/modules/config/password_generator.js'></script>
<form action='$SELF_URL' method='post' class='form form-horizontal' id='PASSWORD_GENERATOR_FORM'>
  <input type='hidden' name='index' value='$index'>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'>
      <h3>_{PASSWORD_GENERATOR}_</h3>
    </div>
    <div class='box-body'>

      <div class='form-group'>
        <label for='SYMBOLS_COUNT' class='col-md-5 control-label'>_{SYMBOLS_COUNT}_</label>
        <div class='col-md-7'>
          <input type='number' class='form-control'
                 min='%MIN_LENGTH%' max='%MAX_LENGTH%'
                 id='SYMBOLS_COUNT' name='SYMBOLS_COUNT'
                 value='%SYMBOLS_COUNT%'/>
        </div>
      </div>

      <hr/>

      <div class='form-group' id='CASE_RADIO'>
        <label for='CASEUPPER' class='col-md-5 control-label'>_{LETTERS}_</label>
        <div class='col-md-7 text-left'>

          <div class='radio'>
            <label><input type='radio' name='CASE' id='CASEUPPER' %CASE_0_CHECKED% value='0'>_{LOWERCASE}_ (abc)</label>
          </div>
          <div class='radio'>
            <label><input type='radio' name='CASE' id='CASELOWER' %CASE_1_CHECKED% value='1'>_{UPPERCASE}_ (ABC)</label>
          </div>
          <div class='radio'>
            <label><input type='radio' name='CASE' id='CASEBOTH' %CASE_2_CHECKED% value='2'>_{BOTH_CASES}_ (aBc)</label>
          </div>
          <div class='radio'>
            <label><input type='radio' name='CASE' id='CASENO' %CASE_3_CHECKED% value='3'>_{NO}_</label>
          </div>
        </div>
      </div>

      <hr/>

      <div class='form-group' id='CHARS_RADIO'>
        <label for='CHARSUPPER' class='col-md-5 control-label'>_{NON_ALPHABET_SYMBOLS}_</label>
        <div class='col-md-7 text-left'>

          <div class='radio'>
            <label><input type='radio' name='CHARS' id='CHARSUPPER' %CHARS_0_CHECKED% value='0'>_{NUMBERS}_</label>
          </div>
          <div class='radio'>
            <label><input type='radio' name='CHARS' id='CHARSLOWER' %CHARS_1_CHECKED%
                          value='1'>_{SPECIAL_CHARS}_</label>
          </div>
          <div class='radio'>
            <label><input type='radio' name='CHARS' id='CHARSBOTH' %CHARS_2_CHECKED% value='2'>_{NUMBERS}_ + _{SPECIAL_CHARS}_</label>
          </div>
          <div class='radio'>
            <label><input type='radio' name='CHARS' id='CHARSNONE' %CHARS_3_CHECKED% value='3'>_{NO}_</label>
          </div>
        </div>
      </div>

      <hr/>

      <div class='form-group'>
        <div class='col-md-3'>
          <button role='button' class='btn btn-success' id='GENERATE_PASSWORD'>_{PREVIEW}_</button>
        </div>
        <div class='col-md-9'>
          <input type='text' class='form-control' aria-describedby='GENERATE_PASSWORD' readonly='readonly'
                 id='PREVIEW_INPUT'/>
        </div>
      </div>

    </div>
    <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name='action' value='_{SAVE}_'>
      <input type='submit' class='btn btn-default' name='reset' value='_{CLEAR}_'>
    </div>
  </div>
</form>

<script>
  jQuery(function () {

    var form                   = jQuery('form#PASSWORD_GENERATOR_FORM');
    var _password_length_input = jQuery('#SYMBOLS_COUNT');
    var _generate_btn          = jQuery('button#GENERATE_PASSWORD');
    var _preview_input         = jQuery('#PREVIEW_INPUT');

    _generate_btn.on('click', function (e) {
      e.preventDefault();

      var length = _password_length_input.val();

      var max_length = 32;
      var min_length = _password_length_input.attr('min');

      length = Math.min(length, max_length);
      length = Math.max(length, min_length);

      if (!is_at_least_one_constraint_selected()){
        jQuery('input#CHARSBOTH').prop('checked', true);
        jQuery('input#CASEBOTH').prop('checked', true);
      }

      var _case  = getRadioValue('CASE');
      var _chars = getRadioValue('CHARS');

      var generated_password = generatePassword({LENGTH: length, CASE: _case, CHARS: _chars});

      _preview_input.val(generated_password);
    });

    form.on('submit', function (e) {
      if (!is_at_least_one_constraint_selected()){
        cancelEvent(e);
        alert('Please select at least one of constraints');
      }
    });

    function is_at_least_one_constraint_selected() {
      var _case  = getRadioValue('CASE');
      var _chars = getRadioValue('CHARS');
      return !(_case === _chars && _case === "3")
    }
  });

</script>