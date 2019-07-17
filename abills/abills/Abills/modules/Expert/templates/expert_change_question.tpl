<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='ID' value='%ID%'>
  
    <div class='box'>
        <div class='box-header'>_{CHANGE}_</div>
        <div class='box-body'>
            <b>Вопрос: </b><input class='form-control' type='text' name='QUESTION' value='%QUESTION%'>
            <b>Описание: </b><input class='form-control' type='text' name='DESCRIPTION' value='%DESCRIPTION%'>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type='submit' name='%BUTTON_NAME%' value='%BUTTON_VALUE%'>
        </div>
    </div>
</form>
