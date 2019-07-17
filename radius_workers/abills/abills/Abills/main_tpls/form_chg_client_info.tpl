<div class='text-center'>
  <form action='$SELF_URL' method='post' class='form form-horizontal pswd-confirm'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=sid value='$sid'>

    <div class='box box-primary'>
      <div class='box-header with-border text-center'>
        <h4>Изменение данных</h4>
      </div>
      %MESSAGE_CHG%
      <div class='box-body'>

        <div id='simple_fio'>
          <div class='form-group' %FIO_HAS_ERROR% %FIO_HIDDEN%>
            <label class='control-label col-xs-3 required' for='FIO'>_{FIO}_</label>
            <div class='col-xs-9'>
              <div class="input-group">
                <input name='FIO' class='form-control' %FIO_READONLY% %FIO_DISABLE% id='FIO' value='%FIO%'>
                <span class="input-group-btn">
                  <button id='show_fio' type="button" class='btn btn-default' tabindex='-1'>
                    <i class="fa fa-bars"></i>
                  </button>
                </span>
              </div>
            </div>
          </div>
        </div>
        
        <div id='full_fio' style='display:none'>
          <div class='form-group'>
            <label class='control-label col-xs-3' for='FIO1'>_{FIO1}_</label>
            <div class='col-xs-9'>
              <div class="input-group">
                <input name='FIO1' class='form-control' id='FIO1' value='%FIO1%'>
                <span class="input-group-btn">
                  <button id='hide_fio' type="button" class='btn btn-default' tabindex='-1'>
                    <i class='fa fa-reply'></i>
                  </button>
                </span>
              </div>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-xs-3' for='FIO2'>_{FIO2}_</label>
            <div class='col-xs-9'>
              <input name='FIO2' class='form-control' id='FIO2' value='%FIO2%'>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-xs-3' for='FIO3'>_{FIO3}_</label>
            <div class='col-xs-9'>
              <input name='FIO3' class='form-control' id='FIO3' value='%FIO3%'>
            </div>
          </div>
        </div>
        <div class='form-group %PHONE_HAS_ERROR% %PHONE_HIDDEN%'>
          <label class='col-md-3 required control-label'>_{PHONE}_:</label>

          <div class='col-md-9'><input type=text name=PHONE value='%PHONE%' class='form-control' %PHONE_DISABLE%></div>
        </div>

        <div class='form-group %EMAIL_HAS_ERROR% %EMAIL_HIDDEN%'>
          <label class='col-md-3 control-label required'>E-mail:</label>

          <div class='col-md-9'><input type=text name=EMAIL value='%EMAIL%' class='form-control' %EMAIL_DISABLE%></div>
        </div>

        <hr/>

        <!--<div class='%ADDRESS_HIDDEN% %ADDRESS_DISABLE%'>-->
          %ADDRESS_SEL%
        <!--</div>-->

        %INFO_FIELDS%
        %INFO_FIELDS_POPUP%

      </div>

      <div class='box-footer'>
        %BTN_TO_MODAL%
        <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary text-center'>
      </div>
    </div>
  </form>
</div>

<script type="text/javascript">
  jQuery('#show_fio').click(function() {
    jQuery('#simple_fio').fadeOut(200);
    jQuery('#full_fio').delay(201).fadeIn(300);
  });

  jQuery('#hide_fio').click(function() {
    jQuery('#full_fio').fadeOut(200);
    jQuery('#simple_fio').delay(201).fadeIn(300);
  });
</script>