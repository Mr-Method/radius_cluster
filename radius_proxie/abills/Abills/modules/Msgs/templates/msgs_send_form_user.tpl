<div class=noprint id=form_msg_add>

    <FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='MsgSendForm' id='MsgSendForm'>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='sid' value='$sid'/>
        <input type='hidden' name='ID' value='%ID%'/>

    <div class='box box-primary'>
        <div class='box-header with-border'><h4 class='box-title'>_{MESSAGE}_</h4></div>
        <div class='box-body form form-horizontal'>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{SUBJECT}_:</label>

                <div class='col-md-9 required'><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'
                   class='form-control' required /></div>
               </div>

               <div class='form-group'>
                <label class='control-label col-md-3'>_{CHAPTERS}_:</label>

                <div class='col-md-9'>%CHAPTER_SEL%</div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{MESSAGE}_</label>

                <div class='col-md-9'>
                    <textarea name='MESSAGE' cols='70' rows='9' class='form-control' required>%MESSAGE%</textarea>
                </div>
            </div>

            <div class='form-group'>
                %ATTACHMENT%
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{ATTACHMENT}_:</label>

                <div class='col-md-9'>
                    <input name='FILE_UPLOAD' type='file' style='margin-top:5px'>
                    <!-- <input class='button' type='submit' name='AttachmentUpload' value='_{ADD}_'> -->
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{STATE}_:</label>

                <div class='col-md-9'>%STATE_SEL%</div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3'>_{PRIORITY}_:</label>

                <div class='col-md-9'>%PRIORITY_SEL%</div>
            </div>
        </div>
        <div class='box-footer text-center'>
            <input type='submit' name='send' value='_{SEND}_' title='Ctrl+C' id='go' class='btn btn-primary'>
        </div>
    </div>


</FORM>

</div>
