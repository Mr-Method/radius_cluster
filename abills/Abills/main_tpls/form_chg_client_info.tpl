<div class='text-center'>
  <form action='$SELF_URL' method='post' class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=sid value='$sid'>

    <div class='box box-primary'>
      <div class='box-header with-border text-center'>
        <h4>Изменение данных</h4>
      </div>
      %MESSAGE_CHG%
      <div class='box-body'>

        <div class='form-group %FIO_HAS_ERROR% %FIO_HIDDEN%'>
          <label class='col-md-3 required control-label'>_{FIO}_:</label>

          <div class='col-md-9'><input name='FIO' value='%FIO%' class='form-control' %FIO_DISABLE%/></div>
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

      </div>

      <div class='box-footer text-center'>
        <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary text-center'>
      </div>
    </div>
  </form>
</div>