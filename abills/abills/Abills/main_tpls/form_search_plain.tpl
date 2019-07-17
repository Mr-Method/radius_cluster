<form action='$SELF_URL' METHOD='GET' name='form_search' id='form_search' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='search_form' value='1'>
  %HIDDEN_FIELDS%

  <fieldset>

    <button class='btn btn-primary btn-block' type='submit' name='search' value=1  style='margin-bottom: 10px'>
      <i class='glyphicon glyphicon-search'></i> _{SEARCH}_
    </button>

    <div class='col-md-6 col-xs-12'>
      %ADDRESS_FORM%
    </div>

    <TABLE class='form'>
      %SEARCH_FORM%
    </TABLE>

    <button class='btn btn-primary btn-block' type='submit' name='search' value=1><i
        class='glyphicon glyphicon-search'></i> _{SEARCH}_
    </button>

  </fieldset>
</form>
