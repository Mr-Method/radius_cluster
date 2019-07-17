<!-- Таблица стилей CSS -->
<style type="text/css">
  
  .item{
      background: #abc;    
      text-align: center;
      height: 300px !important;
  }

  .carousel{
      height: 300px;
  }

  .carousel-control.left, .carousel-control.right {
    background-image: none;
    filter: none;
  }
</style>

<!-- Карусель -->

  <div id="myCarousel" class="carousel slide" data-interval="3000" data-ride="carousel">
    <ol class="carousel-indicators">
      %INDICATORS%
    </ol>
    <div class="carousel-inner">
      %CONTENT%
    </div>
 
    <a class="carousel-control left" href="#myCarousel" data-slide="prev">
      <span class="glyphicon glyphicon-chevron-left"></span>
    </a>
    <a class="carousel-control right" href="#myCarousel" data-slide="next">
      <span class="glyphicon glyphicon-chevron-right"></span>
    </a>
  </div>
<hr>