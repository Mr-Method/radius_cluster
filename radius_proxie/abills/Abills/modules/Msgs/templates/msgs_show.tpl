<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='UID' value='$FORM{UID}'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' name='PARENT' value='%PARENT%'/>
    <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
    <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>

    <div class='row'>
        <div class='col-md-9' id='reply_wrapper' style='margin-top: 15px;'>
            <div class='box %MAIN_PANEL_COLOR%'>
                <div class='box-header with-border'>
                <div class='row'>
                <div class='col-md-9'>
                    <div class='box-title'> %SUBJECT%</div>
                    </div>

                    <div class='col-md-3 pull-right'>%RATING_ICONS%</div>
                    </div>
                </div>
                <div class='box-body text-left'>
                        <div class='row'>
                            <div class='col-md-3'><strong>#:</strong></div>
                            <div class='col-md-3'><span class='badge %MAIN_PANEL_COLOR%'>%ID%</span></div>

                            <div class='col-md-3'><strong>_{CHAPTERS}_:</strong></div>
                            <div class='col-md-3'>%CHAPTER_NAME%</div>
                        </div>

                        <div class='row'>
                            <div class='col-md-3'><strong>_{STATUS}_:</strong></div>
                            <div class='col-md-3'>%STATE_NAME%</div>

                            <div class='col-md-3'><strong>_{PRIORITY}_:</strong></div>
                            <div class='col-md-3'>%PRIORITY_TEXT%</div>
                        </div>

                        <div class='row'>
                            <div class='col-md-3'><strong>_{CREATED}_:</strong></div>
                            <div class='col-md-3'>%DATE%</div>

                            <div class='col-md-3'><strong>_{UPDATED}_:</strong></div>
                            <div class='col-md-3'>%UPDATED%</div>
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
        </div>
        <div class='col-md-3' id='ext_wrapper' style='margin-top: 15px;'>
            %EXT_INFO%
        </div>

    </div>
    <!-- end of table -->
</form>

