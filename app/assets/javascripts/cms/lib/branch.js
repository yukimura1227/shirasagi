window.Cms_Branch = (function () {
  function Cms_Branch(el, options) {
    if (! el) {
      el = "#addon-workflow-agents-addons-branch"
    }
    this.$el = $(el);
    this.options = options;

    var self = this;
    this.$el.find(".create-branch").on("click", function (ev) {
      self.createBranch();

      ev.preventDefault();
      return false;
    });
  }

  Cms_Branch.prototype.createBranch = function() {
    var self = this;
    $.ajax({
      type: "POST",
      url: this.options.path,
      beforeSend: function () {
        self.showLoading();
      },
      success: function (data) {
        self.showResult(data);
      },
      error: function (data, status) {
        self.showError(data);
      }
    });
  };

  Cms_Branch.prototype.showLoading = function() {
    this.$el.find(".result").html(SS.loading).show();
  };

  Cms_Branch.prototype.showResult = function(data) {
    this.$el.find(".result").html(data);
    this.$el.find(".result a").removeClass();

    this.$el.find(".create-branch").parent().html(this.options.message).addClass("text-success");
    this.$el.find(".result").show();

    SS.notice(this.options.message);
  };

  Cms_Branch.prototype.showError = function(data) {
    alert(["== Error =="].concat(data.responseJSON).join("\n"));
  };

  return Cms_Branch;
})();
