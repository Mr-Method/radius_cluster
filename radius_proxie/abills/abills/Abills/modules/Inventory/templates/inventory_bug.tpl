<form action='$SELF_URL' name='inventory_form' method=POST>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=$FORM{chg}>

    <div class='box box-theme'>
        <div class='box-header with-border bg-danger'>
            Bug # %ID%
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <div class='col-md-4 bg-success'>%CUR_VERSION%</div>
                <div class='col-md-4 bg-success'>%DATETIME%</div>
                <div class='col-md-4 bg-success'>%IP%</div>
            </div>

            <div class='form-group'>
                <div class='col-md-4'>%FN_INDEX%</div>
                <div class='col-md-4'><b>%FN_NAME%</b></div>
                <div class='col-md-4'>Checksum: %CHECKSUM%</div>
            </div>

            <div class='form-group'>
                <label class='col-md-12 bg-danger'>Error:</label>
                <div class='col-md-6'>
                    <pre>%ERROR%</pre>
                </div>
                <div class='col-md-6'>
                    <pre>%INPUTS%</pre>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-12 bg-info'>Comments</label>
                <div class='col-md-12'><textarea cols='60' rows='5' ID='COMMENTS'
                                                 class='form-control'>%COMMENTS%</textarea></div>
            </div>
            <div class='form-group'>
                <label class='col-md-2 bg-warning'>Fixed version</label>
                <div class='col-md-2'><input type='text' class='form-control' name='FIX_VERSION' value='%FIX_VERSION%'>
                </div>
                <label class='col-md-2 bg-warning'>_{STATUS}_</label>
                <div class='col-md-2'>%STATUS_SEL%</div>
                <label class='col-md-2 bg-warning'>_{RESPONSIBLE}_</label>
                <div class='col-md-2'>%RESPONSIBLE_SEL%</div>
             </div>
        </div>

            </div>
        </div>

        <div class='box-footer'>
            <input type=submit name=change value='_{CHANGE}_' class='btn btn-primary'>
        </div>
    </div>

</form>
