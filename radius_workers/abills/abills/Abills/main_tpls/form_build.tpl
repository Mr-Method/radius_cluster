<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='BUILDS' value='$FORM{BUILDS}'/>

  <div class="row">
    <div class='col-md-6'>
      <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4 class='box-title'>_{ADDRESS_BUILD}_</h4></div>
        <div class='box-body'>

          <div class='form-group'>
            <label class='control-label col-md-3' for='NUMBER'>_{NUM}_:</label>
            <div class='col-md-9'>
              <input id='NUMBER' name='NUMBER' value='%NUMBER%' placeholder='%NUMBER%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='BLOCK'>_{BLOCK}_:</label>
            <div class='col-md-9'>
              <input id='BLOCK' name='BLOCK' value='%BLOCK%' placeholder='%BLOCK%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='STREET_SEL'>_{ADDRESS_STREET}_:</label>
            <div class='col-md-9'>
              %STREET_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='ENTRANCES'>_{ENTRANCES}_:</label>
            <div class='col-md-9'>
              <input id='ENTRANCES' name='ENTRANCES' value='%ENTRANCES%' placeholder='%ENTRANCES%' class='form-control'
                     type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='FLORS'>_{FLORS}_:</label>
            <div class='col-md-9'>
              <input id='FLORS' name='FLORS' value='%FLORS%' placeholder='%FLORS%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='FLATS'>_{FLATS}_:</label>
            <div class='col-md-9'>
              <input id='FLATS' name='FLATS' value='%FLATS%' placeholder='%FLATS%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='BUILD_SCHEMA'>_{BUILD_SCHEMA}_:</label>
            <div class='col-md-9'>
              <textarea id='BUILD_SCHEMA' name='BUILD_SCHEMA' placeholder='%BUILD_SCHEMA%' class='form-control' rows="2">%BUILD_SCHEMA%</textarea>
            </div>
          </div>

          <div class='form-group'>
            
            <label class='control-label col-md-6' for='NUMBERING_DIRECTION'>_{NUMERATION_ROOMS}_:</label>
            <div class='col-md-6'>
              <div class="checkbox">
              <input name="NUMBERING_DIRECTION" %NUMBERING_DIRECTION_CHECK% id='NUMBERING_DIRECTION' value="1" type="checkbox">
              </div>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-6' for='CONNECT'>_{PLANNED_TO_CONNECT}_:</label>
            <div class='col-md-6'>
              <div class="checkbox">
              <input name="PLANNED_TO_CONNECT" %PLANNED_TO_CONNECT_CHECK% id='CONNECT' value="1" type="checkbox">
              </div>
            </div>
          </div>


        </div>
      </div>
    </div>

    <div class='col-md-6'>

      <div class='box box-theme box-form'>

        <div class='box-header with-border'>
          <h3 class='box-title'>_{EXTRA}_</h3>
          <div class='box-tools pull-right'>
            <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>

        <div id='builds_misc' class='box-collapse box-body collapse out'>

          <div class='form-group'>
            <label class='control-label col-md-3' for='CONTRACT_ID'>_{CONTRACT}_:</label>
            <div class='col-md-9'>
              <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' placeholder='%CONTRACT_ID%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='CONTRACT_DATE'>_{CONTRACT}_ _{DATE}_:</label>
            <div class='col-md-9'>
              <input id='CONTRACT_DATE' name='CONTRACT_DATE' value='%CONTRACT_DATE%' placeholder='%CONTRACT_DATE%'
                     class='form-control datepicker' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='CONTRACT_PRICE'>_{PRICE}_:</label>
            <div class='col-md-9'>
              <input id='CONTRACT_PRICE' name='CONTRACT_PRICE' value='%CONTRACT_PRICE%' placeholder='%CONTRACT_PRICE%'
                     class='form-control' type='text'>
            </div>
          </div>

          <hr>

          <div class='form-group'>
            <label class='control-label col-md-3' for='ZIP'>_{ZIP}_:</label>
            <div class='col-md-9'>
              <input id='ZIP' name='ZIP' value='%ZIP%' placeholder='%ZIP%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
            <div class='col-md-9'>
              <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='PUBLIC_COMMENTS'>_{PUBLIC_COMMENTS}_:</label>
            <div class='col-md-9'>
                <textarea class='form-control' id='PUBLIC_COMMENTS' name='PUBLIC_COMMENTS'
                          rows='3'>%PUBLIC_COMMENTS%</textarea>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='ADDED'>_{ADDED}_:</label>
            <div class='col-md-9'>
              %ADDED%
            </div>
          </div>

          <div class='form-group' data-visible='%MAP_BLOCK_VISIBLE%'>
            <hr/>
            <label class='control-label col-md-3'>_{MAP}_:</label>
            <div class='col-md-9'>
              %MAP_BTN%
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>
  <div class='box-footer'>
    <div class='col-md-12'>
      <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>


</form>
