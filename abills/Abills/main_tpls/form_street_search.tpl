<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<table border=1 width=300>
<TR><TH class='form_title' colspan='2'>_{STREETS}_ _{SEARCH}_</TH></TR>
<tr><td>_{ADDRESS_STREET}_:</td><td>%STREET_SEL%</td></tr>
<tr><td>_{SEARCH}_:</td><td><input type=text name=index name='NAME' value='%NAME%'></td></tr>
<tr><th colspan=2>_{BUILDS}_</th></tr>
<tr><td colspan=2>%BUILDS%</td></tr>
<tr><th colspan=2><input type=submit name=search value='_{SEARCH}_'></th></tr>
</table>
</form>