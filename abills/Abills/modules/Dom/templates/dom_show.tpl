 <script src="/styles/default_adm/js/raphael.min.js"></script>
 <script src="/styles/default_adm/js/build_construct.js"></script>
 <form method='post' class='form form-horizontal'>

  <script type="application/javascript">
    jQuery(document).ready(function(){
      build_construct(%BUILD_FLORS%,%BUILD_ENTRANCES%,%FLORS_ROOMS%,'canvas_container',%USER_INFO%,%LANG_PACK%);

    })
  </script>

  <body id='body'>
    <div id="canvas_container" >
      <div id="tip"></div>
    </div>
  </body>
  <style type="text/css">
    #tip{
     position : fixed;
     color:white;
     border : 1px solid white;
     background-color : #7AB932;
     padding : 3px;
     z-index: 1000;
     /* set this to create word wrap */
     max-width: 200px;
   }
 </style>
</form>

