<script type='text/javascript'>
    function selectLanguage() {
        var sLanguage = jQuery('#language').val() || '';
        var sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language=' + sLanguage;
        document.location.replace(sLocation);
    }
    function set_referrer() {
        document.getElementById('REFERER').value = location.href;
    }
</script>

<nav class='navbar navbar-default' role='navigation'>
    <div class='container-fluid navbar-right'>
        <h1><span style='color: red;'>A</span>BillS
            <small>%TITLE%</small>
            &nbsp;</h1>
    </div>
</nav>

%ERROR_MSG%

<div class='container'>
    <form action='$SELF_URL' METHOD='post' name='frm' id='form_login' class='form-horizontal'>

        <input type=hidden name=DOMAIN_ID value='$FORM{DOMAIN_ID}'>
        <input type=hidden ID=REFERER name=REFERER value='$FORM{REFERER}'>
        <input type='hidden' name='LOGIN' value='1' />
        <fieldset>

            <div class='form-group'>
                <label class='control-label col-md-6' for='user'>_{LANGUAGE}_</label>

                <div class='col-md-2'>
                    %SEL_LANGUAGE%
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-6' for='user'>_{USER}_</label>

                <div class='col-md-2'>
                    <div class='input-group'>
                        <span class='input-group-addon'><span class='glyphicon glyphicon-user'></span></span>
                        <input id='user' name='user' value='%user%' placeholder='_{USER}_' class='form-control'
                               type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-6' for='passwd'>_{PASSWD}_</label>

                <div class='col-md-2'>
                    <div class='input-group'>
                        <span class='input-group-addon'><span class='glyphicon glyphicon-lock'></span></span>
                        <input id='passwd' name='passwd' value='%password%' placeholder='_{PASSWD}_' class='form-control'
                               type='password'>
                    </div>
                </div>
            </div>

            <div class='form-group'>
                <div class='col-sm-offset-6 col-md-6'>
                    <input type='submit' class='btn btn-default' name='logined' value='_{ENTER}_'
                           onclick='set_referrer()'>
                </div>
            </div>

        </fieldset>
    </form>
</div>

