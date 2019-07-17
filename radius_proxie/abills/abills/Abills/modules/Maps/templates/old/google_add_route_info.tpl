<form action=$SELF_URL ID=mapForm name=adress class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=COORDX value=%COORDX%>
    <input type=hidden name=COORDY value=%COORDY%>

    <div class='box box-theme'>
        <div class='box-body'>
            <div class='form-group'>
                %ROUTE_ID%
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' name=add_route_info value=_{ADD}_ class='btn btn-default'>
        </div>
    </div>


</form>

