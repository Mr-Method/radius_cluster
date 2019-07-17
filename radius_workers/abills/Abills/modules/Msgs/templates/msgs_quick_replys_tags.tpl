<form id='msgs_tags' method='POST' action='$SELF_URL'>
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='chg' value='%MSGS_ID%'/>
  <input type='hidden' name='UID' value='%UID%'/>

  <button type="button" id='accordion_open_all' class="btn btn-default btn-xs pull-right" >_{OPEN}_ _{ALL}_</button>

  <ul id='accordion'>
   %LIST%
 </ul>
 %SUMBIT_BTN%
</form>












<style type="text/css">
 #accordion li {
    color : #3c8dbc;
    cursor: pointer;
  }
  #accordion li:hover {
    color : #437ea0;
    cursor: pointer;
  }
  #accordion .box {
    border-top: none;
  }
  #accordion{
    padding-top: 15px;
  }
</style>

<script type="text/javascript">
  jQuery('#accordion_open_all').on('click', function () {
    jQuery('#accordion .collapse').collapse('toggle');
});
</script>