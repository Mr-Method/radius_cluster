<form method='POST' action='$SELF_URL'  class='form-horizontal'>
<input type='hidden' name = 'CECKED_MAS_NAME' value='%MAS%'>
<input type='hidden' name = 'CECKED_SUMM_NAME' value='%SUMMNAME%'>
  <input type='hidden' name='module' value='Price' >


<div class='box box-theme box-big-form box-primary'>

  <!-- Box header -->
  <div class='box-header with-border'>

   <h3 class='box-title'>
     <row>
      <div class='col-md-11 col-md-offset-1'><h2><span class='glyphicon glyphicon-credit-card'></span> Оплата</h2></div>
      <div class='col-md-11 col-md-offset-1'><h4>Пакетное сопровождение</h4></div>
    </row>
  </h3>
  <div class='box-tools'>
  <h3><strong>Итог: %SUMM%<span class='glyphicon glyphicon-usd'></span></strong></h3>
  </div>
</div>
<!-- Box header -->

<!-- Box body -->
<div class='box-body table-responsive no-padding'>
      <table class='table table-hover'>
        <tbody>
         %PANEL%
         %SECOND_PANEL%
    </tbody>
    </table>
</div>

<row class='col-md-12'>
<row style='padding: 10em;'>
    <div class='form-group'>

        <row>

          <div class='col-md-2'>
            <label for='Email'>Email</label>
          </div>
          <div class='col-md-4'>
            <input type='email' class='form-control' name='MAIL' id='Email' placeholder='Enter email'>
          </div>
        </row>

  </div>
</row>
</row>
<!-- Box footor -->
<div class='box-footer'>
  <row>
  <div class='col-md-2'>
<button class='btn btn-block btn-primary' type=submit value='Отменить'>Отменить</button>
</div>
  <div class='col-md-2'>
 <button class='btn btn-block btn-primary' type='submit' name='MAIL_SEND'  value='Отправить'>Отправить</button>
</div>
</row>
</div>
</form>


