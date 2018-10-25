window.SS_AddonNavi = (function () {
  function SS_AddonNavi() {
    if (SS_AddonNavi.instance) {
      return;
    }

    this.$el = $("#addon-navi");
    this.wellKnownButtonClasses = [
      "btn", "btn-primary", "btn-outline-primary", "btn-secondary", "btn-outline-secondary",
      "btn-default", "btn-outline-default", "btn-success", "btn-outline-success" ];
    this.wellKnownButtonClassMap = {
      "btn-primary": "btn-outline-primary",
      "btn-secondary": "btn-outline-secondary",
      "btn-default": "btn-outline-default",
      "btn-success": "btn-outline-success"
    };

    var renderedNaviMenus = this.renderNaviMenus();
    var renderedNaviButtons = this.renderNaviButtons();
    if (renderedNaviMenus || renderedNaviButtons) {
      this.$el.show();
      this.initFixedScroll();
      this.setNavLinkHandler();
    }

    SS_AddonNavi.instance = this;
  }

  SS_AddonNavi.instance = null;

  SS_AddonNavi.prototype.renderNaviMenus = function() {
    var $nav = this.$el.find(".nav");
    var template = this.$el.find(".menu-template").html();
    var nameCount = 0;
    $(".addon-view").each(function() {
      var $this = $(this);
      var id = $this.attr("id");
      var name = $this.find(".addon-head").text();

      var html = template.replace(/#href/, "#" + id).replace(/#id/, id).replace(/#name/, name);
      $nav.append(html);
      nameCount += 1;
    });

    return nameCount > 0;
  };

  SS_AddonNavi.prototype.renderNaviButtons = function() {
    var self = this;
    var $nav = this.$el.find(".col");
    var buttonCount = 0;
    $("form#item-form footer.send .btn").each(function() {
      var $this = $(this);
      var name = $this.val() || $this.text();
      var isSubmit = false;
      if ($this.attr("type") === "submit") {
        isSubmit = true;
      }

      var cssClasses = $.grep($this.attr("class").split(" "), function(n, i) {
        return $.inArray(n, self.wellKnownButtonClasses) >= 0;
      });
      cssClasses = $.map(cssClasses, function(n, i) {
        return self.wellKnownButtonClassMap[n] || n;
      });

      var buttonType = isSubmit ? "submit" : "button";
      var $button = $("<button />").attr("type", buttonType).attr("class", cssClasses.join(" ")).text(name);
      $button.on("click", function(e) {
        $this.click();

        e.preventDefault();
        return false;
      });

      $nav.append($button);
      $nav.append(" ");
      buttonCount += 1;
    });

    return buttonCount > 0;
  };

  SS_AddonNavi.prototype.initFixedScroll = function() {
    this.$fixElement = this.$el.find('.wrap');
    this.baseFixPoint = this.$fixElement.offset().top;
    this.fixClass = 'is-fixed';

    var self = this;
    $(window).on('load scroll', function () {
      self.fixFunction();
    });
  };

  SS_AddonNavi.prototype.fixFunction = function() {
    var windowScrollTop = $(window).scrollTop();
    if (windowScrollTop >= this.baseFixPoint) {
      this.$fixElement.addClass(this.fixClass);
    } else {
      this.$fixElement.removeClass(this.fixClass);
    }
  };

  SS_AddonNavi.prototype.setNavLinkHandler = function() {
    this.$el.on("click", ".nav-link", function() {
      var target = $(this).data("target");
      var targetElement = $("#" + target)[0];
      if (targetElement) {
        SS_AddonTabs.showWithAnimation(targetElement);
      }
      return true;
    });
  };

  return SS_AddonNavi;
})();
