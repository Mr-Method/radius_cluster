<script language='JavaScript'>
    function autoReload() {
        document.iptv_user_info.add_form.value = '1';
        document.iptv_user_info.TP_ID.value = '';
        document.iptv_user_info.new.value = '$FORM{new}';
        document.iptv_user_info.step.value = '$FORM{step}';
        document.iptv_user_info.submit();
    }
</script>

<form action='$SELF_URL' method=post name='iptv_user_info' class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value='$FORM{chg}'>
    <input type=hidden name=UID value='$FORM{UID}'>
    <input type=hidden name=TP_IDS value='%TP_IDS%'>
    <input type=hidden name='step' value='$FORM{step}'>
    <input type=hidden name='new' value=''>
    <input type=hidden name='add_form' value=''>

    <fieldset>
%NEXT_FEES_WARNING%
        <div class='box box-theme box-form box-big-form'>
            <div class='box-header with-border'><h4 class='box-title'>_{TV}_: %ID%</h4></div>
            <div class='box-body'>
                %MENU%
                %SUBSCRIBE_FORM%
                %SERVICE_FORM%
                <div class='form-group'>
                    <label class='control-label col-md-3' for='TP_NUM'>_{TARIF_PLAN}_:</label>
                    <div class='col-md-9'>
                        %TP_ADD%
                        <div class='input-group' %TP_DISPLAY_NONE%>
                            <span class='hidden-xs input-group-addon bg-primary'>%TP_NUM%</span>
                            <input type=text name='GRP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs'
                                   readonly>
                            <input type=text name='GRP1' value='%TP_ID%:%TP_NAME%' ID='TP'
                                   class='form-control visible-xs'
                                   readonly>
                            <span class='input-group-addon'>%CHANGE_TP_BUTTON%</span>
                        </div>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_:</label>
                    <div class='col-md-9' style='background: %STATUS_COLOR%;'>
                        %STATUS_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='EMAIL'>E-mail:</label>
                    <div class='col-md-9'>
                        <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control'
                               type='text'>
                    </div>
                </div>


                <div class='form-group'>
                    <label class='control-label col-md-3' for='CID'>MAC (Modem):</label>
                    <div class='col-md-9'>
                        <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
                        %SEND_MESSAGE%
                    </div>
                </div>



                    <div class='box box-default box-big-form collapsed-box'>
                        <div class='box-header with-border'>
                            <h3 class='box-title'>_{EXTRA}_</h3>
                            <div class='box-tools pull-right'>
                                <button type='button' class='btn btn-box-tool' data-widget='collapse'><i
                                        class='fa fa-plus'></i>
                                </button>
                            </div>
                        </div>
                        <div class='box-body'>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='FILTER_ID'>Filter-ID:</label>
                                <div class='col-md-9'>
                                    <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                                           class='form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='PIN'>PIN:</label>
                                <div class='col-md-9'>
                                    <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control'
                                           type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='DISABLE'>VoD:</label>
                                <div class='col-md-9'>
                                    <input id='VOD' name='VOD' value='1' %VOD% type='checkbox'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='DVCRYPT_ID'>DvCrypt ID:</label>
                                <div class='col-md-9'>
                                    <input id='DVCRYPT_ID' name='DVCRYPT_ID' value='%DVCRYPT_ID%'
                                           placeholder='%DVCRYPT_ID%' class='form-control' type='text'>
                                </div>
                            </div>

                            %IPTV_MODEMS%

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='IPTV_ACTIVATE'>_{ACTIVATE}_:</label>
                                <div class='col-md-3'>
                                    <input id='IPTV_ACTIVATE' name='IPTV_ACTIVATE' value='%IPTV_ACTIVATE%'
                                           placeholder='%IPTV_ACTIVATE%' class='datepicker form-control' type='text'>
                                </div>
                                <label class='control-label col-md-2' for='IPTV_EXPIRE'>_{EXPIRE}_:</label>
                                <div class='col-md-4'>
                                    <input id='IPTV_EXPIRE' name='IPTV_EXPIRE' value='%IPTV_EXPIRE%'
                                           placeholder='%IPTV_EXPIRE%' class='datepicker form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='ID'>ID:</label>
                                <div class='col-md-3'>
                                    <input value='%ID%' class='form-control' disabled>
                                </div>
                                <label class='control-label col-md-2' for='SERVICE_ID'>_{SERVICE}_:</label>
                                <div class='col-md-4'>
                                    <input value='%SUBSCRIBE_ID%' class='form-control' disabled>
                                </div>

                            </div>


                            <div class='form-group'>
                                %EXTERNAL_INFO%
                            </div>
                        </div>
                    </div>


                <div class='box-footer'>
                    %BACK_BUTTON%
                    <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
                </div>


            </div>

        </div>

    </fieldset>

</form>

