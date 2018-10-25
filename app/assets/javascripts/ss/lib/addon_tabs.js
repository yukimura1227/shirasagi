this.SS_AddonTabs = (function () {
  function SS_AddonTabs() {
  }

  SS_AddonTabs.render = function () {
    $(document).on('click', '.toggle-head', function() {
      SS_AddonTabs.toggleWithAnimation(this);
    });
  };

  SS_AddonTabs.findAddonView = function (view) {
    var $view = $(view)
    var $addonView;
    if ($view.hasClass("addon-view")) {
      $addonView = $view;
    } else {
      $addonView = $view.closest('.addon-view');
    }

    return $addonView;
  };

  SS_AddonTabs.head = function (content) {
    var $addonView = SS_AddonTabs.findAddonView(content);
    $addonView.find('.addon-head');
  };

  SS_AddonTabs.show = function (view) {
    var $addonView = SS_AddonTabs.findAddonView(view);
    $addonView.find('.toggle-body').show();
    $addonView.removeClass('body-closed');
  };

  SS_AddonTabs.hide = function (view) {
    var $addonView = SS_AddonTabs.findAddonView(view);
    $addonView.find('.toggle-body').hide();
    $addonView.addClass('body-closed');
  };

  SS_AddonTabs.toggleWithAnimation = function (view) {
    var $addonView = SS_AddonTabs.findAddonView(view);
    $addonView.find('.toggle-body').animate({ height: 'toggle' }, 'fast', function() {
      $addonView.toggleClass('body-closed');
    });
  };

  SS_AddonTabs.showWithAnimation = function (view) {
    var $addonView = SS_AddonTabs.findAddonView(view);
    if ($addonView.hasClass("body-closed")) {
      SS_AddonTabs.toggleWithAnimation(view)
    }
  };

  SS_AddonTabs.toggleView = function (view) {
    console.log("SS_AddonTabs.toggleView is deprecated");
    $(view).parent().hide();
  };
  //TODO: depracated

  return SS_AddonTabs;

})();
