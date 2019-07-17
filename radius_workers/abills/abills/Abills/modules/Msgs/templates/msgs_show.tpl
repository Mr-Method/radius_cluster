<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='UID' value='$FORM{UID}'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' name='PARENT' value='%PARENT%'/>
    <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
    <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>

    <div class='row' style='word-wrap: break-word;'>
        <div class='col-md-9' id='reply_wrapper' style='margin-top: 15px;'>
            <div class='box %MAIN_PANEL_COLOR%'>
                <div class='box-header with-border'>
                <div class='row'>
                <div class='col-md-12'>
                    <div class='box-title'><span class='badge %MAIN_PANEL_COLOR%'>%ID%</span> %SUBJECT% %CHANGE_SUBJECT_BUTTON% </div>
                    <div class='box-tools pull-right'>%RATING_ICONS% %PARENT_MSG%</div>
                    </div>

                    </div>
                </div>
                <div class='box-body text-left'>
                        <div class='row'>
                            <div class='col-md-3'><strong>_{STATUS}_:</strong></div>
                            <div class='col-md-3'>%STATE_NAME%</div>

                            <div class='col-md-3'><strong>_{PRIORITY}_:</strong></div>
                            <div class='col-md-3'>%PRIORITY_TEXT%</div>
                        </div>

                        <div class='row'>
                            <div class='col-md-3'><strong>_{CREATED}_:</strong></div>
                            <div class='col-md-3'>%DATE%</div>

                            <div class='col-md-3'><strong>_{CHAPTER}_:</strong></div>
                            <div class='col-md-3'>%CHAPTER_NAME%</div>
                        </div>

                        <div class='row' style="display: %MSG_TAGS_DISPLAY_STATUS%">
                            <div class='col-md-12'>%MSG_TAGS%</div>
                        </div>

                        <!-- progres start -->
                    %PROGRESSBAR%
                        <!-- progres -->
                    </div>

            </div>


            <div class='box box-theme'>
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
            %REPLY_FORM%
            %WORKPLANNING%
        </div>
        <div class='col-md-3' id='ext_wrapper' style='margin-top: 15px;'>
            %EXT_INFO%
        </div>

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
    var dateStr = date.toISOString().slice(0,10) + " " + date.toTimeString().slice(0,9) + "(%ADMIN_LOGIN%)";
    replyText = replyText + "\n\n\nEdited: " + dateStr;
    var replyHtml = replyText.replace(/\</g, "&lt")
                             .replace(/\>/g, "&gt")
                             .replace(/\n/g, "<br />");

    jQuery(element).parent().html(replyHtml);

    console.log(jQuery.post('$SELF_URL', 'header=2&get_index=_msgs_edit_reply&edit_reply=' + replyId + '&replyText=' + replyText ));
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
      
      jQuery(".reply-save").click(function(){
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

  jQuery(function(){
    Events.emit('Msgs.entityViewed.Msg', '%ID%');
    jQuery(".reply-edit-btn").click(function(event){
      event.preventDefault();
      edit_reply(this);
    });
  });
</script>
