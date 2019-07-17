<style>
  .start-panel {
    display: block;
    padding-left: 3px;
    padding-right: 3px;
  }

  .start-panel > .box:not(.collapsed-box) > div.box-body {
    min-height: 270px;
    max-height: 270px;
  }

  .start-panel-placeholder {
    width: 432px;
    height: 432px;
    background-color: yellow;
  }

  #sortable > div {
    border-top: 1px solid transparent;
  }

  .start-panel .box .box-header {
    cursor: move;
  }
</style>
<form action='$SELF_URL' method='post' id='FORM_QUICK_REPORT_POSITION'>
  <input type='hidden' name='AWEB_OPTIONS' value='1'/>
  <input type='hidden' name='QUICK' value='1'/>
</form>
<div class="row">
  <div id='sortable'>
    %INFO%
  </div>
</div>
<script>

  jQuery(function () {
    var sortable_wrapper = jQuery("#sortable");

    /*sortable box*/
    sortable_wrapper.sortable(
        {
          cancel: ".box-body",
          scroll: true,
          helper: "clone",
          cursor: "move"
        }
    );

    /* Save order after moving panels */
    sortable_wrapper.on("sortupdate", function (event, ui) {
      var formData = '';

      // Collect panels order
      jQuery(".start-panel").map(function (indx, element) {
        formData += '&QUICK_REPORTS_SORT=' + jQuery(element).attr('id');
      });

      formData += "&AWEB_OPTIONS=1&QUICK=1";

      /* Send Data */
      jQuery.post('/admin/index.cgi', formData, function (data) {
      });
    });

  });

</script>
