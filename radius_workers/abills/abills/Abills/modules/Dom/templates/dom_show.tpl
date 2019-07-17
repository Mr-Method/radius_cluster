<script src='/styles/default_adm/js/raphael.min.js'></script>
<script src='/styles/default_adm/js/build_construct.js'></script>


<style type='text/css'>
   #tip {
    position: fixed;
    color: white;
    border: 1px solid gray;
    border-bottom: none;
    background-color: #7AB932;
    padding: 3px;
    z-index: 1000;
    /* set this to create word wrap */
    max-width: 200px;
  }

</style>

<form method='post' class='form form-horizontal'>
  <div class='box  box-theme no-padding'>
    <div class='box-body no-padding' id='body'>
      <div class='info-box-content' style='margin-left:5px'>
        <span class='info-box-number'>%DISTRICT_NAME% %STREET_NAME% %BUILD_NAME%</span>

        <div class='col-md-12'>
          <p>_{ENTRANCES}_: %BUILD_ENTRANCES%</p>
          <p>_{FLORS}_: %BUILD_FLORS%</p>
          <p>_{MAP}_ _{FLATS}_: %CLIENTS_FLATS_SUM%/%BUILD_FLATS% </p>
        </div>

        <!--         <div class='col-md-6'>
                  <p>_{FLATS}_: %BUILD_FLATS%</p>
                  <p>_{USER_FLAT_NUM_NO_CORRECT}_: %USER_SUM_WITH_NO_ROOM%
                    <span>
                       <a title='_{SHOW}_' id='no_correct_flat' href=''>_{SHOW}_</a>
                     </span>
                  </p>
                </div> -->

        <div class='col-md-12'>
          <div class='progress '>
            <div class='progress-bar'><span class='badge bg-light-blue-active color-palette'>%PERCENTAGE% %</span>
            </div>
          </div>
        </div>
      </div>
      <!-- Canvas -->
      <div class='col-sm-12' id='scroll_canvas_container' style='padding: 0px'>
        <div id='canvas_container' style='overflow: scroll; width: 100%; padding: 0px'>
          <div id='tip' style='display: none'></div>
          <div >
            <p>
              <strong><i class="fa fa-list margin-r-5"></i>_{DESCRIBE}_</strong>
              <span class="label label-success">_{ENABLE}_</span>
              <span class="label label-danger">_{NEGATIVE}_ _{DEPOSIT}_</span>
              <span class="label label-warning">_{CREDIT}_</span>
              <span class="label" style="background-color: #747372">_{DISABLED}_</span>
            </p>
          </div>
          %TABLE_NAS%
        </div>
      </div>

    </div>
  </div>


</form>

<script type='application/javascript'>
  jQuery(document).ready(function () {

    jQuery('.progress-bar').width('%PERCENTAGE%' + '%');
    jQuery('#no_correct_flat').attr('href', '%SHOW_USERS%');

    var canvas_height = jQuery(window).height() * 0.8;

    jQuery('#canvas_container').height(canvas_height);

    build_construct(
      '%BUILD_FLORS%',
      '%BUILD_ENTRANCES%',
      '%FLORS_ROOMS%',
      'canvas_container',
      '%USER_INFO%',
      '%LANG_PACK%',
      'canvas_height',
      '%BUILD_FLATS%',
      '%BUILD_SCHEMA%',
      '%NUMBERING_DIRECTION%'
    );

  })
</script>


