<form action='$SELF_URL' class='form-horizontal'>
<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value=%ID%>

  <div class='box box-form box-primary'>
    <div class='box-header with-border'>_{GROUPS}_</div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='control-element col-md-3'>_{GROUP}_</label>
        <div class='col-md-9'>
          <input class='form-control' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-element col-md-3'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <button type='submit' name='ACTION' class='btn btn-primary'>%ACTION_LNG%</button>
    </div>
  </div>

</form>