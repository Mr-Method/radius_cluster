<input type='hidden' name='MAIN_INNER_MESSAGE' value='%MAIN_INNER_MSG%'/>
<input type='hidden' name='RATING' id='rating'/>

<script type='text/javascript'>
'use strict';
  // Multi upload logic
  jQuery(function () {
    var MAX_FILES_COUNT = 3;
    initMultifileUploadZone('file_upload_holder', 'FILE_UPLOAD', MAX_FILES_COUNT);
  });

  // Rating modal logic
  jQuery(function () {
    var form            = jQuery('form');
    var rating_modal    = jQuery('#rating-modal');
    var save_rating_btn = jQuery('#send-rating');
    var stars           = jQuery('.rating-star');
    var rating_input    = jQuery('#rating');
    var state_select    = jQuery('#STATE');
    var btn_name        = "";

    jQuery('.btn').on('click', function(e) {
      btn_name = e.target.id;
    });

    var force_submit = function () {
      form.off('submit');

      jQuery('#go').on('click', cancelEvent);
      jQuery('#send-rating').on('click', cancelEvent);
//      renameAndDisable('go', '_{IN_PROGRESS}_...');
//      renameAndDisable('send-rating', '_{IN_PROGRESS}_...');
      form.append(jQuery('<input/>', { name : '%ACTION%', value : '%LNG_ACTION%', type : 'hidden'}));
      form.submit();
    };

    var send_with_rating = function () {

      // Submit if have rating
      if (rating_input.val() !== 'undefined') {
        force_submit();
        return true;
      }

      // Else should show rating modal
      show_rating_modal();
    };

    var paint_rating_stars = function (rating) {
      stars.removeClass('active');
      for (var i = 0; i <= rating; i++) {
        jQuery(stars[i]).addClass('active');
      }
    };

    var show_rating_modal = function () {
      rating_modal.modal('show');

      // Fill initial colors
      rating_input.val(3);
      paint_rating_stars(2);

      // Fill meta data position for all stars
      stars.each(function (i, s) {
        jQuery(s).data('position', i);
      });

      stars.off('click');
      stars.on('click', function () {
        var _this = jQuery(this);
        var pos   = _this.data('position');
        paint_rating_stars(pos);
        rating_input.val(pos + 1);
      });

      save_rating_btn.off('click', send_with_rating);
      save_rating_btn.on('click', send_with_rating);
    };

    var check_values_and_submit_form = function (e) {
      if (btn_name == 'change') {
        return true;
      }
      cancelEvent(e);

      // Submit if going to close
      var message_state = state_select.val();
      if ((+message_state === 1) || (+message_state === 2)) {
        show_rating_modal();
      }
      else {
        force_submit();
        return true;
      }
    };

    // Before sending show rating form
   form.on('submit', check_values_and_submit_form);
  });

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

<div class='modal fade in' id='rating-modal' role='dialog'>
  <div class='modal-dialog'>
    <div class='modal-content'>
      <div class='modal-header text-center'>
        <button type='button' class='close' data-dismiss='modal'>&times;</button>
        <h4 class='modal-title'>_{ASSESSMENT}_</h4>
      </div>
      <div class='modal-body text-center'>
        <div class='rating-block'>
          <a href='#rating-modal' class='fa fa-fw fa-star rating-star'></a>
          <a href='#rating-modal' class='fa fa-fw fa-star rating-star'></a>
          <a href='#rating-modal' class='fa fa-fw fa-star rating-star active'></a>
          <a href='#rating-modal' class='fa fa-fw fa-star rating-star'></a>
          <a href='#rating-modal' class='fa fa-fw fa-star rating-star'></a>
        </div>
      </div>
      <div class='row'>
        <div class='col-md-12'>
          <div class='form-group'>
            <textarea name='RATING_COMMENT' placeholder='_{YOUR_FEEDBACK}_' class='form-control' rows='5'
                      style='width:85%; margin-left:auto;margin-right:auto'></textarea>
          </div>
        </div>
      </div>

      <div class='modal-footer'>
        <input type='submit' name='%ACTION%' value='%LNG_ACTION%' id='send-rating' class='btn btn-primary'/>
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

    <div class='box-body form form-horizontal' id='box-body'>
      <div class='form-group'>
        <div class='col-md-12'>
          <textarea data-action='drop-zone' class='form-control' name='REPLY_TEXT' cols='90' rows='11'>%QUOTING% %REPLY_TEXT%</textarea>
        </div>
      </div>
      <div class='form-group'>
        %ATTACHMENT%
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{ATTACHMENT}_:</label>

        <div class='col-md-9' style='padding:5px' id='file_upload_holder'>
          <input name='FILE_UPLOAD' type='file' data-number='0' class='fixed'>
        </div>

      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{STATUS}_:</label>
        <div class='col-md-9'>%STATE_SEL% %RUN_TIME%</div>
      </div>
      <input type='hidden' name='signature' id='signData' value='' />
    </div>
    <div class='box-footer'>
      <input type='hidden' name='sid' value='$sid'/>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%' id='go'
             title='_{SEND}_ (Ctrl+Enter)'/>
    </div>
  </div>
</div>

<script src="/styles/default_adm/js/draganddropfile.js"></script>
<script src="/styles/default_adm/js/signature_pad.js"></script>
<script type="text/javascript">

  jQuery(function(){

    jQuery('select#STATE').on('change',function(e){
      changeEventHandler(e);
    });

  });

  var signaturePad;
  // document.addEventListener('DOMContentLoaded',function() {
  //   document.querySelector('select[id="STATE"]').onchange=changeEventHandler;
  // },false);

  function changeEventHandler(event) {
    if(event.target.value == 2) {
      addSigpad();
      addBtn();
      initSigpad();
    }
    else {
      if (document.querySelector("#signature-pad")) {
        document.querySelector("#signature-pad").remove();
      }
    }
  }

  function addSigpad() {
    // var sigpad = jQuery('<div></div>', { id : 'signature-pad', 'class' : 'signature-pad'});

    var sigpad = document.createElement("div");
    sigpad.id = "signature-pad";
    sigpad.className = "signature-pad";

    var sigpadbody = document.createElement("div");
    sigpadbody.className = "signature-pad--body";
    sigpadbody.innerHTML = "<canvas style='border:solid #000000; width: 100%; position: relative;'></canvas> ";

    sigpad.appendChild(sigpadbody);

    document.querySelector('div[id="box-body"]').appendChild(sigpad);
  }

  function initSigpad() {
    var ratio  = Math.max(window.devicePixelRatio || 1, 1);
    var canvas = document.querySelector("canvas");
    signaturePad = new SignaturePad(canvas, {
      backgroundColor: 'rgb(255, 255, 255)'
    });
    canvas.width = canvas.offsetWidth * ratio;
    canvas.height = canvas.offsetHeight * ratio;
    canvas.getContext("2d").scale(ratio, ratio);
    signaturePad.clear();
  }

  window.onresize = initSigpad;

  function addBtn() {
    var sigpad = document.querySelector("#signature-pad");
    var buttons = document.createElement("div");
    buttons.innerHTML = "<button type='button' class='btn btn-default' data-action='clear'>_{CLEAR}_</button> "
                      + "<button type='button' class='btn btn-default' data-action='sign'>_{SIGN}_</button>";
    sigpad.appendChild(buttons);

    var clearButton = sigpad.querySelector("[data-action=clear]");
    var signButton  = sigpad.querySelector("[data-action=sign]");
    
    clearButton.addEventListener("click", function (event) {
      signaturePad.clear();
    });

    signButton.addEventListener("click", function (event) {
      document.getElementById("signData").value = signaturePad.toDataURL();
      document.querySelector("#signature-pad").remove();
    });
  }
  
</script>
