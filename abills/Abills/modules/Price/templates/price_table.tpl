<form method='POST' action='$SELF_URL'  >
  <input type='hidden' name='ID' value='1' >
  <input type='hidden' name='module' value='Price' >

  <section class='content'>
   <row class='col-md-12'>
    <div class='box box-theme box-primary'>
      <div class='box-header with-border'>
       <h3 class='box-title'>
         <div class='row'>
          <div class='col-md-11 col-md-offset-1'><h2><span class='fa fa-fw fa-wrench'></span> Подержка</h2></div>
          <div class='col-md-11 col-md-offset-1'><h4>Пакетное сопровождение</h4></div>
        </div>

      </h3>
    </div>
    <!-- Box header -->

    <div class='box-body table-responsive no-padding'>
      <table class='table table-hover'>
        <tbody>

          %PANEL%

        </tbody>
      </table>

      <row class='col-md-12'>
        <row style="padding-top: 10em;">
          <div class='col-md-7 col-md-offset-1'>
            <strong>За каждых дополнительных 500 абонентов доплата 100 <span class='glyphicon glyphicon-usd'></span></strong>
          </div>
          <div class='col-md-3'>
            <div class='input-group'>
              <input type='number' name='SUMM' required class='form-control' placeholder='0' value='%CLIENT%'>
              <span class='input-group-addon'><strong><span class='glyphicon glyphicon-user'></span></strong></span>
            </div>
          </div>
        </row>
      </row>



    </div>
    <!-- Box footor -->
    <div class='box-footer'>

      <div class='col-md-2'>
        <button class='btn btn-block btn-primary' type=submit name='ACCEPT' value='Подтвердить'>Подтвердить<span class='glyphicon glyphicon-ok'></button>
      </div>
      <div class='col-md-2 '>
        <button class='btn btn-block btn-primary' type=submit name='NORES' value='Итог:'>Итог: %SUMM%<span class='glyphicon glyphicon-usd'></button>
      </div>
      <div class='col-md-2'>
        <button class='btn btn-block btn-primary' type=submit name='RES'  value='Сбросить'>Сбросить<span class='glyphicon glyphicon-refresh'></button>
      </div>



    </div>

  </div>
</row>
</section>
</form>