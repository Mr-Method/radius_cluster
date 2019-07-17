<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='chg' value='%ID%'>
    <input type='hidden' name='OLD_SUBJECT' value='%SUBJECT%'>

    <div class='box'>
        <div class='box-header'>_{SUBJECT}_ _{CHANGE}_</div>
        <div class='box-body'>
            <input class='form-control' type='text' name='SUBJECT' value='%SUBJECT%' autofocus>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type='submit' name='CHANGE_SUBJECT' value='_{CHANGE}_'>
        </div>
    </div>
</form>