<link rel='stylesheet' href='/styles/default_adm/css/modules/cablecat/raphael.context-menu.css'>
<link rel='stylesheet' href='/styles/default_adm/css/modules/cablecat/commutation.css'>
<link rel='stylesheet' href='/styles/default_adm/css/modules/cablecat/jquery.contextMenu.min.css'>
<link rel='stylesheet' type='text/css' href='/styles/default_adm/fonts/google-static/Roboto.css'>

%INFO_TABLE%

<div class='row'>
  <div class='col-md-12'>



    <div class='row text-left'>
      <div id='scheme_controls' class='well well-sm'>
        <div class='btn-group' role='toolbar'>

          <!-- ADD MENU -->
          <div class='btn-group'>
            <button type='button' class='btn btn-success dropdown-toggle' data-toggle='dropdown' aria-haspopup='true'
                    aria-expanded='false'>
              <span>_{ADD}_</span>
              <span class='caret'></span>
            </button>
            <ul class='dropdown-menu plus-options' aria-labelledby='dLabel'></ul>
          </div>

          <!-- INFO BUTTON -->
<!--          <button type='button' id='info-btn' role='button' class='btn btn-info' title='_{INFO}_'>
            <span>_{INFO}_</span>
          </button>-->

          <!-- SPECIAL OPERATIONS BUTTON -->
          <div class='btn-group'>
            <button type='button' role='button' class='btn btn-default dropdown-toggle' title='_{EXTRA}_'
                    data-toggle='dropdown' aria-haspopup='true' aria-expanded='false'>
              <span>_{EXTRA}_</span>
              <span class='caret'></span>
            </button>

            <ul class='dropdown-menu advanced-options' aria-labelledby='dLabel'></ul>

          </div>
        </div>

      </div>
    </div>
  </div>

  <div class='col-md-12'>
    <div id='canvas_container' class='table-responsive'>
      <div id='drawCanvas'></div>
    </div>
  </div>
</div>
</div>

<script>

  try {
    document['COMMUTATION_ID'] = '%ID%';
    document['CONNECTER_ID']   = '%CONNECTER_ID%';
    document['WELL_ID']        = '%WELL_ID%';

    document['CABLES'] = JSON.parse('%CABLES%');
    document['LINKS']  = JSON.parse('%LINKS%');

    document['LANG'] = {
      CABLE              : '_{CABLE}_',
      CONNECTER          : '_{CONNECTER}_',
      LINK               : '_{LINK}_',
      CONNECT            : '_{CONNECT}_',
      'CLEAR'            : '_{CLEAR}_',
      'CONNECT BY NUMBER': '_{CONNECT_BY_NUMBER}_',
      'DELETE LINK'      : '_{DELETE_LINK}_',
      'ATTENUATION'      : '_{ATTENUATION}_',
      'COMMENTS'         : '_{COMMENTS}_',
      'REMOVE CABLE FROM SCHEME' : '_{REMOVE_CABLE_FROM_SCHEME}_',
      'GO TO COMMUTATION' : '_{GO_TO_COMMUTATION}_',
      'MAP' : '_{MAP}_',
      'CHANGE' : '_{CHANGE}_'
    }
  }
  catch (Error) {
    alert('Error happened while transfering data to page');
  }

</script>

<script src='/styles/default_adm/js/raphael.min.js'></script>
<script src='/styles/default_adm/js/modules/cablecat/raphael.extensions.js'></script>
<script src='/styles/default_adm/js/modules/cablecat/jquery.ui.position.min.js'></script>
<script src='/styles/default_adm/js/modules/cablecat/jquery.contextMenu.min.js'></script>
<script src='/styles/default_adm/js/modules/cablecat/hammer.min.js'></script>
<script src='/styles/default_adm/js/modules/cablecat/raphael.pan-zoom.js'></script>
<script src='/styles/default_adm/js/modules/cablecat/commutation.js'></script>
