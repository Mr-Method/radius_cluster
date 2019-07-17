<div class='box box-theme box-form'>
<!--<div class='box-header with-border'><h4>Vlan</h4></div>-->
<div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-5' for='OLT'>_{SELECT_OLT}_:</label>

                <div class='col-md-7 control-element'>
                    %OLT_SEL%
                </div>
            </div>
</div>
</div>

    <script>
        \$(document).ready(function(){
            \$('#NAS_ID').change(function(){
                var nas_id = \$('#NAS_ID').val();
                var link = "index.cgi?index=%INDEX%&visual=4&NAS_ID=" + nas_id;
                window.location.replace(link);
            });

        });
    </script>
