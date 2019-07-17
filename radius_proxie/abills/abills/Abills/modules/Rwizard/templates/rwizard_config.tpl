<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data' id='CARDS_ADD'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>

<div class='box box-primary form-horizontal'>
    <div class='box-header with-border'>Reports Wizard</div>
    <div class='box-body'>

        <div class='form-group'>
            <label class='control-element col-md-6'>_{NAME}_</label>
            <label class='control-element col-md-6'>_{GROUP}_</label>
            <div class='col-md-6'>
                <input type=text name=NAME value='%NAME%' class='form-control'>
            </div>
            <div class='col-md-6'>
                %GROUP_SEL%
            </div>
        </div>

        <div class='form-group'>
            <label class='control-element col-md-6'>_{QUERY}_: _{MAIN}_</label>
            <label class='control-element col-md-6'>_{QUERY}_: _{TOTAL}_</label>
            <div class='col-md-6'>
                <textarea class='form-control' name=QUERY rows=12 cols=75>%QUERY%</textarea>
            </div>
            <div class='col-md-6'>
                <textarea class='form-control' name=QUERY_TOTAL rows=12 cols=75>%QUERY_TOTAL%</textarea>
            </div>
        </div>

        <div class='form-group'>
            <div class='col-md-6'>
                <label class='control-element col-md-12'>_{FIELDS}_ (_{FIELD}_:_{NAME}_:CHART[LINE]:FILTER)</label>
                <div class='col-md-12'>
                    <textarea class='form-control' name=FIELDS rows=12 cols=75>%FIELDS%</textarea>
                </div>
            </div>
            <div class='col-md-6'>
                <label class='control-element col-md-12'>_{COMMENTS}_</label>
                <div class='col-md-12'>
                    <textarea class='form-control' name=COMMENTS rows=3 cols=75>%COMMENTS%</textarea>
                </div>
                <label class='control-element col-md-12'>_{IMPORT}_</label>
                <div class='col-md-12'>
                    <input name=IMPORT id='IMPORT' type='file'>
                </div>
                <div class='col-md-12'>
                    <div class="checkbox">
                        <label><input type="checkbox" name=QUICK_REPORT value="1" %QUICK_CHECKED%>_{QUICK_REPORT}_</label>
                    </div>
                </div>
            </div>
        </div>

    </div>
    <div class='box-footer'>
        <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
</div>

</FORM>