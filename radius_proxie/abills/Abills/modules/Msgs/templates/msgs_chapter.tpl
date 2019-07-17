<FORM action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%ID%'/>

    <div class='box box-primary' style='max-width: 400px;'>
        <div class='box-header with-border'><h4>Раздел</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{NAME}_:</label>

                <div class='col-md-9'>
                    <input class='form-control' type=text name=NAME value='%NAME%' maxlength="21">
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-7'>_{INNER_M}_ _{CHAPTER}_:</label>

                <div class='col-md-5 text-left'>
                    <input type='checkbox' name=INNER_CHAPTER value='1' %INNER_CHAPTER%
                                                       style='margin-top:10px'>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
        </div>
    </div>


</form>
