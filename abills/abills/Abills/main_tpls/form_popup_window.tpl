<script>
  var formURL                 = '?get_index=%CALLBACK_FN_NAME%&header=2';
  var should_open_results_tab = '%OPEN_RESULT%' || false;
</script>
<div id='open_popup_block_middle'>
  <div class='modal-content'>
    <div class='modal-header'>
      <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
        <span aria-hidden="true">&times;</span>
      </button>
      <div class='row text-center'>

          <input type='button' class='btn' data-toggle='dropdown' onclick='enableSearchPill();'
                 value='_{SEARCH}_'/>
          <input type='button' class='btn' data-toggle='dropdown' onclick='enableResultPill();'
                 value='_{RESULT}_'/>

      </div>
    </div>
    <div class='modal-body'>
      <div id='search_pill' class='dropdown-toggle'>%SUB_TEMPLATE%</div>
      <div id='result_pill' class='dropdown-toggle hidden'>%RESULTS%</div>
    </div>
    <div class='modal-footer'>
      <button type='button' class='btn btn-primary' value='SEARCH' id='search'>
        <span class='glyphicon glyphicon-search'></span>_{SEARCH}_</button>
    </div>
  </div>
</div>

