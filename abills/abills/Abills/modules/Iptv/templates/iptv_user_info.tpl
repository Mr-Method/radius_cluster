<div class='box box-theme'>
    <div class='box-body'>

        <div class='form-group'>
            <label class='control-label col-md-6' for='TP_ID'>_{TARIF_PLAN}_:</label>

            <div class='input-group' %TP_DISPLAY_NONE%>
                <span class='hidden-xs input-group-addon bg-primary'>%TP_NUM%</span>
                <input type=text name='GRP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs'
                       readonly>
                <input type=text name='GRP1' value='%TP_ID%:%TP_NAME%' ID='TP' class='form-control visible-xs'
                       readonly>
                <span class='input-group-addon'>%TP_CHANGE_BTN%</span>
            </div>
            </label>
        </div>

        <div class='form-group'>
            <label class='control-label col-md-6' for='DISABLE'>_{STATUS}_:</label>
            <label class='control-label col-md-6' for='TP_ID'>
                %DISABLE% %DISABLE_BTN%
            </label>
        </div>

        <div class='form-group col-md-12'>
            %M3U_LIST%
        </div>

    </div>
</div>
<div class='form-group'>
    %ACTIVE_CODE%
    %WATCH_NOW%
</div>