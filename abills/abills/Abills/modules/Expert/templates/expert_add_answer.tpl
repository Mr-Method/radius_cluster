<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='ID' value='%PARRENT_ID%'>
    <input type='hidden' name='ANSWER_ID' value='%ANSWER_ID%'>
  
    <div class='box'>
        <div class='box-header'>_{ADD}_</div>
        <div class='box-body'>
            <b>Номер вопроса: </b><input class='form-control' type='text' name='PARRENT_ID' value='%PARRENT_ID%'>
            <b>Вариант ответа: </b><input class='form-control' type='text' name='ANSWER' value='%ANSWER%' autofocus>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type='submit' name='%BUTTON_NAME%' value='%BUTTON_VALUE%'>
        </div>
    </div>
</form>
