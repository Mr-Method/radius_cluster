<form action=$SELF_URL name=multi_create>
<input type=hidden name=index value=$index>
<input type=hidden name=INCLUDE_BALANCE value=1>

%USERS_TABLE%

<table class=form>
    <tr>
        <td>_{DATE}_:</td>
        <td>%DATE%</td>
    </tr>
    <tr>
        <td>_{ORDER}_:</td>
        <td><input size=30 type=text name=ORDER value=%ORDER%></td>
    </tr>
    <tr>
        <td>_{SUM}_:</td>
        <td><input type=text name=SUM value='%SUM%' size=5></td>
    </tr>
    <tr>
        <td>_{SEND}_ E-mail:</td>
        <td><input type=checkbox name=SEND_EMAIL value='1' checked></td>
    </tr>
    <tr>
        <th colspan=2><input type=submit name=create value='_{CREATE}_' class='btn btn-primary'></th>
    </tr>
</table>
</form>
