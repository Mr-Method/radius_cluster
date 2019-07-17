<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='UID' value='$FORM{UID}'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' name='PARENT' value='%PARENT%'/>
    <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
    <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>

    <div class='panel with-nav-tabs panel-default'>
        <div class='panel-heading'>
                <ul class='nav nav-tabs'>
                    <li class='%TAB1_ACTIVE%'><a href='#tab1default' data-toggle='tab'>_{MESSAGE}_</a></li>
                    <li class='%TAB2_ACTIVE%'><a href='#tab2default' data-toggle='tab'>_{REPLYS}_</a></li>
                    <li class='%TAB3_ACTIVE%'><a href='#tab3default' data-toggle='tab'>_{MANAGE}_</a></li>
                </ul>
        </div>
        <div class='panel-body'>
            <div class='tab-content'>

                <div class='tab-pane %TAB1_ACTIVE%' id='tab1default'>
                    <div class='box %MAIN_PANEL_COLOR%'>
                        <div class='box-header with-border'>
                        <div class='row'>
                        <div class='col-md-9'>
                            <div class='box-title'> <span class='badge %MAIN_PANEL_COLOR%'>%ID%</span> %SUBJECT% %CHANGE_SUBJECT_BUTTON%</div>
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

                                <div class='row' style='display: %MSG_TAGS_DISPLAY_STATUS%'>
                                    <div class='col-md-3'><strong>_{TAGS}_:</strong></div>
                                    <div class='col-md-9'>%MSG_TAGS%</div>
                                </div>

                                <!-- progres start -->
                            %PROGRESSBAR%

                                <!-- progres -->
                            </div>
                        
                    </div>
                    %WORKPLANNING%

                </div>
                

                <div class='tab-pane %TAB2_ACTIVE%' id='tab2default'>
                    <div class='box box-theme'>
                      <div class='box-header with-border'><h4 class='text-left'>%SUBJECT%</h4></div>
                        <div class='box-body'>
                          <div class='row'>
                            <div class='col-md-12'>
                              <ul class='timeline'>
                                <li>
                                  <i class='fa fa-user %COLOR%'></i>
                                  <div class='timeline-item text-left'>
                                    <span class='time'>%DATE%</span>
                                    <h3 class='timeline-header'>%LOGIN%</h3>
                                    <div class='timeline-body'>%MESSAGE%</div>
                                    %ATTACHMENT%
                                  </div>
                                </li>
                                %REPLY%
                              </ul>
                            </div>
                          </div>
                        </div>
                    </div>

                    %REPLY_FORM%

                </div>
                    


                <div class='tab-pane %TAB3_ACTIVE%' id='tab3default'>
                    
                    %EXT_INFO%

                </div>
            </div>
        </div>
    </div>

    <!-- end of table -->
</form>

