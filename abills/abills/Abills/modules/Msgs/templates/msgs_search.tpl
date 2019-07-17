<div class='col-xs-12 col-md-6'>
    <div class='box box-theme box-form'>
        <div class='box-body'>

            <div class='form-group'>
                <label class='control-label col-md-2' for='LOGIN'>ID:</label>
                <div class='col-md-3'>
                    <input id='MSG_ID' name='MSG_ID' value='%MSG_ID%' placeholder='%MSG_ID%' class='form-control'
                           type='text'>
                </div>

                <label class='control-label col-md-4' for='INNER_MSG'>_{PRIVATE}_</label>
                <div class='col-md-1'>
                    <input type=checkbox name=INNER_MSG value=1 %INNER_MSG%>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-2' for='CHAPTER_ID'>_{CHAPTERS}_</label>
                <div class='col-md-8'>
                    %CHAPTER_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-2' for='SUBJECT'>_{SUBJECT}_:</label>
                <div class='col-md-10'>
                    <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-2' for='MESSAGE'>_{MESSAGE}_:</label>
                <div class='col-md-10'>
                    <input id='SUBJECT' name='MESSAGE' value='%MESSAGE%' placeholder='%MESSAGE%' class='form-control'
                           type='text'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-2' for='STATE'>_{STATE}_:</label>
                <div class='col-md-10'>
                    %STATE_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-2' for='PRIORITY'>_{PRIORITY}_:</label>
                <div class='col-md-10'>
                    %PRIORITY_SEL%
                </div>
            </div>

         <div class='form-group'>
                <label class='control-label col-md-2' for='MSGS_TAGS'>_{MSGS_TAGS}_:</label>
                <div class='col-md-10'>
                    %MSGS_TAGS_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' >_{EXECUTION}_:</label>
                <div class='col-md-4'>
                    <input id='PLAN_FROM_DATE' name='PLAN_FROM_DATE' value='%PLAN_FROM_DATE%'
                           placeholder='%PLAN_FROM_DATE%' class='form-control datepicker' type='text'>
                </div>
                <label class='control-label col-md-1' >-</label>
                <div class='col-md-4'>
                    <input id='PLAN_TO_DATE' name='PLAN_TO_DATE' value='%PLAN_TO_DATE%' placeholder='%PLAN_TO_DATE%'
                           class='form-control datepicker' type='text'>
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-2' for='RESPOSIBLE'>_{RESPOSIBLE}_:</label>
                <div class='col-md-8'>
                    %RESPOSIBLE_SEL%
                </div>
            </div>


        </div>
    </div>
</div>
