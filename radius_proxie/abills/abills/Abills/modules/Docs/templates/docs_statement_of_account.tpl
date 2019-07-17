<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <title>Выписка по счету</title>
  <link href='/styles/default_adm/css/bootstrap.min.css' rel='stylesheet'>
</head>
<script language='JavaScript'>
    function autoReload() {
        document.docs_statment_account.submit();
    }
</script>
<body>
<div class='container'>
    <div class='row hidden-print'>
        <form action='$SELF_URL' name='docs_statment_account' class='form-inline'>
          <input type=hidden name='qindex' value=15>
          <input type=hidden name='STATMENT_ACCOUNT' value=1>
          <input type=hidden name='UID' value=%UID%>
          <input type=hidden name='header' value='2'>
          %YEAR_SEL%
          <a href='javascript:window.print();' class='btn btn-default'>_{PRINT}_</a>
        </form>

    </div>
  <div class='row'>
 	<div class='col-xs-12 text-left'>
    <h3>%COMPANY_NAME% </h3>  
    <div class='col-xs-6 pull-left'>
      
<div class='col-xs-6 text-right'>
    <b>Почтовый адрес:</b>      <br>
    <b>Адрес:</b>         <br>
     <br>
  </div>

<div class='col-xs-6 text-left'>
    <u>%ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT% </u>    <br>
    <u>%ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT%</u>     <br>
    %DISTRICT%, %CITY%, %ZIP%   <br>
  </div>



     </div>
  <div class='col-xs-6 pull-right'>
            
<div class='col-xs-6 text-right'>
    <b>Телефон:</b>      <br>
    <b>Факс:</b>         <br>
    <b>Электронная почта:</b>  <br>
  </div>

<div class='col-xs-6 text-left'>
    %PHONE%      <br>
    %_fax%         <br>
    %EMAIL%  <br>
  </div>

</div>

<div class='col-xs-12 text-center'>
  <h4>Выписка</h4>
</div>

<div class='col-xs-6 pull-left'>
	<div class='col-xs-6 text-right'>
  	<br>
	  <b>Номер выписки:</b>	  <br>	
	  <b>Дата:</b> 	 <br>     
    <b>Код клиента: </b>	
    <br>
  </div>
  <div class='col-xs-6 text-left'>
	  <br>%UID%_%DATE%<br>
 	  <b>%DATE%  </b><br> 
  	<b>%UID%</b> 
  	<br>
  </div>
        
</div>


<div class='col-xs-6 pull-right'>
	<div class='col-xs-6 text-right'>
<br>
	  <b>Плательщик:</b> 	
	  <br>  
	  
    
         
    
  </div>
  <div class='col-xs-6 text-left'>
    <br>      %FIO% <br>	
	  %COMPANY_NAME%<br>  
	  %ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT%  <br>
    
    %DISTRICT%, %CITY%, %ZIP% <br>     
    
  </div>
</div>
</div> <!-- /row -->
        
<br>
<br>
<br>
<br>

<div class='row TWhead'> </div>
<div class='col-xs-12'>
<table class='table'>
  <thead>
    <tr>
      <th><small>Дата </small></th>
      <th><small>Тип</small></th>
      <th><small>Номер счета</small></th>
      <th><small>Описание</small></th>
      <th><small>Списание</small></th>
      <th><small>Платеж</small></th>
      <th><small>Баланс</small></th>              
    </tr>
  </thead>
  <tbody>
    %ROWS%          
  </tbody> 
</table> 

<H4>_{DEPOSIT}_: %DEPOSIT% </H4>



</div> 
</div> <!-- /container -->

</body>
</html>
