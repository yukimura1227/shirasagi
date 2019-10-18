module Gws::Affair::Searchable
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_user(params)
      criteria = criteria.search_date(params)
      criteria = criteria.search_state(params)
      criteria
    end

    def search_user(params)
      return all if params[:user_id].blank?
      all.where(user_id: params[:user_id])
    end

    def search_date(params)
      return all if params[:year].blank? || params[:month].blank?

      start_at = Time.zone.parse("#{params[:year]} #{params[:month]}/1")
      end_at = start_at.end_of_month

      all.where('$and' => [ { "date" => { "$gte" => start_at } }, { "date" => { "$lte" => end_at } } ])
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text, 'column_values.text_index')
    end

    def search_state(params)
      return all if params[:state].blank?

      # サブクエリ構築時に `unscoped` を用いているが、`unscoped` を呼び出すと現在の検索条件が消失してしまう。
      # それを防ぐため、前もって現在の検索条件を複製しておく。
      base_criteria = all.dup

      cur_site = params[:cur_site]
      cur_user = params[:cur_user]

      allow_selector = unscoped do
        all.allow(:read, cur_user, site: cur_site).selector
      end
      readable_selector = unscoped do
        all.in(state: %w(approve public)).readable(cur_user, site: cur_site).selector
      end
      base_criteria = base_criteria.where('$and' => [{ '$or' => [ allow_selector, readable_selector ] }])

      case params[:state]
      when 'all'
        base_criteria
      when 'approve'
        base_criteria.where(
          workflow_state: 'request',
          workflow_approvers: { '$elemMatch' => { 'user_id' => cur_user.id, 'state' => 'request' } }
        )
      when 'request'
        base_criteria.where(workflow_user_id: cur_user.id)
      else
        none
      end
    end
  end
end
