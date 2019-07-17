
<div class='box box-theme'>
<div class='box-body'>

<form action='$SELF_URL' method='POST' id='payment-form'>
<input type=hidden name=OPERATION_ID value='$FORM{OPERATION_ID}'>
<input type=hidden name=PAYMENT_SYSTEM value='$FORM{PAYMENT_SYSTEM}'>
<input type=hidden name=TP_ID value='$FORM{TP_ID}'>
<input type=hidden name=PHONE value='$FORM{PHONE}'>
<input type=hidden name=DOMAIN_ID value='$FORM{DOMAIN_ID}'>
<input type=hidden name=index value='$index'>

<table style='min-width:350px;' width=auto class=form>
<tr><th colspan=2 class=form_title>Stripe</th></tr>
    <tr>
        <td>_{ORDER}_:</td>
        <td>$FORM{OPERATION_ID}</td>
    </tr>
    <tr>
        <td>_{SUM}_:</td>
        <td>$FORM{SUM}</td>
    </tr>
    <tr>
        <td>_{DESCRIBE}_:</td>
        <td>%LOGIN% $FORM{DESCRIBE}</td>
    </tr>
</table>

  <script
    src='https://checkout.stripe.com/checkout.js' class='stripe-button'
    data-key='$conf{PAYSYS_STRIPE_PUBLISH_KEY}'
    data-amount='%AMOUNT%'
    data-name='$conf{WEB_TITLE}'
    data-description='2 widgets ($FORM{SUM})'
    data-image='/128x128.png'>
  </script>
</form>

</div>
</div>

