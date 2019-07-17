<form name='STORAGE_USER_SEARCH' id='form-search' method='post' class='form form-horizontal'>
    <input type='hidden' name='qindex' value='$index'/>
    <input type='hidden' name='install_accountability' value='1'/>
    <input type='hidden' name='user_search_form' value='2'/>


    <div class='form-group'>
        <label class='control-label col-md-2' for='LOGIN_id'>_{LOGIN}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' name='LOGIN' id='LOGIN_id'/>
        </div>
    </div>

    <div class='form-group'>
        <label class='control-label col-md-2' for='FIO_id'>_{FIO}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' name='FIO' id='FIO_id'/>
        </div>
    </div>

    <div id='address_form_target'></div>

</form>

<script>

    //Copy address form
    jQuery(function () {
        var address_form = jQuery('#address_form_source').clone(true);
        address_form.find('.chosen-container').remove();
        address_form.find('select').show();
        address_form.appendTo('#address_form_target');
    });
    updateChosen();

    function defineSearchResultLogic() {
        var searchResult = jQuery('.search-result');

        var hiddenInput = jQuery('#UID_HIDDEN');
        var loginInput = jQuery('#USER_LOGIN');

        searchResult.on('click', function () {
            aModal.hide();

            var login = jQuery(this).text();
            var uid = jQuery(this).attr('data-uid');

            hiddenInput.val(uid);
            loginInput.val(login);

            aModal.destroy();
        });
    }
</script>
