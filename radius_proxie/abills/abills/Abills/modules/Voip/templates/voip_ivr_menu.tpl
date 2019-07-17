<div class='box box-theme box-form'>
  <div class='box-header'>
    <h4>IVR _{MENU}_</h4>
  </div>
  <div class='box-body'>

        <form action=$SELF_URL method=post class='form-horizontal'>
            <input type=hidden name=index value=$index>
            <input type=hidden name=ID value='%ID%'>

            <fieldset>
                <div class='form-group'>
                    <label class='control-label col-md-3' for='MAIN_ID'>_{MAIN}_:</label>
                    <div class='col-md-9'>
                        %MAIN_ID_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='NUMBER'>_{NUMBER}_:</label>
                    <div class='col-md-9'>
                        <input id='NUMBER' name='NUMBER' value='%NUMBER%' placeholder='%NUMBER%' class='form-control'
                               type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
                    <div class='col-md-9'>
                        <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control'
                               type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
                    <div class='col-md-9'>
                        <input id='COMMENTS' name='COMMENTS' value='%COMMENTS%' placeholder='%COMMENTS%'
                               class='form-control' type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='FUNCTION'>_{FUNCTION}_:</label>
                    <div class='col-md-9'>
                        <input id='FUNCTION' name='FUNCTION' value='%FUNCTION%' placeholder='%FUNCTION%'
                               class='form-control' type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='AUDIO_FILE'>_{AUDIO_FILE}_:</label>
                    <div class='col-md-9'>
                        <input id='AUDIO_FILE' name='AUDIO_FILE' value='%AUDIO_FILE%' placeholder='%AUDIO_FILE%'
                               class='form-control' type='text'>
                    </div>
                </div>


                <div class='form-group'>
                    <label class='control-label col-md-3' for='DISABLE'>_{DISABLE}_:</label>
                    <div class='col-md-9'>
                        <input id='DISABLE' name='DISABLE' value='1' %DISABLE% type='checkbox'>
                    </div>
                </div>

   </div>
   <div class='box-footer'>
    <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
   </div>

  </fieldset>
 </form>
</div>
