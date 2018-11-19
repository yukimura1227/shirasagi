this.SS_SearchUI = (function () {
  function SS_SearchUI(el) {
    this.$el = $(el);
    this.$table = this.$el.find(".ajax-selected");
    this.template = null;

    var self = this;
    this.$table.on("click", "a.deselect", function(e) { return self.deselect(e, $(this)); });
    if (this.itemCount() === 0) {
      this.hideTable();
    } else {
      this.showTable();
    }

    this.$el.find(".ajax-box").data("searchUI", this);
  }

  SS_SearchUI.anchorAjaxBox;
  SS_SearchUI.searchUI;

  SS_SearchUI.clear = function () {
    SS_SearchUI.anchorAjaxBox = null;
    SS_SearchUI.searchUI = null;
  };

  SS_SearchUI.render = function () {
    $(".ajax-select").each(function() {
      new SS_SearchUI(this);
    });

    //
    // set #colorbox event handlers
    //
    $("#colorbox").on("submit", "#ajax-box form.search", function (e) {
      if (SS_SearchUI.searchUI) {
        return SS_SearchUI.searchUI.handleSearchForm(e, $(this));
      }
      return true;
    });
    $("#colorbox").on("click", "#ajax-box .pagination a", function (e) {
      if (SS_SearchUI.searchUI) {
        return SS_SearchUI.searchUI.handleClickPagination(e, $(this));
      }
      return true;
    });
    $("#colorbox").on("change", "#ajax-box .submit-on-change", function (e) {
      if (SS_SearchUI.searchUI) {
        return SS_SearchUI.searchUI.handleSubmitOnChange(e, $(this));
      }
      return true;
    });
    $("#colorbox").on("click", "#ajax-box a.select-item", function (e) {
      if (SS_SearchUI.searchUI) {
        return SS_SearchUI.searchUI.handleSelectItem(e, $(this));
      }
      return true;
    });
    $("#colorbox").on("click", "#ajax-box .select-single-item", function (e) {
      if (SS_SearchUI.searchUI) {
        return SS_SearchUI.searchUI.handleSelectSingleItem(e, $(this));
      }
      return true;
    });
    $("#colorbox").on("click", "#ajax-box .select-items", function (e) {
      if (SS_SearchUI.searchUI) {
        return SS_SearchUI.searchUI.handleSelectItems(e, $(this));
      }
      return true;
    });
    $("#colorbox").on("change", "#ajax-box .index", function (e) {
      if (SS_SearchUI.searchUI) {
        return SS_SearchUI.searchUI.handleChangeIndex(e, $(this));
      }
      return true;
    });
  };

  SS_SearchUI.modal = function (options) {
    if (!$.colorbox.element().hasClass("ajax-box")) {
      return;
    }

    SS_SearchUI.anchorAjaxBox = $.colorbox.element();
    SS_SearchUI.searchUI = SS_SearchUI.anchorAjaxBox.data("searchUI");
    if (! SS_SearchUI.searchUI) {
      var el = SS_SearchUI.anchorAjaxBox.closest(".ajax-select");
      if (el.length > 0) {
        var searchUI = SS_SearchUI.searchUI = new SS_SearchUI(el);
        SS_SearchUI.anchorAjaxBox.data("searchUI", searchUI);
      }
    }
    if (! SS_SearchUI.searchUI) {
      SS_SearchUI.anchorAjaxBox = null;
      throw 'Unsupported modal. you must define <div class=".ajax-select"> as modal root';
    }

    var submit_on_changes;
    if (options && options.submit_on_changes) {
      submit_on_changes = options.submit_on_changes;
    }
    if (!submit_on_changes) {
      submit_on_changes = ["#s_group"];
    }
    for (var i = 0, len = submit_on_changes.length; i < len; i++) {
      var el = submit_on_changes[i];
      $("#ajax-box " + el).on("change", function (e) {
        SS_SearchUI.searchUI.searchForm($(this).closest("form"));
      });
    }
    SS_SearchUI.searchUI.$table.find("tr[data-id]").each(function () {
      var id, item, tr;
      id = $(this).data("id");
      tr = $("#colorbox .items [data-id='" + id + "']");
      tr.find("input[type=checkbox]").remove();
      item = tr.find(".select-item,.select-single-item").html();
      return tr.find(".select-item,.select-single-item").replaceWith("<span class='select-item' style='color: #888'>" + item + "</span>");
    });
    SS_ListUI.render("table.index");
    SS_SearchUI.searchUI.toggleSelectButton();
  };

  SS_SearchUI.prototype.itemCount = function() {
    return this.$table.find("tr[data-id]").size();
  };

  SS_SearchUI.prototype.hideTable = function() {
    this.$table.addClass("hide");
  };

  SS_SearchUI.prototype.showTable = function() {
    this.$table.removeClass("hide");
  };

  SS_SearchUI.prototype.deselect = function (e, $el) {
    $el.closest("tr").remove();
    if (this.itemCount() === 0) {
      this.hideTable();
    }
    this.$el.trigger("change");
    e.preventDefault();
    return false
  };

  SS_SearchUI.prototype.handleSearchForm = function (e, $source) {
    this.searchForm($source);
    e.preventDefault();
    return false;
  };

  SS_SearchUI.prototype.handleClickPagination = function (e) {
    this.selectItems();
    return true;
  };

  SS_SearchUI.prototype.handleSubmitOnChange = function (e) {
    this.selectItems();
    $("#ajax-box form.search").submit();
    return true;
  };

  SS_SearchUI.prototype.handleSelectItem = function (e, $source) {
    if (!SS.disableClick($source)) {
      e.preventDefault();
      return false;
    }

    //append newly selected item
    this.select($source);
    this.showTable();

    $.colorbox.close();

    e.preventDefault();
    return false;
  };

  SS_SearchUI.prototype.handleSelectSingleItem = function (e, $source) {
    if (!SS.disableClick($source)) {
      e.preventDefault();
      return false;
    }
    this.$table.find("tr[data-id]").each(function () {
      if ($source.find("input[value]").length) {
        $source.remove();
        return true;
      }
    });

    //append newly selected item
    this.select($el);
    this.showTable();

    $.colorbox.close();

    e.preventDefault();
    return false;
  };

  SS_SearchUI.prototype.handleSelectItems = function (e, $source) {
    if (!SS.disableClick($source)) {
      e.preventDefault();
      return false;
    }
    this.selectItems();

    $.colorbox.close();

    e.preventDefault();
    return false;
  };

  SS_SearchUI.prototype.handleChangeIndex = function (e) {
    this.toggleSelectButton();
    return true;
  };

  SS_SearchUI.prototype.defaultSelector = function ($item) {
    if (! this.template) {
      this.template = this.$el.find(".ajax-item-template").html();
    }

    var html = this.template;
    var dataEl = $item.closest("[data-id]");
    $.each(dataEl.data(), function(key, value) {
      html = html.replace(new RegExp("#" + key.toString(), "g"), value.toString());
    });
    var name = dataEl.data("name") || dataEl.find(".select-item").text() || item.text() || dataEl.text();
    html = html.replace(/#name/g, name);

    this.$table.find("tbody").prepend(html);
    this.$el.trigger("change");
  };

  SS_SearchUI.prototype.select = function ($item) {
    var selector = this.$el.find(".ajax-box").data('on-select');
    if (! selector) {
      selector = this.$el.data('on-select');
    }
    if (selector) {
      selector($item);
    } else {
      this.defaultSelector($item);
    }
  };

  SS_SearchUI.prototype.selectItems = function () {
    var self = this;
    $("#ajax-box .items input:checkbox").filter(":checked").each(function () {
      self.select($(this));
    });
    this.showTable();
  };

  SS_SearchUI.prototype.toggleSelectButton = function () {
    if ($("#ajax-box .items input:checkbox").filter(":checked").size() > 0) {
      $("#ajax-box .select-items").parent("div").show();
    } else {
      $("#ajax-box .select-items").parent("div").hide();
    }
  };

  SS_SearchUI.prototype.searchForm = function ($form) {
    this.selectItems();
    $form.ajaxSubmit({
      url: $form.attr("action"),
      success: function (data) {
        $("#cboxLoadedContent").html(data);
      },
      error: function (data, status) {
        alert("== Error ==");
      }
    });
  };

  return SS_SearchUI;

})();

