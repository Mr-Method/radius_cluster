<form class='form-horizontal' action='$SELF_URL' METHOD='POST'>
    <fieldset>
        <input type=hidden name='index' value='$index'>
        <input type=hidden name='search_form' value='1'>
        %HIDDEN_FIELDS%
        <div class='col-xs-12 '>
            <div class='box box-theme box-form'>
                <div class='box-header with-border'>_{SEARCH}_</div>

                <div class='box-body'>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='PAGE_ROWS'>_{ROWS}_</label>
                        <div class='col-md-9'>
                            <input id='PAGE_ROWS' name='PAGE_ROWS' value='$PAGE_ROWS' class='form-control' type='text'>
                        </div>
                    </div>
                    %SEARCH_FORM%
                </div>
                <div class='box-footer'><input type=submit name='search' value='_{SEARCH}_' class='btn btn-primary'>
                </div>
            </div>
        </div>
    </fieldset>
</form>
