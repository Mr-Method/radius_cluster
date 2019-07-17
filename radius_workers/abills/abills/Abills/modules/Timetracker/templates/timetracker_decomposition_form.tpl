<!-- %RESULT%
<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>Декомпозиция</h4></div>
  <div class='box-body'>
        <form name='DECOMPOSTION' id='form_DECOMPOSTION' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1' />

        %CHECKBOXES%
    </form>

  </div>
  <div class='box-footer text-center'>
      <input type='submit' form='form_DECOMPOSTION' class='btn btn-primary' name='submit' value='Результат'>
  </div>
</div> -->

<style type="text/css">
  .material-switch > input[type="checkbox"] {
    display: none;   
}

.material-switch > label {
    cursor: pointer;
    height: 0px;
    position: relative; 
    width: 40px;  
}

.material-switch > label::before {
    background: rgb(0, 0, 0);
    box-shadow: inset 0px 0px 10px rgba(0, 0, 0, 0.5);
    border-radius: 8px;
    content: '';
    height: 16px;
    margin-top: -8px;
    position:absolute;
    right: 0px;
    opacity: 0.3;
    transition: all 0.4s ease-in-out;
    width: 40px;
}
.material-switch > label::after {
    background: rgb(255, 255, 255);
    border-radius: 16px;
    box-shadow: 0px 0px 5px rgba(0, 0, 0, 0.3);
    content: '';
    height: 24px;
    left: -4px;
    margin-top: -8px;
    position: absolute;
    top: -4px;
    transition: all 0.3s ease-in-out;
    width: 24px;
}
.material-switch > input[type="checkbox"]:checked + label::before {
    background: inherit;
    opacity: 0.5;
}
.material-switch > input[type="checkbox"]:checked + label::after {
    background: inherit;
    left: 20px;
}
</style>


<div class="container">
    <div class="row">
        <div class="col-xs-12 col-sm-6 col-md-4 col-sm-offset-3 col-md-offset-4">
        <form name='DECOMPOSTION' id='form_DECOMPOSTION' method='post' class='form form-horizontal'>    
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='submit' value='1' /> 
            <div class="panel panel-default">
                <!-- Default panel contents -->
                <div class="panel-heading">_{IT_DECOMPOSITION}_</div>
            
                <!-- List group -->
                <ul class="list-group"> 
                    %CHECKBOXES%        
                </ul>

            </div>    
                <button type="submit" form='form_DECOMPOSTION' class="btn btn-primary btn-md btn-block" name='submit'>_{RESULT}_</button>   
            </form>            
        </div>
    </div>
</div>







