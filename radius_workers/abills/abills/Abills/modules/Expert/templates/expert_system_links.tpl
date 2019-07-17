<form class='form-horizontal' name='expert'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='module' value='Expert'>
  <div class='col-md-6'>
    <div class='box box-theme box-form'>
      <div class='box-header with-border'><h3 class='box-title'>Ссылки для получения информации</h3></div>
      <div class='box-body'>
        <div class='col-md-12'>

          <div class="form-group">
            <label class='control-label col-md-3' for='server'>Abills server address</label>
            <div class='col-md-9'>
              <input name='server' value='%server%' class='form-control' type='text' placeholder='https://demo.abills.net.ua:9443/admin/index.cgi'>
            </div>
          </div>

          <div class="form-group">
            <label class='control-label col-md-3' for='api_key'>API KEY</label>
            <div class='col-md-9'>
              <input name='api_key' value='%api_key%' class='form-control' type='text'>
            </div>
          </div>

        </div>
      </div>
      <div class='box-footer'>
        <input type='submit' name='change_links' value='Изменить' class='btn btn-primary'>
      </div>  
    </div>
  </div>
</form>