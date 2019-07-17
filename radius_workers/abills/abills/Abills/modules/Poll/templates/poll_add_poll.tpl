<script src='/styles/default_adm/js/modules/poll.js'></script>
<form action=$SELF_URL METHOD=POST class='form-horizontal' id='POLL_ANSWER_FORM'>

<input type='hidden' name='index' value="%INDEX%">
<input type='hidden' name='action' value=%ACTION%>
<input type='hidden' name='id' value='%ID%'>
%JSON%

<div class='box box-theme box-form'>
    <div class='box-header with-border text-primary'><h3>_{POLL}_</h3></div>

<div class='box-body'>
  <div class='form-group'>
      <label class='col-md-3 control-label required'>_{SUBJECT}_</label>
  	<div class='col-md-9'>
        <input class='form-control' type='text' name='SUBJECT' value='%SUBJECT%' placeholder='_{POLL_SUBJECT}_'
               required='required'>
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{DESCRIPTION}_</label>
  	<div class='col-md-9'>
        <textarea class='form-control' type='text' name='DESCRIPTION' placeholder='_{POLL_DESCRIPTION}_'
                  maxlength='200'>%DESCRIPTION%</textarea>
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{STATUS}_</label>
  	<div class='col-md-9'>
  		%STATUS%
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'><span id='answerLabel'>_{ANSWER}_</span> 1</label>
  	<div class='col-md-9'>
        <input class='form-control' type='text' name='ANSWER' value='%ANSWER_1%' placeholder='_{ANSWER}_' %DISABLE%
               required='required'>
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{ANSWER}_ 2</label>
  	<div class='col-md-9'>
        <input class='form-control' type='text' name='ANSWER' value='%ANSWER_2%' placeholder='_{ANSWER}_' %DISABLE%
               required='required'>
  	</div>
  </div>
  <div id='extraAnswerWrapper'></div>
 </form>

  <div class='form-group %HIDDEN%' id='extraAnswerControls' style='margin-right: 15px;'>
      <div class='text-right'>
          <div class='btn-group btn-group-xs'>
              <button class='btn btn-xs btn-danger' id='removeAnswerBtn'
                      data-tooltip='_{DEL}_ _{POLL}_'
                      data-tooltip-position='bottom'>
                  <span class='glyphicon glyphicon-remove'></span>
              </button>
              <button class='btn btn-xs btn-success' id='addAnswerBtn'
                      data-tooltip='_{ADD}_ _{POLL}_'>
                  <span class='glyphicon glyphicon-plus'></span>
              </button>
          </div>
      </div>
  </div>
</div>

<div class='box-footer'>
  <button  form='POLL_ANSWER_FORM' type='submit' class='btn btn-primary'>%BUTTON%</button>
</div>

</div>

