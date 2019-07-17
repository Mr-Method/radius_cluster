<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='UID' value='$FORM{UID}'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' name='PARENT' value='%PARENT%'/>
    <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
    <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>


    <div style='word-wrap: break-word;'>
        <div class='box box-theme %MAIN_PANEL_COLOR%'>
            <div class='box-header with-border'>
                <div class='box-title'>%SUBJECT% </div>
            </div>
            <div class='box-body'>
                <div class='table'>
                <div class='row'>
                    <div class='col-md-3 text-left'><strong>#:</strong></div>
                    <div class='col-md-3 text-left'><span class='badge'>%ID%</span></div>

                    <div class='col-md-3 text-left'><strong>_{CHAPTERS}_:</strong></div>
                    <div class='col-md-3 text-left'>%CHAPTER_NAME%</div>
                </div>

                <div class='row'>
                    <div class='col-md-3 text-left'><strong>_{STATUS}_:</strong></div>
                    <div class='col-md-3 text-left'>%STATE_NAME%</div>

                    <div class='col-md-3 text-left'><strong>_{PRIORITY}_:</strong></div>
                    <div class='col-md-3 text-left'>%PRIORITY_TEXT%</div>
                </div>

                <div class='row'>
                    <div class='col-md-3 text-left'><strong>_{CREATED}_:</strong></div>
                    <div class='col-md-3 text-left'>%DATE%</div>

                    <div class='col-md-3 text-left'><strong>_{UPDATED}_:</strong></div>
                    <div class='col-md-3 text-left'>%UPDATED%</div>
                </div>
                </div>
                <!-- progres start -->
                %PROGRESSBAR%
                <!-- progres -->
            </div>
        </div>

        <div class='box box-primary'>
            <div class='box-header with-border'>
                <h5 class='box-title'>%LOGIN% _{ADDED}_: %DATE%</h5>
            </div>
            <div class='box-body' style='text-align: left'>
                %MESSAGE%
                <div class='pull-right'>%QUOTING% %DELETE%</div>
            </div>
            <div class='box-footer'>%RUN_TIME% %ATTACHMENT%</div>
        </div>

        %REPLY%
    </div>

    <!-- end of table -->
</form>

<script>
  var saveStr = '_{SAVE}_';
  var cancelStr = '_{CANCEL}_';
  var replyId = 0;

  function save_reply(element) {
    var replyText = jQuery('.reply-edit').val();
    var date = new Date();
    var dateStr = date.toISOString().slice(0,10) + " " + date.toTimeString().slice(0,9) + "(%LOGIN%)";
    replyText = replyText + "\n\n\nEdited: " + dateStr;
    var replyHtml = replyText.replace(/\</g, "&lt")
                             .replace(/\>/g, "&gt")
                             .replace(/\n/g, "<br />");

    jQuery(element).parent().html(replyHtml);
  }

  function edit_reply(element) {
    if (replyId==0) {
      replyId = jQuery(element).attr('reply_id');
      var replyElement = jQuery(element).closest(".box").find(".box-body");
      var oldReplyHtml = replyElement[0].innerHTML;
      var oldReply = replyElement[0].innerText;
      replyElement.html("")
        .append("<textarea class='form-control reply-edit' rows='10' style='width:100%; margin-left:auto;margin-right:auto'>" + oldReply + "</textarea>")
        .append("<button type='button' class='btn btn-default btn-xs reply-save'>" + saveStr + "</button>")
        .append("<button type='button' class='btn btn-default btn-xs reply-cancel'>" + cancelStr + "</button>");
      replyElement.children().first().focus();
      
      jQuery(".reply-save").click(function(event){
        event.preventDefault();
        save_reply(this);
        replyId = 0;
      });

      jQuery(".reply-cancel").click(function(event){
        event.preventDefault();
        jQuery(this).parent().html(oldReplyHtml);
        replyId = 0;
      });
    }
  };

  jQuery(function(event){
    jQuery(".reply-edit-btn").click(function(event){
      event.preventDefault();
      edit_reply(this);
    });
  });
</script>


