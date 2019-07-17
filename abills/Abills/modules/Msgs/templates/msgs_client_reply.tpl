<input type='hidden' name='MAIN_INNER_MESSAGE' value='%MAIN_INNER_MSG%'/>
<input type='hidden' id='rating' name='rating'/>
<script type='text/javascript'>

  jQuery(function () {
    var form = jQuery('form');

    jQuery('#send-rating').on('click', function () {
      form.unbind('submit');
    });

    jQuery('#go').on('click', function () {
      form.unbind('submit');

      var state = jQuery('#STATE').val();

      if ((state == 1) || (state == 2)) {
        jQuery('form').submit(function () {
          return false;
        });

        jQuery('#myModal').modal('show');

        jQuery('.send-rating').off('click');

        var stars = jQuery('.rating-star');

        // Fill meta data position for all stars
        stars.each(function (i, s) {
          jQuery(s).data('position', i);
        });

        stars.on('click', function () {
          var _this = jQuery(this);

          var pos = _this.data('position');
          stars.removeClass('active');

          for (var i = 0; i <= pos; i++) {
            jQuery(stars[i]).addClass('active');
          }

          jQuery('#rating').val(pos + 1);
        });
      }
    })
  })


</script>
<style type='text/css'>
  .fa-star {
    color: #c4c3be;
    font-size: 2em;
    margin: 0;
    padding: 0;

  }

  .fa-fw.fa-star.active {
    color: #fff72b;
    font-size: 2em;
  }

  .fa-fw.fa-star:hover {
    color: #fff72b;
  }

  .modal-title {
    color: #79797a;
  }

  .rating-block {
    cursor: pointer;
  }
</style>
<div class='modal fade in' id='myModal' role='dialog'>
  <div class='modal-dialog'>
    <div class='modal-content'>
      <div class='modal-header text-center'>
        <button type='button' class='close' data-dismiss='modal'>&times;</button>
        <h4 class='modal-title'>_{ASSESSMENT}_</h4>
      </div>
      <div class='modal-body text-center'>
        <div class='rating-block'>
          <a href='#myModal' class='fa fa-fw fa-star rating-star'></a>
          <a href='#myModal' class='fa fa-fw fa-star rating-star'></a>
          <a href='#myModal' class='fa fa-fw fa-star rating-star'></a>
          <a href='#myModal' class='fa fa-fw fa-star rating-star'></a>
          <a href='#myModal' class='fa fa-fw fa-star rating-star'></a>
        </div>
      </div>
      <div class='row'>
        <div class='col-md-12'>
          <div class='form-group'>
            <textarea name='rating_comment' placeholder='_{YOUR_FEEDBACK}_' class='form-control' rows='5'
                      style='width:85%; margin-left:auto;margin-right:auto'></textarea>
          </div>
        </div>
      </div>

      <div class='modal-footer'>
        <input type='submit' name='%ACTION%' value='%LNG_ACTION%' title='Ctrl+C' id='send-rating'
               class='btn btn-primary'>
      </div>
    </div>
  </div>
</div>
<div class='noprint'>
  <div class='box box-primary'>
    <div class='box-header with-border'>
      <h5 class='box-title text-center'>_{REPLY}_</h5>
    </div>
    <input type='hidden' name='SUBJECT' value='%SUBJECT%' size=50/>

    <div class='box-body form form-horizontal'>
      <div class='form-group'>
        <div class='col-md-12'>
          <textarea class='form-control' name='REPLY_TEXT' cols='90' rows='11'>%QUOTING% %REPLY_TEXT%</textarea>
        </div>
      </div>
      <div class='form-group'>
        %ATTACHMENT%
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{ATTACHMENT}_:</label>

        <div class='col-md-9' style='padding:5px'><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
          <!--   <input class='button' type='submit' name='AttachmentUpload' value='_{ADD}_'>-->
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{STATUS}_:</label>

        <div class='col-md-9'>%STATE_SEL% %RUN_TIME%</div>
      </div>
    </div>
    <div class='box-footer text-center'>
      <input type='hidden' name='sid' value='$sid'/>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%' id='go'
             title='_{SEND}_ (Ctrl+Enter)'/>
    </div>
  </div>
</div>
