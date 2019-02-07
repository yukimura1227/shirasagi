//= require cms/lib/form
//= require cms/lib/template_form

//= require ss/lib/workflow
//= require ss/lib/addon/temp_file
//= require ss/lib/search_ui
//= require ss/lib/list_ui
//= require ss/lib/tree_ui
//= require ss/lib/dropdown

SS_Preview = (function () {
  function SS_Preview(el) {
    this.el = el;
    this.inplaceMode = false;
    this.layouts = [];
    this.parts = [];
  }

  SS_Preview.libs = {
    jquery: { isInstalled: function() { return !!window.jQuery; }, js: null, css: null },
    datetimePicker: { isInstalled: function() { return !!$.datetimepicker; }, js: null, css: null },
    colorbox: { isInstalled: function() { return !!$.colorbox; }, js: null, css: null },
    dialog: { isInstalled: function() { return $.ui && $.ui.dialog; }, js: null, css: null }
  };

  SS_Preview.confirms = { delete: null };

  SS_Preview.notices = { deleted: null };

  SS_Preview.item = {};

  SS_Preview.preview_path = "";

  SS_Preview.mobile_path = "/mobile";

  SS_Preview.request_path = null;

  SS_Preview.form_item = null;

  SS_Preview.overlayPadding = 5;
  SS_Preview.previewToolHeight = 70;

  SS_Preview.inplaceFormPath = { page: null, columnValue: {}, palette: null };

  SS_Preview.workflowPath = { wizard: null, pages: null };

  SS_Preview.redirectorPath = { newPage: null };

  SS_Preview.instance = null;

  SS_Preview.minFrameSize = { width: 320, height: 150 };
  SS_Preview.initialFrameSize = { width: 780, height: 180 };

  SS_Preview.render = function (opts) {
    if (SS_Preview.instance) {
      return;
    }

    SS_Preview.instance = new SS_Preview("#ss-preview");

    SS_Preview.loadJQuery(function() {
      $.when(
        SS_Preview.lazyLoad(SS_Preview.libs.datetimePicker),
        SS_Preview.lazyLoad(SS_Preview.libs.colorbox),
        SS_Preview.lazyLoad(SS_Preview.libs.dialog)
      ).done(function () {
        SS_Preview.instance.initialize(opts);
      });
    });
  };

  SS_Preview.loadJQuery = function (callback) {
    if (window.jQuery) {
      callback();
      return;
    }

    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = SS_Preview.libs.jquery.css;

    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = SS_Preview.libs.jquery.js;

    if (script.readyState) {
      // IE
    } else {
      script.onload = function () {
        callback();
      }
    }

    document.getElementsByTagName("head")[0].appendChild(link);
    document.getElementsByTagName("head")[0].appendChild(script);
  };

  SS_Preview.lazyLoad = function (data) {
    var d = new $.Deferred;

    if (data.isInstalled()) {
      d.resolve();
      return d.promise();
    }

    var link;
    if (data.css) {
      link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = data.css;
    }

    var script;
    if (data.js) {
      script = document.createElement("script");
      script.type = "text/javascript";
      script.src = data.js;
    }

    if (link) {
      document.getElementsByTagName("head")[0].appendChild(link);
    }

    if (script) {
      if (script.readyState) {
        // IE
        d.resolve();
      } else {
        script.onload = function () {
          d.resolve();
        }
      }

      document.getElementsByTagName("head")[0].appendChild(script);
    } else {
      d.resolve();
    }

    return d.promise();
  };

  SS_Preview.notice = function (message) {
    if (!SS_Preview.instance) {
      return;
    }
    if (!SS_Preview.instance.notice) {
      return;
    }

    SS_Preview.instance.notice.show(message);
  };

  SS_Preview.bindToWorkflowCommentForm = function (updateType) {
    if (!SS_Preview.instance) {
      return;
    }

    SS_Preview.instance.bindToWorkflowCommentForm(updateType);
  };

  SS_Preview.prototype.initialize = function(opts) {
    this.$el = $(this.el);
    this.$datePicker = this.$el.find(".ss-preview-date");
    this.$datePicker.datetimepicker({
      lang: "ja",
      roundTime: "ceil",
      step: 30,
      closeOnDateSelect: true
    });

    var self = this;

    this.initializePart();
    this.initializeLayout();
    this.initializePage();
    this.initializeColumn();

    // initialize overlay;
    this.overlay = new Overlay(this);
    this.overlay.on("part:edit", function(ev, data) {
      self.openPartEdit(data.id);
    });
    this.overlay.on("page:edit", function(ev, data) {
      self.openPageEdit(data.id);
    });
    this.overlay.on("column:edit", function(ev, data) {
      self.openColumnEdit(data.id);
    });
    this.overlay.on("column:delete", function(ev, data) {
      self.postColumnDelete(data.id);
    });
    this.overlay.on("column:moveUp", function(ev, data) {
      self.postColumnMoveUp(data.id);
    });
    this.overlay.on("column:moveDown", function(ev, data) {
      self.postColumnMoveDown(data.id);
    });
    this.overlay.on("column:movePosition", function(ev, data, order) {
      self.postColumnMovePosition(data.id, order);
    });

    var formEnd = $("#ss-preview-form-end");
    if (formEnd[0]) {
      this.formPalette = FormPalette.createBefore(this, formEnd[0]);
    }

    this.$el.on("click", ".ss-preview-btn-toggle-inplace", function () {
      self.toggleInplaceMode();

      if (self.inplaceMode) {
        if (window.history.pushState) {
          window.history.pushState(null, null, window.location.pathname + "#inplace");
        } else {
          window.location.hash = "#inplace";
        }
      } else {
        if (window.history.pushState) {
          window.history.pushState(null, null, window.location.pathname);
        } else {
          window.location.hash = "";
        }
      }
    });

    $(document).on("click", ".ss-preview-btn-open-path", function () {
      var path = $(this).data("path");
      if (path) {
        window.open(path, "_blank")
      }
    });

    var $selectNodeBtn = this.$el.find("#ss-preview-btn-select-node");
    $selectNodeBtn.colorbox({ iframe: true, fixed: true, width: "90%", height: "90%" })
      .data("on-select", function($item) {
        var $dataEl = $item.closest("[data-id]");
        var id = $dataEl.data("id");
        var name = $dataEl.find(".name").text();

        var $nodeDataEl = $selectNodeBtn.closest("[data-node-id]");
        SS_Preview.setData($nodeDataEl, "node-id", id);
        $nodeDataEl.find("label").html(name);
      });

    this.$el.find("#ss-preview-btn-create-new-page").on("click", function() {
      var $nodeDataEl = $selectNodeBtn.closest("[data-node-id]");
      var nodeId = $nodeDataEl.data("node-id");

      window.open(SS_Preview.redirectorPath.newPage.replace(":nodeId", nodeId));
    });

    this.$el.find("#ss-preview-btn-select-draft-page")
      .colorbox({ iframe: true, fixed: true, width: "90%", height: "90%" })
      .data("on-select", function($item) {
        var $dataEl = $item.closest("[data-id]");
        var filename = $dataEl.find(".filename").text();

        var url = SS_Preview.previewPath.replace(":path", filename);
        if (self.inplaceMode) {
          url += "#inplace";
        }
        window.location.href = url;
      });

    this.$el.on("click", ".ss-preview-btn-pc", function () {
      self.previewPc();
    });

    this.$el.on("click", ".ss-preview-btn-mobile", function () {
      self.previewMobile();
    });

    if (SS_Preview.request_path) {
      $('body a [href="#"]').val("onclick", "return false;");
    }

    if (window.history.pushState) {
      // history api is available
      window.addEventListener("popstate", function() {
        if (window.location.hash === "#inplace") {
          self.startInplaceMode();
        } else {
          self.stopInplaceMode();
        }
      });
    }

    if (window.location.hash === "#inplace") {
      this.startInplaceMode();
    }

    // initialize notice;
    this.notice = new Notice(this);
    if (opts.notice) {
      this.notice.show(opts.notice);
    }
  };

  SS_Preview.prototype.initializeLayout = function() {
    var $body = $("body");
    if ($body.data("layout-id")) {
      this.layouts = [{
        id: $body.data("layout-id"), name: $body.data("layout-name"),
        filename: $body.data("layout-filename"), path: $body.data("layout-path")
      }];
    }

    var button = this.$el.find(".ss-preview-btn-edit-layout");
    if (! this.layouts || this.layouts.length === 0) {
      button.closest(".ss-preview-btn-group").addClass("ss-preview-hide");
      return;
    }

    button.closest(".ss-preview-btn-group").removeClass("ss-preview-hide");

    var path = this.layouts[0].path;
    button.on('click', function() {
      window.open(path, '_blank');
    });
  };

  SS_Preview.prototype.initializePage = function() {
    var self = this;
    $(document).on("mouseover", ".ss-preview-page", function() {
      if (self.inplaceMode) {
        self.overlay.showForPage($(this));
      }
    });
  };

  SS_Preview.prototype.adjustDialogSize = function(frame) {
    var width = frame.contentWindow.document.body.scrollWidth;
    var height = frame.contentWindow.document.body.scrollHeight;

    if (width < SS_Preview.initialFrameSize.width) {
      width = SS_Preview.initialFrameSize.width;
    }
    if (height < SS_Preview.initialFrameSize.height) {
      height = SS_Preview.initialFrameSize.height;
    }

    var maxWidth = Math.floor(window.innerWidth * 0.9);
    var maxHeight = Math.floor(window.innerHeight * 0.9);

    if (width > maxWidth) {
      width = maxWidth;
    }
    if (height > maxHeight) {
      height = maxHeight;
    }

    if ($(frame).closest("#cboxLoadedContent")[0]) {
      $.colorbox.resize({ width: width, height: height });
    }

    if ($(frame).closest(".ui-dialog")[0]) {
      $(frame).dialog("option", "width", width).dialog("option", "height", height).css("display", "").css("width", "");
    }
  };

  SS_Preview.prototype.initializeFrame = function(frame) {
    var itemForm = frame.contentWindow.document.querySelector("#item-form");
    if (! itemForm) {
      // iframe is not loaded completely
      return;
    }

    this.adjustDialogSize(frame);

    var self = this;
    self.saveIfNoAlerts = false;
    self.ignoreAlertsAndSave = false;

    itemForm.addEventListener("click", function(ev) {
      var el = ev.target;

      if (el.tagName === "BUTTON" && el.classList.contains("btn-cancel")) {
        if ($(frame).closest("#cboxLoadedContent")[0]) {
          $.colorbox.close();
        }
        if ($(frame).closest(".ui-dialog")[0]) {
          $(frame).dialog("close");
        }
      }

      if (el.tagName === "INPUT" && el.name === "save_if_no_alerts") {
        self.saveIfNoAlerts = true;
      }

      if (el.tagName === "INPUT" && el.name === "ignore_alerts_and_save") {
        self.ignoreAlertsAndSave = true;
      }

      return true;
    });
    itemForm.onsubmit = function(ev) {
      var formData = frame.contentWindow.Cms_Form.getFormData(frame.contentWindow.$(itemForm), { preserveMethod: true });
      if (self.saveIfNoAlerts) {
        formData.append("save_if_no_alerts", "button");
      }
      if (self.ignoreAlertsAndSave) {
        formData.append("ignore_alerts_and_save", "button");
      }

      var action = itemForm.getAttribute("action");
      var method = itemForm.getAttribute("method") || "POST";
      $.ajax({
        url: action,
        type: method,
        data: formData,
        processData: false,
        contentType: false,
        cache: false,
        success: function(data, textStatus, xhr) {
          $.colorbox.close();
          if (typeof data === "string") {
            // data is html
            location.reload();
          } else {
            // data is json
            if (data && data.location) {
              location.href = data.location;
            } else {
              location.reload();
            }
          }
        },
        error: function(xhr, status, error) {
          var $html = $(xhr.responseText);
          var $itemForm = $html.find("#item-form");

          itemForm.innerHTML = $itemForm.html();
          self.adjustDialogSize(frame);
        }
      });

      self.saveIfNoAlerts = false;
      self.ignoreAlertsAndSave = false;

      ev.preventDefault();
      return false;
    };


    if (frame.contentWindow.CKEDITOR) {
      frame.contentWindow.CKEDITOR.on("instanceReady", function (ev) {
        self.adjustRichEditorHeight(ev.editor);
      });
    }
  };

  // SS_Preview.prototype.openDialogInFrame = function(url) {
  //   var self = this;
  //
  //   // open edit form in iframe
  //   $.colorbox({
  //     href: url,
  //     iframe: true,
  //     fixed: true,
  //     width: SS_Preview.initialFrameSize.width,
  //     height: SS_Preview.initialFrameSize.height,
  //     opacity: 0.15,
  //     overlayClose: false,
  //     escKey: false,
  //     arrowKey: false,
  //     closeButton: false,
  //     onComplete: function() {
  //       var frame = $("#cboxLoadedContent iframe")[0];
  //       frame.onload = function() {
  //         self.initializeFrame(frame);
  //       };
  //     }
  //   });
  // };
  SS_Preview.prototype.openDialogInFrame = function(url) {
    var self = this;

    var $frame = $("<iframe></iframe>", {
      id: "ss-preview-dialog-frame",
      frameborder: "0", allowfullscreen: true,
      src: url
    });

    $frame[0].onload = function() { self.initializeFrame($frame[0]); };

    $frame.dialog({
      autoOpen: true,
      width: SS_Preview.initialFrameSize.width,
      height: SS_Preview.initialFrameSize.height,
      minWidth: SS_Preview.minFrameSize.width,
      minHeight: SS_Preview.minFrameSize.height,
      closeOnEscape: false,
      dialogClass: "ss-preview-dialog ss-preview-dialog-column",
      draggable: true,
      modal: true,
      resizable: true,
      close: function(ev, ui) {
        // explicitly destroy dialog and remove elemtns because dialog elements is still remained
        $(this).dialog('destroy').remove();
      }
    });
  };

  SS_Preview.prototype.openDialog = function(url) {
    var self = this;

    $.ajax({
      url: url,
      type: "GET",
      success: function(data, textStatus, xhr) {
        var $frame = $("div#ss-preview-dialog-frame");
        if (! $frame[0]) {
          $frame = $("<div></div>", { id: "ss-preview-dialog-frame" });
        }
        $frame.html(data);
        $frame.dialog({
          autoOpen: true,
          width: SS_Preview.initialFrameSize.width,
          height: SS_Preview.initialFrameSize.height,
          minWidth: SS_Preview.minFrameSize.width,
          minHeight: SS_Preview.minFrameSize.height,
          closeOnEscape: false,
          dialogClass: "ss-preview-dialog ss-preview-dialog-column",
          draggable: true,
          modal: true,
          resizable: true,
          close: function(ev, ui) {
            // explicitly destroy dialog and remove elemtns because dialog elements is still remained
            $(this).dialog('destroy').remove();
          }
        });
      },
      error: function(xhr, status, error) {
        self.notice.show(error);
      }
    })
  };

  SS_Preview.prototype.adjustRichEditorHeight = function(editor) {
    if (editor.status !== "ready") {
      return;
    }

    var $el = $(editor.element.$);
    var $parent = $el.parent();
    var height = $parent.height();

    height = height - 40;
    if (height < 50) {
      height = 50;
    }

    editor.resize("100%", height.toString());
  };

  SS_Preview.prototype.openPageEdit = function(pageId) {
    // open page(body) edit form in iframe
    var url = SS_Preview.inplaceFormPath.page.replace(":id", pageId);
    this.openDialogInFrame(url);
  };

  SS_Preview.prototype.initializePart = function() {
    var self = this;
    this.parts = [];
    $(document).find(".ss-preview-part").each(function() {
      var $this = $(this);
      if (! $this.data("part-id")) {
        return;
      }
      self.parts.push({
        el: $this, id: $this.data("part-id"), name: $this.data("part-name"),
        filename: $this.data("part-filename"), path: $this.data("part-path")
      });
    });


    if (!this.parts || this.parts.length === 0) {
      this.$el.find(".ss-preview-part-group").addClass("ss-preview-hide");
      return;
    }

    var list = this.$el.find(".ss-preview-part-list");
    var options = list.html();
    $.each(this.parts, function(index, item) {
      options += "<option value=\"" + item.id + "\">" + item.name + "</option>"
    });

    list.html(options).on('change', function() {
      self.changePart($(this));
    });

    this.$el.on("click", ".ss-preview-btn-edit-part", function() {
      self.openPartEdit(list.val());
    });

    this.$el.on("click", "#ss-preview-btn-workflow-start", function() {
      self.openWorkflowApprove();
    });

    this.$el.on("click", "#ss-preview-btn-workflow-approve", function() {
      self.openWorkflowComment("approve");
    });
    this.$el.on("click", "#ss-preview-btn-workflow-remand", function() {
      self.openWorkflowComment("remand");
    });
    this.$el.on("click", "#ss-preview-btn-workflow-pull-up", function() {
      self.openWorkflowComment("pull-up");
    });

    this.$el.find(".ss-preview-part-group").removeClass("ss-preview-hide");

    $(document).on("mouseover", ".ss-preview-part", function() {
      if (self.inplaceMode) {
        self.overlay.showForPart($(this));
      }
    });
  };

  SS_Preview.prototype.findPartById = function(partId) {
    if (! partId) {
      return null;
    }

    if ($.type(partId) === "string") {
      partId = parseInt(partId);
    }

    var founds = $.grep(this.parts, function(part, index) { return part.id === partId });
    if (! founds || founds.length === 0) {
      return null;
    }

    return founds[0];
  };

  SS_Preview.prototype.initializeColumn = function() {
    var self = this;
    $(document).on("mouseover", ".ss-preview-column", function() {
      if (self.inplaceMode) {
        self.overlay.showForColumn($(this));
      }
    });
  };

  SS_Preview.prototype.openColumnEdit = function(ids) {
    // open column edit form in iframe
    var url = SS_Preview.inplaceFormPath.columnValue.edit.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    this.openDialogInFrame(url);
  };

  SS_Preview.prototype.postColumnDelete = function(ids) {
    if (! confirm(SS_Preview.confirms.delete)) {
      return;
    }

    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.destroy.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { _method: "DELETE", authenticity_token: token },
      success: function(data, textStatus, xhr) {
        self.overlay.hide();

        if (data && data.location) {
          location.href = data.location;
        } else {
          var $column = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
          $column.fadeOut("fast", function () {
            $column.remove();
            self.notice.show("削除しました。");
          });
        }
      },
      error: function(xhr, status, error) {
        self.notice.show(error);
      }
    });
  };

  SS_Preview.prototype.postColumnMoveUp = function(ids) {
    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.moveUp.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { authenticity_token: token },
      success: function(data, textStatus, xhr) {
        self.overlay.hide();

        if (data.location) {
          location.href = data.location;
        } else {
          self.finishColumnMoveUp(ids, data);
          self.notice.show("移動しました。");
        }
      },
      error: function(xhr, status, error) {
        self.notice.show(error);
      }
    });
  };

  SS_Preview.camelize = function(str) {
    return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function(letter, index) {
      return index == 0 ? letter.toLowerCase() : letter.toUpperCase();
    }).replace(/[\s-]+/g, '');
  };

  SS_Preview.setData = function($el, name, value) {
    $el.data(name, value);

    var camelizedName = SS_Preview.camelize(name);
    $el.each(function() {
      this.dataset[camelizedName] = value;
    });
  };

  SS_Preview.prototype.finishColumnMoveUp = function(ids, data) {
    this.overlay.hide();

    var $target = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
    if (!$target[0]) {
      return;
    }
    var $prev = $target.prev(".ss-preview-column[data-page-id='" + ids.pageId + "']");
    if (!$prev[0]) {
      return;
    }

    Cms_TemplateForm.swapElement($prev, $target, function() {
      SS_Preview.setData($prev, "column-order", data[$prev.data("column-id")]);
      SS_Preview.setData($target, "column-order", data[$target.data("column-id")]);
      $target.after($prev);
    });
  };

  SS_Preview.prototype.postColumnMoveDown = function(ids) {
    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.moveDown.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { authenticity_token: token },
      success: function(data) {
        self.overlay.hide();

        if (data.location) {
          location.href = data.location;
        } else {
          self.finishColumnMoveDown(ids, data);
          self.notice.show("移動しました。");
        }
      },
      error: function(xhr, status, error) {
        self.notice.show(error);
      }
    });
  };

  SS_Preview.prototype.finishColumnMoveDown = function(ids, data) {
    this.overlay.hide();

    var $target = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
    if (!$target[0]) {
      return;
    }

    var $next = $target.next(".ss-preview-column[data-page-id='" + ids.pageId + "']");
    if (!$next[0]) {
      return;
    }

    Cms_TemplateForm.swapElement($target, $next, function() {
      SS_Preview.setData($next, "column-order", data[$next.data("column-id")]);
      SS_Preview.setData($target, "column-order", data[$target.data("column-id")]);
      $target.before($next);
    });
  };

  SS_Preview.prototype.postColumnMovePosition = function(ids, order) {
    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.moveAt.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { authenticity_token: token, order: order },
      success: function(data) {
        self.finishColumnMovePosition(ids, order, data);
      },
      error: function(xhr, status, error) {
        self.notice.show(error);
      }
    });
  };

  SS_Preview.prototype.finishColumnMovePosition = function(ids, order, data) {
    this.overlay.hide();

    var $source = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
    if (!$source[0]) {
      return;
    }
    var sourceOrder = $source.data("column-order");

    var $destination = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-order='" + order + "']");
    if (!$destination[0]) {
      return;
    }

    Cms_TemplateForm.insertElement($source, $destination, function() {
      $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "']").each(function() {
        var $this = $(this);
        SS_Preview.setData($this, "column-order", data[$this.data("column-id")]);
      });
      if (order < sourceOrder) {
        $destination.before($source);
      } else {
        $destination.after($source);
      }
    });
  };

  SS_Preview.prototype.previewPc = function() {
    var date = this.dateForPreview();
    if (! date) {
      return;
    }

    var path = SS_Preview.request_path || location.pathname;
    path = path.replace(RegExp("\\/preview\\d*(" + SS_Preview.mobile_path + "|" + SS_Preview.preview_path + ")?"), "/preview" + date + SS_Preview.preview_path) + location.search;
    if (SS_Preview.request_path) {
      this.submitFormPreview(path, SS_Preview.form_item);
    } else {
      location.href = path;
    }
  };

  SS_Preview.prototype.previewMobile = function() {
    var date = this.dateForPreview();
    if (! date) {
      return;
    }

    var path = SS_Preview.request_path || location.pathname;
    path = path.replace(RegExp("\\/preview\\d*(" + SS_Preview.mobile_path + "|" + SS_Preview.preview_path + ")?"), "/preview" + date + SS_Preview.mobile_path) + location.search;
    if (SS_Preview.request_path) {
      this.submitFormPreview(path, SS_Preview.form_item);
    } else {
      location.href = path;
    }
  };

  SS_Preview.prototype.dateForPreview = function() {
    var date = this.$datePicker.val();
    if (!date) {
      return;
    }
    return date.replace(/[^\d]/g, "");
  };

  SS_Preview.prototype.submitFormPreview = function (path, form_item) {
    var token = $('meta[name="csrf-token"]').attr('content');
    var form = $("<form>").attr("method", "post").attr("action", path);

    SS_Preview.appendParams(form, "preview_item", form_item);
    form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden"}));
    form.appendTo("body");
    form.submit();
  };

  SS_Preview.prototype.changePart = function($el) {
    var part = this.findPartById($el.val());
    if (! part) {
      this.overlay.hide();
      return;
    }

    // this.showOverlayForPart(part.el);
    this.overlay.showForPart(part.el);
    this.scrollToPart(part.el);
  };

  SS_Preview.prototype.scrollToPart = function($part) {
    var offset = $part.offset();
    var scrollTop = offset.top - SS_Preview.previewToolHeight;
    if (scrollTop < 0) {
      scrollTop = 0;
    }

    window.scrollTo({ top: scrollTop, behavior: "smooth" });
  };

  SS_Preview.prototype.openPartEdit = function(partId) {
    var part = this.findPartById(partId);
    if (! part) {
      return;
    }

    window.open(part.path, "_blank");
  };

  //
  // Workflow Approve
  //

  SS_Preview.prototype.openWorkflowApprove = function() {
    var url = SS_Preview.workflowPath.wizard.replace(":id", SS_Preview.item.pageId) + "/frame";
    this.openDialog(url);
  };

  SS_Preview.prototype.openWorkflowComment = function(updateType) {
    var url = SS_Preview.workflowPath.wizard.replace(":id", SS_Preview.item.pageId) + "/comment?update_type=" + updateType;
    this.openDialog(url);
  };

  SS_Preview.prototype.bindToWorkflowCommentForm = function(updateType) {
    var $frame = $("#ss-preview-dialog-frame");
    $frame.on("click", "input[type=submit]", function() {
      var remandComment = $frame.find("textarea[name=comment]").prop("value");
      var action = updateType + "_update";
      var url = SS_Preview.workflowPath.pages.replace(":id", SS_Preview.item.pageId);
      url += "/" + action;

      $frame.dialog("close");

      $.ajax({
        type: "POST",
        url: url,
        data: {
          remand_comment: remandComment,
          url: SS_Preview.request_path,
          forced_update_option: true
        },
        success: function (data) {
          if (data.workflow_alert) {
            self.notice.show(data.workflow_alert);
            return;
          }

          if (data.redirect.reload) {
            location.reload();
            return;
          }

          if (data.redirect.url) {
            location.href = SS_Preview.previewPath.replace(":path", data.redirect.url.slice(1));
            return;
          }

          location.reload();
        },
        error: function(xhr, status) {
          try {
            var errors = $.parseJSON(xhr.responseText);
            var msg = ["== Error =="].concat(errors).join("\n");
            self.notice.show(msg);
          }
          catch (ex) {
            var msg = ["== Error =="].concat(xhr["statusText"]).join("\n");
            self.notice.show(msg);
          }
        }
      });
    });
    $frame.on("click", "button[type=reset]", function() {
      $frame.dialog("close");
    });
  };

  //
  // Inplace Edit
  //

  SS_Preview.prototype.toggleInplaceMode = function() {
    if (this.inplaceMode) {
      this.stopInplaceMode();
    } else {
      this.startInplaceMode();
    }
  };

  SS_Preview.prototype.startInplaceMode = function() {
    var button = this.$el.find(".ss-preview-btn-toggle-inplace");

    this.inplaceMode = true;
    button.addClass("ss-preview-active");
    $("#ss-preview-notice").addClass("ss-preview-hide");
    if (this.formPalette) {
      this.formPalette.show();
    }

    $("a[href]").each(function() {
      var $a = $(this);
      var href = $a.attr("href");
      if (!href) {
        return;
      }
      if (!href.startsWith("/")) {
        return;
      }
      if (href.includes("#")) {
        return;
      }

      $a.attr("href", href + "#inplace");
    });
  };

  SS_Preview.prototype.stopInplaceMode = function() {
    var button = this.$el.find(".ss-preview-btn-toggle-inplace");

    this.inplaceMode = false;
    button.removeClass("ss-preview-active");
    this.overlay.hide();
    if (this.formPalette) {
      this.formPalette.hide();
    }

    $("a[href]").each(function() {
      var $a = $(this);
      var href = $a.attr("href");
      if (!href) {
        return;
      }
      if (!href.startsWith("/")) {
        return;
      }

      $a.attr("href", href.replace("#inplace", ""));
    });
  };

  //
  //
  //

  SS_Preview.prototype.showError = function(errorJson) {
    var messages = [];
    $.each(errorJson, function() {
      messages.push("<li>" + this + "</li>");
    });

    $("#ss-preview-error-explanation ul").html(messages.join());
    $("#ss-preview-error-explanation").removeClass("ss-preview-hide");
    $("#ss-preview-messages").removeClass("ss-preview-hide");
  };

  SS_Preview.prototype.clearError = function() {
    $("#ss-preview-error-explanation ul").html("");
    $("#ss-preview-error-explanation").addClass("ss-preview-hide");
    $("#ss-preview-messages").addClass("ss-preview-hide");
  };

  SS_Preview.appendParams = function (form, name, params) {
    var k, results, v;
    if (params.length <= 0) {
      form.append($("<input/>", {
        name: name + "[]",
        value: "",
        type: "hidden"
      }));
    }
    results = [];
    for (k in params) {
      v = params[k];
      if (k.match(/^\d+$/)) {
        k = "";
      }
      if (typeof v === 'object') {
        results.push(SS_Preview.appendParams(form, name + "[" + k + "]", v));
      } else {
        results.push(form.append($("<input/>", {
          name: name + "[" + k + "]",
          value: v,
          type: "hidden"
        })));
      }
    }
    return results;
  };

  //
  // Overlay
  //

  function Overlay(container) {
    this.container = container;
    this.$overlay = $("#ss-preview-overlay");

    this.initPosition();

    var self = this;
    this.$overlay.on("click", ".ss-preview-overlay-btn-edit", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":edit";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("click", ".ss-preview-overlay-btn-delete", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":delete";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("click", ".ss-preview-overlay-btn-move-up", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":moveUp";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("click", ".ss-preview-overlay-btn-move-down", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":moveDown";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("change", ".ss-preview-overlay-btn-move-position", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":movePosition";
      var order = parseInt($(this).val(), 10);
      self.$overlay.trigger(eventType, [ self.$overlay.data(), order ]);
    });

    $(document).on('click', function(e) {
      if (! $(e.target).closest('#ss-preview-overlay').length) {
        self.hide();
      }
    });

    // delegates
    this.on = this.$overlay.on.bind(this.$overlay);
    this.off = this.$overlay.off.bind(this.$overlay);
  }

  Overlay.prototype.initPosition = function() {
    var select = this.$overlay.find(".ss-preview-overlay-btn-move-position");
    if (select[0]) {
      var html = [];
      $(document).find(".ss-preview-column[data-column-order]").each(function () {
        var order = parseInt(this.dataset.columnOrder, 10);
        html.push("<option value=\"" + order + "\">" + (order + 1) + "</option>");
      });

      select.html(html.join(""));
    }
  };

  Overlay.prototype.hide = function() {
    this.$overlay.addClass("ss-preview-hide");
  };

  Overlay.prototype.showForPage = function($page) {
    var rect = $page[0].getBoundingClientRect();
    if (! rect) {
      return;
    }

    this.moveTo(rect);
    this.setInfo({ mode: "page", id: $page.data("page-id"), name: null });

    this.$overlay.find(".ss-preview-overlay-btn-group-move").addClass("ss-preview-hide");
    this.$overlay.find(".ss-preview-overlay-btn-group-delete").addClass("ss-preview-hide");

    this.$overlay.removeClass("ss-preview-hide");
  };

  Overlay.prototype.showForColumn = function($column) {
    var rect = $column[0].getBoundingClientRect();
    if (! rect) {
      return;
    }

    this.moveTo(rect);
    this.setInfo({ mode: "column", id: { pageId: $column.data("page-id"), columnId: $column.data("column-id") }, name: $column.data("column-name") });

    if (SS_Preview.item.formSubType === "entry") {
      this.$overlay.find(".ss-preview-overlay-btn-group-move").removeClass("ss-preview-hide");
      this.$overlay.find(".ss-preview-overlay-btn-group-delete").removeClass("ss-preview-hide");

      var select = this.$overlay.find(".ss-preview-overlay-btn-move-position");
      select.val($column.data("column-order"));
    } else {
      this.$overlay.find(".ss-preview-overlay-btn-group-move").addClass("ss-preview-hide");
      this.$overlay.find(".ss-preview-overlay-btn-group-delete").addClass("ss-preview-hide");
    }

    this.$overlay.removeClass("ss-preview-hide");
  };

  Overlay.prototype.showForPart = function($part) {
    var part = this.container.findPartById($part.data("part-id"));
    if (! part) {
      return;
    }

    var rect = $part[0].getBoundingClientRect();
    if (! rect) {
      return;
    }

    this.moveTo(rect);
    this.setInfo({ mode: "part", id: part.id, name: part.name });

    this.$overlay.find(".ss-preview-overlay-btn-group-move").addClass("ss-preview-hide");
    this.$overlay.find(".ss-preview-overlay-btn-group-delete").addClass("ss-preview-hide");

    this.$overlay.removeClass("ss-preview-hide");
  };

  Overlay.prototype.moveTo = function(rect) {
    var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    var scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
    var top = Math.floor(rect.top + scrollTop) - SS_Preview.overlayPadding;
    var left = Math.floor(rect.left + scrollLeft) - SS_Preview.overlayPadding;
    var width = rect.width + SS_Preview.overlayPadding * 2;
    var height = rect.height + SS_Preview.overlayPadding * 2;

    this.$overlay[0].style.top = top + "px";
    this.$overlay[0].style.left = left + "px";
    this.$overlay[0].style.width = width + "px";
    this.$overlay[0].style.height = height + "px";
  };

  Overlay.prototype.setInfo = function(info) {
    SS_Preview.setData(this.$overlay, "mode", info.mode);
    SS_Preview.setData(this.$overlay, "id", info.id);

    if (info.name) {
      this.$overlay.find(".ss-preview-overlay-name").text(info.name).removeClass("ss-preview-hide");
    } else {
      this.$overlay.find(".ss-preview-overlay-name").text("").addClass("ss-preview-hide");
    }
  };

  //
  // FormPalette
  //

  function FormPalette(container, $el) {
    this.container = container;
    this.$el = $el;

    var self = this;
    this.$el.on("load", function() {
      self.initializeFrame();
    });
  }

  FormPalette.margin = { height: 20 };

  FormPalette.createBefore = function(container, elBefore) {
    var formId = elBefore.dataset.formId;
    if (! formId) {
      return null;
    }
    var subType = elBefore.dataset.formSubType;
    if (subType !== "entry") {
      return null;
    }

    var $frame = $("<iframe />", {
      id: "ss-preview-form-palette", class: "ss-preview-hide", frameborder: "0", scrolling: "no",
      src: SS_Preview.inplaceFormPath.palette.replace(":id", formId)
    });

    $(elBefore).before($frame);

    return new FormPalette(container, $frame);
  };

  FormPalette.prototype.initializeFrame = function() {
    this.adjustHeight();

    var frame = this.$el[0];
    var self = this;
    frame.contentWindow.addEventListener("resize", function () {
      self.delayAdjustHeight();
    });
    frame.contentWindow.document.addEventListener("click", function (ev) {
      var el = ev.target;
      if (el.tagName === "BUTTON" && el.dataset.formId && el.dataset.columnId) {
        self.clickPalette(el);
        return;
      }

      var button = $(el).closest("button[data-form-id]")[0];
      if (button && button.dataset.formId && button.dataset.columnId) {
        self.clickPalette(button);
        return;
      }
    });
  };

  FormPalette.prototype.delayAdjustHeight = function() {
    if (this.timer > 0) {
      clearTimeout(this.timer);
    }

    var self = this;
    this.timer = setTimeout(function () { self.adjustHeight(); self.timer = 0; }, 100);
  };

  FormPalette.prototype.adjustHeight = function() {
    var frame = this.$el[0];
    if (! frame) {
      return;
    }

    var height = frame.contentWindow.document.body.scrollHeight + FormPalette.margin;
    frame.style.height = height + "px";
  };

  FormPalette.prototype.show = function() {
    this.$el.removeClass("ss-preview-hide");
    this.delayAdjustHeight();
  };

  FormPalette.prototype.hide = function() {
    this.$el.addClass("ss-preview-hide");
  };

  FormPalette.prototype.clickPalette = function(el) {
    var formId = el.dataset.formId;
    var columnId = el.dataset.columnId;
    if (!formId || !columnId) {
      return;
    }

    var url = SS_Preview.inplaceFormPath.columnValue.new.replace(":pageId", SS_Preview.item.pageId).replace(":columnId", columnId);
    this.container.openDialogInFrame(url);
  };

  //
  // Notice
  //

  function Notice(container) {
    this.container = container;
    this.$el = this.container.$el.find(".ss-preview-notice-wrap");
    this.timerId = null;
  }

  Notice.speed = "normal";
  Notice.holdInMillis = 1800;

  Notice.prototype.show = function(message) {
    this.hide();

    var self = this;
    this.$el.html(message).slideDown(Notice.speed, function() {
      self.noticeShown();
    });
  };

  Notice.prototype.hide = function() {
    if (this.timerId) {
      clearTimeout(this.timerId);
      this.timerId = null;
    }

    this.$el.hide();
    this.$el.html("");
  };

  Notice.prototype.noticeShown = function() {
    var self = this;
    this.timerId = setTimeout(function () {
      self.$el.slideUp(Notice.speed);
      self.timerId = null;
    }, Notice.holdInMillis);
  };

  return SS_Preview;

})();
