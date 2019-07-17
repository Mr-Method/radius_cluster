<style>
    div.horizontal-centered-del {
        margin-top: 10px;
        margin-bottom: 15px;
    }

    div.horizontal-centered {
        margin-top: 20px;
        margin-bottom: 15px;
    }

    label.paysys_card {
        width: 100%;
    }

    div.card-row {
        min-height: 60px;
    }

    div.card-row div.card-text-container {
        padding: 10px;
    }

    div.card-row div.card-text-container h4 {
        margin-top: 0;
    }

    div.card-row.card-selected {
        /*background-color: lightblue;*/
    }

    div.card-row.card-selected div.card-selected-highlight {
        background-color: lightblue;
    }

    .fa-trash{
        color: #707070;
    }
</style>


<div class='col-md-12 text-left'><strong>_{CHOOSE_CARD_FOR_ONECLICK_PAY}_</strong></div>
<div class='col-md-12'>
    <div class='col-md-6'>
        <div class='form-group'>
            %CARDS%
            %ADD_BTN%
        </div>
    </div>
    <div class='col-md-6'>
        <p><strong>_{PAYMENT_BY_ANY_CARD}_</strong></p>
        <p><input type='submit' class='btn btn-primary' name='%SUBMIT_NAME%' value='_{PAY}_'/></p>
    </div>
</div>
<p>
<img class='img-responsive center-block' src='styles/default_adm/img/paysys_logo/masterpass-des.png'>
</p>
<script>
    jQuery(function () {


        jQuery('input.card-radio').on('change', function () {
            var radio = jQuery(this);
            console.log('change');
            jQuery('div.card-row').removeClass('card-selected');


            var label = radio.parents('div.card-row').first();
            if (radio.prop('checked') === true) {
                label.addClass('card-selected');
            }
        });
    });
</script>
