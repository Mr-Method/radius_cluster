   <div class='col-xs-12 col-md-6'>
      <input type=hidden name=COMPANY_ID value='$FORM{COMPANY_ID}'>
      <div class='box box-theme'>
         <div class='box-body'>
            <div class='form-group'>
               <label class='col-md-3 control-label'>_{GROUP}_:</label>
               <div class='col-md-9'>
                  <input class='form-control' type=text name=GROUP_SEL value='%GROUP_SEL%'>
               </div>
            </div>
            <div class='form-group'>
               <label class='col-md-3 control-label'>_{INVOICE_AUTO_GEN}_:</label>
               <div class='col-md-9'>
                  <input type=checkbox name=PERIODIC_CREATE_DOCS value=1 %PERIODIC_CREATE_DOCS%>
               </div>
            </div>
            <div class='form-group'>
               <label class='col-md-3 control-label'>_{SEND}_ E-mail:</label>
               <div class='col-md-9'>
                  <input type=checkbox name=SEND_DOCS value=1 %SEND_DOCS%>
               </div>
            </div>
            <div class='form-group'>
               <label class='col-md-3 control-label'>E-mail:</label>
               <div class='col-md-9'>
                  <input type=text name=EMAIL value='%EMAIL%'>
               </div>
            </div>
            <div class='form-group'>
               <label class='col-md-3 control-label'>_{INVOICING_PERIOD}_:</label>
               <div class='col-md-9'>
                  %INVOICE_PERIOD_SEL%
               </div>
            </div>
            <div class='form-group'>
               <label class='col-md-3 control-label'>_{INVOICE}_ _{DATE}_:</label>
               <div class='col-md-9'>
                  %INVOICE_DATE%
               </div>
            </div>
            <div class='form-group'>
               <label class='col-md-3 control-label'>_{NEXT_INVOICE_DATE}_:</label>
               <div class='col-md-9'>
                  %PRE_INVOICE_DATE%
               </div>
            </div>
            <div class='form-group'>
               <label class='col-md-3 control-label'>_{STATUS}_:</label>
               <div class='col-md-9'>
                  %STATUS_SEL%
               </div>
            </div>
         </div>
      </div>
   </div>



