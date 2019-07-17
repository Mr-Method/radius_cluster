<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value=$index>

  <div class='box box-primary form-horizontal'>
    <div class='box-body'>
      <row>
        <div class='col-md-3'>
         %DATE%
       </div>
       <div class='col-md-4'>
        <div class='form-group'>
          <div class='col-md-12'>
            <div class="checkbox">
              <label>
                <input type="checkbox" name="disable" ;>
                _{SHOW}_ _{DISABLED}_
              </label>
              </div>
            </div>
          </div>
        </div>
        <div class='col-md-5'>
          <input type='submit' class='btn btn-primary' value='_{ACCEPT}_' name='_{ACCEPT}_'>
        </div>
      </row>
    </div>

  </div>

</form>