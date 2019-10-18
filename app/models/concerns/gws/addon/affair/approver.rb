module Gws::Addon::Affair
  module Approver
    extend ActiveSupport::Concern
    extend SS::Addon
    include Workflow::Approver

    def status
      if state == 'approve'
        state
      elsif workflow_state == 'cancelled'
        'draft'
      elsif workflow_state.present?
        workflow_state
      elsif state == 'closed'
        'draft'
      else
        state
      end
    end

    def workflow_state_options
      %w(all approve request).map do |v|
        [I18n.t("gws/workflow.options.file_state.#{v}"), v]
      end
    end

    def editable?(user, opts)
      editable = allowed?(:edit, user, opts) && !workflow_requested?
      return editable if editable

      if workflow_requested?
        workflow_approver_editable?(user)
      end
    end

    def destroyable?(user, opts)
      allowed?(:delete, user, opts) && !workflow_requested?
    end

    def agent_enabled?
      return false
    end
  end
end
