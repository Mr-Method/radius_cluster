%BUTTON% %BUTTONS%

<form action=$SELF_URL name='inventory_form' method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=inventory_main value=1>
<input type=hidden name=ID value=$FORM{chg}>

<table>
  <tr>
    <td align=%ALIGN%>_{HOSTNAME}_:</td>
    <td>
   		<input type=text name=HOSTNAME  value='%HOSTNAME%' class='form-control'/>
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>IP:</td>
    <td>
    	<input type=text name=IP value='%IP%' class='form-control'/>
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>_{LOGIN}_:</td>
    <td>
    	<input type=text name=LOGIN value='%LOGIN%' class='form-control'/>
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>_{PASSWD}_:</td>
    <td>
    	<input type=text name=PASSWORD value='%PASSWORD%' class='form-control'/>
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>root _{PASSWD}_:</td>
    <td>
    	<input type=text name=SUPERPASSWORD value='%SUPERPASSWORD%' class='form-control'/>
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>_{INTEGRATION_DATE}_:</td>
    <td>
    	%INTEGRATION_DATE%
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>_{ADMIN_MAIL}_:</td>
    <td>
    	<input type=text name=ADMIN_MAIL value='%ADMIN_MAIL%' class='form-control'/>
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>Benchmark _{INFO}_:</td>
    <td>
    	<input type=text name=BENCHMARK_INFO value='%BENCHMARK_INFO%' class='form-control'/>
    </td>
  </tr>
  <tr>
  <th colspan=2 class='table_title'>Hardware</th>
  </tr>

  %HARDWARE%


  <tr>
  <th colspan=2 class='table_title'>Software</th>
  </tr>

  %SOFTWARE%
<tr>
<td colspan=2>&nbsp;</td>
</tr>

<tr>
<td colspan=2>%DEL_BUTTON%</td>
</tr>
</table>


<input type=submit name=%ACTION% value=%ACTION_LNG% class='btn btn-default'>
</form>