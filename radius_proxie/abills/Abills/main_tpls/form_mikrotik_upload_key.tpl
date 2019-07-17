<form action='$SELF_URL' method='post' class='form form-horizontal'>

  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='mikrotik_hotspot' value='1'/>
  <input type='hidden' name='ADMIN' value='%ADMIN%'/>
  <input type='hidden' name='NAS_ID' value='%NAS_ID%'/>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4>Mikrotik SSH Key Upload</h4></div>
    <div class='box-body'>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{LOGIN}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='SYSTEM_ADMIN' value='%SYSTEM_ADMIN%'/>
        </div>
      </div>


      <div class='form-group'>
        <label class='control-label col-md-3'>_{PASSWD}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='SYSTEM_PASSWD' value='%SYSTEM_LOGIN%'/>
        </div>
      </div>


    </div>
    <div class='box-footer'>
      <input type='submit' name='upload_key' value='_{SET}_' id='go'>
    </div>
  </div>
</form>