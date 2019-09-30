class Gws::Affair::Overtime::AggregateController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::OvertimeFile

  navi_view "gws/affair/main/navi"
  menu_view nil

  before_action :set_query

  private

  def set_query
    @start_year = params.dig(:s, :start_year).presence || Time.zone.now.year
    @start_month = params.dig(:s, :start_month).presence || Time.zone.now.month
    @start_at = Time.zone.parse("#{@start_year}/#{@start_month}").to_date

    @end_year = params.dig(:s, :end_year).presence || Time.zone.now.year
    @end_month = params.dig(:s, :end_month).presence || Time.zone.now.month
    @end_at = Time.zone.parse("#{@end_year}/#{@end_month}").to_date.end_of_month

    @unit = params.dig(:s, :unit).presence || "day"
  end

  public

  def index
    @items = @model.user(@cur_user).and(
      { "results_by_day.date" => { "$gte" => @start_at } },
      { "results_by_day.date" => { "$lte" => @end_at } },
    ).aggregate_results_by_date(@unit)
  end

  def capitals
    @capitals = Gws::Affair::Capital.site(@cur_site).map { |item| [item.id, item] }.to_h
    @items = @model.user(@cur_user).and(
      { "results_by_day.date" => { "$gte" => @start_at } },
      { "results_by_day.date" => { "$lte" => @end_at } },
    ).aggregate_results_by_capital(@unit)
  end
end
