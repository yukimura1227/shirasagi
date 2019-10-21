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
      criteria = criteria.search_capital(params)
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

      cur_site = params[:cur_site]
      cur_user = params[:cur_user]

      base_criteria = all.allow(:read, cur_user, site: cur_site)

      case params[:state]
      when 'all'
        base_criteria
      when 'approve'
        base_criteria.where(
          workflow_state: 'request',
          workflow_approvers: { '$elemMatch' => { 'user_id' => cur_user.id, 'state' => 'request' } }
        )
      when 'mine'
        base_criteria.where(user_id: cur_user.id)
      else
        none
      end
    end

    def search_capital(params)
      return all if params[:capital_id].blank?

      capital = Gws::Affair::Capital.find(params[:capital_id]) rescue nil
      return all if capital.blank?

      all.where(capital_id: capital.id)
    end
  end
end
