Cms_TemplateForm = function(options) {
  this.options = options;
  this.$formChangeBtn = $('#addon-basic .btn-form-change');
  this.$formSelect = $('#addon-basic select[name="item[form_id]"]');
  this.$formPage = $('#addon-cms-agents-addons-form-page');
  this.$formPageBody = this.$formPage.find('.addon-body');
  this.selectedFormId = null;
};

Cms_TemplateForm.instance = null;

Cms_TemplateForm.render = function(options) {
  if (Cms_TemplateForm.instance) {
    return;
  }

  var instance = new Cms_TemplateForm(options);
  instance.render();
  Cms_TemplateForm.instance = instance;
};

Cms_TemplateForm.prototype = {
  render: function() {
    this.changeForm();

    var pThis = this;
    this.$formChangeBtn.on('click', function() {
      pThis.changeForm();
    });
  },
  changeForm: function() {
    var formId = this.$formSelect.val();
    if (formId) {
      if (!this.selectedFormId || this.selectedFormId !== formId) {
        this.loadAndActivateForm(formId);
        this.selectedFormId = formId;
      } else {
        this.activateForm();
      }
    } else {
      this.deactivateForm();
    }
  },
  loadAndActivateForm: function(formId) {
    var pThis = this;

    this.$formChangeBtn.attr('disabled', true);
    $.ajax({
      url: this.options.formUrlTemplate.replace(':id', formId),
      type: 'GET',
      success: function(html) {
        pThis.loadForm(html);
        pThis.activateForm();
      },
      error: function(xhr, status, error) {
        pThis.showError(error);
        pThis.activateForm();
      },
      complete: function() {
        pThis.$formChangeBtn.attr('disabled', false);
      }
    });
  },
  loadForm: function(html) {
    this.$formPage.html($(html).html());
    SS.render();
  },
  showError: function(msg) {
    this.$formPageBody.html('<p>' + msg + '</p>');
  },
  activateForm: function() {
    this.$formPage.removeClass('hide');
    $('#addon-cms-agents-addons-body').addClass('hide');
    $('#addon-cms-agents-addons-file').addClass('hide');

    if (SS_AddonNavi.instance) {
      SS_AddonNavi.instance.reload();
    }
  },
  deactivateForm: function() {
    this.$formPageBody.html('');
    this.$formPage.addClass('hide');
    $('#addon-cms-agents-addons-body').removeClass('hide');
    $('#addon-cms-agents-addons-file').removeClass('hide');

    if (SS_AddonNavi.instance) {
      SS_AddonNavi.instance.reload();
    }
  }
};
