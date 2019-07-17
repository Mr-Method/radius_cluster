<style>
    .card-row{
        height: 75px;
    }
</style>

<div class='row text-left card-row %CARD_SELECTED%'>
    <label class='paysys_card'>
        <div class='col-md-1 text-left pull-left card-checkbox-container'>
            <div class='horizontal-centered'>
                <input type='radio' name='CARD_ALIAS' value='%NAME%' class='card-radio' %CHECKED%>
            </div>&nbsp;
        </div>
        <div class='col-md-11 text-left card-text-container card-selected-highlight'>
            <div class='pull-left'><img height="50px" width="50" src='styles/default_adm/img/paysys_logo/credit_card.png'></div>
            <div class='horizontal-centered-del pull-right'>
                %DELETE_BUTTON%
            </div>
            <h4>%NAME%</h4>
            <small>%MASK%</small>
        </div>

    </label>
</div>
