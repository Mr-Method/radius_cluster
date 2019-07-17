<link rel='stylesheet' href='/styles/default_adm/css/bootstrap-tour.min.css'>
<script src='/styles/default_adm/js/bootstrap-tour.min.js'></script>

<script>
  function getTemplate(i, step) {

    return "<div class='popover tour'>"
        + "<div class='arrow'></div>"
        + "<h3 class='popover-title text-bold'></h3>"
        + "<div class='popover-content'></div>"
        + "<div class='popover-navigation'>"
        + "<button class='btn btn-default' data-role='prev'><span class='glyphicon glyphicon-backward'></span></button>"
        + "<button class='btn btn-default' data-role='next'><span class='glyphicon glyphicon-forward'></span></button>"
        + "<button class='btn btn-default' data-role='end'>_{FINISH}_</button>"
        + "</div>"
        + "</div>";
  }

  jQuery(function () {

//    localStorage.setItem('tour_current_step', '10');


    // Instance the tour
    var tour = new Tour({
//      debug   : true,
      template: getTemplate,
      steps   : [
// Tutorial welcome
        {
          path    : '/admin/',
          orphan  : true,
          title   : '_{GUIDE_WELCOME}_',
          content : '_{GUIDE_WELCOME_TEXT}_',
          backdrop: true
        },

// Main menu
        {
          element : 'aside.main-sidebar',
          title   : '_{GUIDE_MAIN_MENU}_',
          content : '_{GUIDE_MAIN_MENU_TEXT}_',
          backdrop: true
        },
//Messages
        {
          element  : '#messages-menu',
          title    : '_{GUIDE_MESSAGES_MENU}_',
          content  : '_{GUIDE_MESSAGES_MENU_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom'
        },

//Responsible
        {
          element  : '#responsible-menu',
          title    : '_{GUIDE_RESPONSIBLE_MENU}_',
          content  : '_{GUIDE_RESPONSIBLE_MENU_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom'
        },

//Events
        {
          element  : '#events-menu',
          title    : '_{GUIDE_EVENTS_MENU}_',
          content  : '_{GUIDE_EVENTS_MENU_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom',
          onShown  : function () {
            AMessageChecker.processData(
                {
                  TYPE    : 'EVENT',
                  TITLE   : 'TEST',
                  TEXT    : '_{EVENT}_',
                  EXTRA   : '$SELF_URL',
                  MODULE  : "WEB",
                  GROUP_ID: '1',
                  ID      : '2586'
                }, 1
            );
          }
        },

// Quick search
        {
          element  : 'li.search_form',
          title    : '_{GUIDE_QUICK_SEARCH}_',
          content  : '_{GUIDE_QUICK_SEARCH_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'auto'
        },

//Documentation
        {
          element  : 'li#wiki-link',
          title    : '_{GUIDE_WIKI_LINK}_',
          content  : '_{GUIDE_WIKI_LINK_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom'
        },

//Control-sidebar
        {
          element  : '#control-sidebar-open-btn',
          title    : '_{GUIDE_RIGHT_MENU}_',
          content  : '_{GUIDE_RIGHT_MENU_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShow   : function () {
            jQuery('#control-sidebar-open-btn').on('click', tour.next.bind(tour));
          }
        },

// Quick menu
        {
          element  : '#admin-quick-menu',
          title    : '_{GUIDE_QUICK_MENU}_',
          content  : '_{GUIDE_QUICK_MENU_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShow   : function () {
            if (!jQuery('body').hasClass('control-sidebar-open')) {
              window['\$'].AdminLTE.controlSidebar.open();
            }
          }
        },

// Interface settings btn
        {
          element  : '#admin_setting_btn',
          title    : '_{GUIDE_INTERFACE_SETTINGS_BTN}_',
          content  : '_{GUIDE_INTERFACE_SETTINGS_BTN_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShow   : function () {
            if (!jQuery('body').hasClass('control-sidebar-open')) {
              window['\$'].AdminLTE.controlSidebar.open();
            }
            jQuery('a#admin_setting_btn').on('click', tour.next.bind(tour));
          }
        },

// Interface settings
        {
          element  : '#admin_setting',
          title    : '_{GUIDE_INTERFACE_SETTINGS_MENU}_',
          content  : '_{GUIDE_INTERFACE_SETTINGS_MENU_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShow   : function () {
            if (!jQuery('body').hasClass('control-sidebar-open')) {
              window['\$'].AdminLTE.controlSidebar.open();
            }
            var openBtn = jQuery('a#admin_setting_btn');
            if (!openBtn.parent('li').hasClass('active')) {
              clickButton('admin_setting_btn');
            }
          }
        },
// Back to start page. finish
        {
          title    : '_{GUIDE_WELCOME}_',
          content  : "_{GUIDE_FINISH_TEXT}_",
          orphan : true,
          backdrop : true
        }
      ],
      onEnd : function () {
        jQuery.post("/admin/index.cgi", { tour_ended : 1 });
      }
    });

    // Initialize the tour
    tour.init();

    // Start the tour
    tour.start();
  });
</script>
