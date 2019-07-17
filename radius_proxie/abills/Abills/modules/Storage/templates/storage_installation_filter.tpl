<form action=$SELF_URL name=\"storage_filter_installation\" method=POST>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=%ID%>

    <fieldset>
        <div class='box box-theme box-form'>
            <div class='box-body form form-horizontal'>
                <legend>_{SEARCH}_</legend>
                <div class='form-group'>
                    <label class='col-md-3 control-label'>_{ADMIN}_: </label>
                    <div class='col-md-9'>%AID%</div>
                </div>
                %ADDRESS_FORM%
            </div>
            <div class='box-footer'>
                <input class='btn btn-primary' type=submit name=show_installation value=_{SHOW}_>
            </div>
        </div>
    </fieldset>
</form>