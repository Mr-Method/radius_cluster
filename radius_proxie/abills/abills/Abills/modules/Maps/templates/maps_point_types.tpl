<style>
  #ICON_SELECT, #ICON_SELECT_chosen, #ICON_SELECT_chosen > .chosen-single {
    min-height: 60px;
  }

  #ADD_ICON_BUTTON {
    margin-top: 35%;
  }
</style>

<div class='box box-theme box-form'>
  <div class='box-header with-border text-center'>
    <h4>_{OBJECT}_ _{TYPE}_</h4>
  </div>
  <div class='box-body'>
    <form name='MAPS_POINT_TYPES_FORM' id='form_MAPS_POINT_TYPES_FORM' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='ICON_SELECT'>_{ICON}_</label>
        <div class="col-md-9">
          <div class='col-md-10'>
            %ICON_SELECT%
          </div>
          <div class="col-md-2">
            %ADD_ICON_BUTTON%
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_MAPS_POINT_TYPES_FORM' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

<script>

  /** Anykey : pictures inside select **/

  var BASE_DIR = '%MAPS_ICONS_WEB_DIR%';

  var select  = jQuery('#ICON_SELECT');
  var options = select.find('option');

  jQuery.each(options, function (i, option) {
    var _opt = jQuery(option);

    var icon_name = _opt.text();

    var icon_src = BASE_DIR + icon_name;

    var img = document.createElement('img');
    img.src = icon_src;
    jQuery(img).addClass('img-responsive img-thumbnail');

    var strong = document.createElement('strong');
    jQuery(strong).addClass('text-left col-md-6');
    strong.innerText = icon_name;

    _opt.addClass('text-center');
    _opt.html(strong.outerHTML + img.outerHTML);
  });

  updateChosen();

</script>