<div class='row'>
  <section id='left-column' class='ui-sortable col-sm-12 col-md-12 col-lg-6' style="min-height: 500px">
    %DASHBOARD%
    %LEFT_PANEL%
  </section>
  <section id='right-column' class='ui-sortable col-sm-12 col-md-12 col-lg-6 ' style="min-height: 500px">
    %RIGHT_PANEL%
  </section>
  <div class='col-md-12 col-lg-12'>
    %SERVICE_INFO_3%
  </div>
</div>
<script>
  jQuery( function() {
    jQuery( ".ui-sortable" ).sortable({
      connectWith: ".ui-sortable",
      handle: ".box-header",
      cursor: "move",
      placeholder: "portlet-placeholder ui-corner-all"
    });
    jQuery(".box-header").hover(function() {
      jQuery(this).css('cursor','pointer');
    }, function() {
      jQuery(this).css('cursor','auto');
    });

  //  Left schema save to DB
    jQuery('#left-column').on("sortupdate", function () {
      var formData1 = '';
      jQuery("#left-column").find("div.for_sort").each(function(){
        formData1 += ',' + this.id ;
      });
      if (formData1 == '') {
        formData1 = 'empty';
      }
      formData1 = '?get_index=set_admin_params&header=2&LSCHEMA=1&VALUE_LEFT=' + formData1;
      /* Send Data */
      jQuery.post('/admin/index.cgi', formData1, function () {
      });
      formData1 = '';
    });

    //Right schema save to DB
    jQuery('#right-column').on("sortupdate", function () {
      var formData2 = '';
      jQuery("#right-column").find("div.for_sort").each(function(){
        formData2 += ',' + this.id ;
      });
      if (formData2 == '') {
        formData2 = 'empty';
      }
      formData2 = '?get_index=set_admin_params&header=2&RSCHEMA=1&VALUE_RIGHT=' + formData2;
      /* Send Data */
      jQuery.post('/admin/index.cgi', formData2, function () {
      });
      formData2 = '';
    });
  } );
</script>
