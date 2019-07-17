<form method='POST' action='$SELF_URL'  class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='%ID%' >
<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4>Добавить услугу</h4></div>
  <div class='box-body'>
    
        <form name='Add_services' id='form_Add_services' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index' />
 <fieldset>
      <div class='form-group'>
          <label class='control-label col-md-3' >Название</label>
          <div class='col-md-9'>
              <input type='text' class='form-control'  name='NAME'  value='%NAME%'  />
          </div>
      </div>

      <div class='form-group'>
          <label class='control-label col-md-3' >Цена</label>
          <div class='col-md-9'>
              <input type='text' class='form-control'  name='PRICE'  value='%PRICE%' />
          </div>
      </div>

      <div class='form-group'>
          <label class='control-label col-md-3' >Описание</label>
          <div class='col-md-9'>
              <textarea class='form-control'  rows='5'  name='COMMENTS'  >%COMMENTS%</textarea>
          </div>
      </div>
    </form>
</fieldset>
  </div>
  <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
  </div>
</div>
</form>
