<form action='$SELF_URL' METHOD='GET' name='form_search' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name="visual" value='%VISUAL%'>
  <input type='hidden' name="NAS_ID" value='%NAS_ID%'>
  <div class='box box-theme box-big-form'>
    <div class='box-header with-border' style="border-bottom: none; ">
      <div class='row'>
        <div class='col-md-3'>
          <button class='btn btn-primary btn-block' type='submit' style="margin-bottom: 10px;">
            <i class='glyphicon glyphicon-search'></i> _{SEARCH}_
          </button>
        </div>
        <div class='col-md-9'>
          <div class="input-group">
            <input  name='grep' class='form-control' type='text' value='%grep%'>
            <span class='input-group-addon'>
              <input type='checkbox' name='all_logs' value='checked' %all_logs% data-tooltip="_{ALL}_ _{NASS}_">
            </span>
          </div>
      </div>
      
    </div>
<div class="box-body">
  %LOG_FILE%
</div>
</div>
</div>

</form>



