
(function ($, AdminLTE) {

  "use strict";

  /**
   * List of all the available skins
   *
   * @type Array
   */

  var my_skins = [
    "skin-blue",
    "skin-black",
    "skin-red",
    "skin-yellow",
    "skin-purple",
    "skin-green",
    "skin-blue-light",
    "skin-black-light",
    "skin-red-light",
    "skin-yellow-light",
    "skin-purple-light",
    "skin-green-light"
  ];


  setup();

  /**
   * Toggles layout classes
   *
   * @param cls the layout class to toggle
   * @returns void
   */
  function change_layout(cls) {
    $("body").toggleClass(cls);
  }

  /**
   * Replaces the old skin with the new skin
   * @param cls the new skin class
   * @returns Boolean false to prevent link's default action
   */
  function change_skin(cls) {
    $.each(my_skins, function (i) {
      $("body").removeClass(my_skins[i]);
    });

    $("body").addClass(cls);
    return false;
  }

  /**
   * Retrieve default settings and apply them to the template
   *
   * @returns void
   */
  function setup() {
    //Add the change skin listener
    $("[data-skin]").on('click', function (e) {
      if($(this).hasClass('knob'))
        return;
      e.preventDefault();
//      var $em = $('list-unstyled').find('')
        $(this).addClass("hover");
        $('#skin').val($(this).data('skin'));
      change_skin($(this).data('skin'));
    });

    //Add the layout manager
    $("[data-layout]").on('click', function () {
      change_layout($(this).data('layout'));
    });

    $("[data-controlsidebar]").on('click', function () {
      change_layout($(this).data('controlsidebar'));
      var slide = !AdminLTE.options.controlSidebarOptions.slide;
      AdminLTE.options.controlSidebarOptions.slide = slide;
      if (!slide)
        $('.control-sidebar').removeClass('control-sidebar-open');
    });

    $("[data-sidebarskin='toggle']").on('click', function () {
      var sidebar = $(".control-sidebar");
      if (sidebar.hasClass("control-sidebar-dark")) {
        sidebar.removeClass("control-sidebar-dark");
        sidebar.addClass("control-sidebar-light")
      } else {
        sidebar.removeClass("control-sidebar-light");
        sidebar.addClass("control-sidebar-dark")
      }
    });
    
    $("[data-header='fixed']").on('click', function () {
      var $nav =$("nav.navbar.navbar-static-top");
      $(this).prop('checked')
          ? $nav.addClass('navbar-fixed-top')
          : $nav.removeClass('navbar-fixed-top');
          
    });
    

    // Reset options
    if ($('body').hasClass('fixed')) {
      $("[data-layout='fixed']").attr('checked', 'checked');
    }


  }
})(jQuery, $.AdminLTE);
