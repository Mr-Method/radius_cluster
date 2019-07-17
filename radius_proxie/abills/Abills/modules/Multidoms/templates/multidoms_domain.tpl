<div class='box box-theme box-form'>
<div class='box-body'>


<form action='$SELF_URL' METHOD='POST' class='form-horizontal'>
    <fieldset>
    <div class='panel panel-primary panel-form'>
        <div class='panel-heading text-center'><h4>_{DOMAINS}_</h4></div>
        <div class='panel-body'>
            <input type='hidden' name='index' value='$index'>
            <input type='hidden' name='chg' value='$FORM{chg}'>

                <div class='form-group'>
                    <label class='control-label col-md-2' for='NAME'>_{NAME}_</label>
                    <div class='col-md-10'>
                        <input id='NAME' name='NAME' value='%LOGIN%' placeholder='%NAME%' class='form-control'
                               type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-2' for='NAME'>_{DISABLE}_</label>
                    <div class='col-md-5'>
                        <input type='checkbox' name='STATE' value=1 %STATE%>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-2' for='NAME'>_{CREATED}_</label>
                    <div class='col-md-5'>
                        %CREATED%
                    </div>
                </div>

                <div class='form-group'>
                    <div class='col-md-12'>
                        _{COMMENTS}_
                    </div>
                </div>

                <div class='form-group'>
                    <div class='col-md-12'>
                        <textarea cols=60 rows=6 name=comments class='form-control'>%RULES%</textarea>
                    </div>
                </div>

        </div>
        <div class='panel-footer'>
            <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
        </div>
    </div>

    </fieldset>
</form>
