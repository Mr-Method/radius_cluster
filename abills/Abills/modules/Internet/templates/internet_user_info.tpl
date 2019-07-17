<div class='box box-theme'>
    <div class='box-header with-border'>
        <h3 class='box-title'>_{INTERNET}_ (%ID%)</h3>
        <div class='box-tools pull-right'>
          <button type='button' class='btn btn-box-tool' data-widget='collapse'>
            <i class='fa fa-minus'></i>
          </button>
        </div>
    </div>
    <div class='box-body'>
        <div class='row'>
            <div class='col-md-12'>
                %PAYMENT_MESSAGE%
                %NEXT_FEES_WARNING%
                %TP_CHANGE_WARNING%
                %SERVICE_EXPIRE_DATE%
            </div>
        </div>
        <div class='row'>
            <div class='col-md-3 text-1'>_{STATUS}_</div>
            <div class='col-md-9 text-2'><b>%STATUS_VALUE%</b> %HOLDUP_BTN%</div>
        </div>
        <div class='row'>
            <div class='col-md-3 text-1'>_{TARIF_PLAN}_</div>
            <div class='col-md-9 text-2'>%TP_NAME%<span class='extra'>%TP_CHANGE%</span><br>%COMMENTS%</div>
        </div>
        %EXTRA_FIELDS%
        %PREPAID_INFO%
    </div>
</div>


