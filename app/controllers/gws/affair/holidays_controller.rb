class Gws::Affair::HolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  helper Gws::Schedule::PlanHelper

  model Gws::Schedule::Holiday

  navi_view "gws/affair/main/navi"
  append_view_path "app/views/gws/schedule/holidays"

  private

  def set_duty_hour
    @duty_hour ||= Gws::Affair::DutyHour.site(@cur_site).find(params[:duty_hour_id])
  end

  def set_year
    @cur_year ||= begin
      year = params[:year].to_s
      if year == "-"
        :all
      elsif year.numeric?
        Time.new(year.to_i, @cur_site.attendance_year_changed_month, 1).in_time_zone
      else
        raise "404"
      end
    end

    @cur_year_range ||= begin
      if @cur_year != :all
        @cur_site.attendance_year_range(@cur_year)
      else
        []
      end
    end
  end

  def fix_params
    set_duty_hour
    { cur_user: @cur_user, cur_site: @cur_site, duty_hour: @duty_hour }
  end

  def set_crumbs
    set_duty_hour
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("mongoid.models.gws/affair/duty_hour"), gws_affair_duty_hours_path ]
    @crumbs << [ @duty_hour.name, gws_affair_duty_hour_path(id: @duty_hour) ]
  end

  def set_items
    set_duty_hour
    set_year
    @items = @duty_hour.holidays
    @items = @items.gte(start_at: @cur_year_range[0]).lte(start_at: @cur_year_range[1]) if @cur_year_range.present?
  end

  def set_item
    set_items
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    set_items
    raise "403" unless @duty_hour.allowed?(:read, @cur_user, site: @cur_site)
    @items = @items.order_by(start_at: 1)
  end

  def show
    raise "403" unless @duty_hour.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def new
    raise "403" unless @duty_hour.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    raise "403" unless @duty_hour.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    raise "403" unless @duty_hour.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    raise "403" unless @duty_hour.allowed?(:edit, @cur_user, site: @cur_site)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end

  def delete
    raise "403" unless @duty_hour.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @duty_hour.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end
end
