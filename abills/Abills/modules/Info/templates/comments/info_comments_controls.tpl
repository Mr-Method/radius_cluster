<div class='btn-group btn-group-xs'>
  <a role='button' class='btn btn-default btn-xs btn-primary' data-toggle='modal' data-target='#info_comments_modal'>
    <span class='glyphicon glyphicon-plus'></span>
  </a>

  <button role='button' class='btn btn-default btn-xs btn-success' id='info_comments_refresh'
          data-object_id='%OBJECT_ID%' data-object_type='%TABLE_NAME%'
          data-renews="#commentsBlock" data-source="info_comments_renew">
    <span class='glyphicon glyphicon-refresh'></span>
  </button>
</div>
<div class='modal fade' id='info_comments_modal' tabindex='-1' role='dialog'>
  <div class='modal-dialog'>
    <form class='form-horizontal form-horizontal' id='form_add_comments'>
      <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
              aria-hidden='true'>&times;</span></button>
          <h4 class='modal-title' id='info_comments_modal_title'>_{ADD}_ _{COMMENTS}_</h4>
        </div>
        <div class='modal-body' id='info_comments_body'>
          <div class='row'>
            <input id='OBJECT_TYPE' type='hidden' value='%TABLE_NAME%'>
            <input id='OBJECT_ID' type='hidden' value='%OBJECT_ID%'>
            <input id='ADD_INDEX' type='hidden' value='%ADD_COMMENT_INDEX%'>

            <div class='form-group'>
              <label class='control-label col-md-3' for='COMMENTS_TEXT'>_{COMMENTS}_</label>

              <div class='col-md-9'>
                <textarea class='form-control' id='COMMENTS_TEXT' rows='6' maxlength='254'></textarea>
              </div>
            </div>

          </div>
        </div>
        <div class='modal-footer'>
          <button type='button' class='btn btn-default' data-dismiss='modal'>_{CANCEL}_</button>
          <button type='submit' class='btn btn-primary' id='go'>_{ADD}_</button>
        </div>
      </div><!-- /.modal-content -->
    </form>
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->