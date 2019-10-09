require 'spec_helper'

describe "gws_affair_duty_hours", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:affair_on_duty_working_minute) { rand(350..370) }
  let(:affair_on_duty_break_minute) { rand(40..50) }
  let(:affair_on_duty_working_minute2) { rand(370..390) }
  let(:affair_on_duty_break_minute2) { rand(50..60) }

  before do
    login_gws_user
  end

  context 'crud for default item' do
    it do
      #
      # Update: this is only available.
      #
      visit gws_affair_duty_hours_path(site: site)
      click_on I18n.t("gws/affair.default_duty_hour")
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[affair_on_duty_working_minute]", with: affair_on_duty_working_minute
        fill_in "item[affair_on_duty_break_minute]", with: affair_on_duty_break_minute

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Affair::DutyHour.all.count).to eq 0
      site.reload
      expect(site.affair_on_duty_working_minute).to eq affair_on_duty_working_minute
      expect(site.affair_on_duty_break_minute).to eq affair_on_duty_break_minute

      # Update on site
      visit gws_site_path(site: site)
      within "#addon-gws-agents-addons-attendance-group_setting" do
        first(".addon-head h2").click
        expect(page).to have_content(affair_on_duty_working_minute.to_s)
        expect(page).to have_content(affair_on_duty_break_minute.to_s)
      end

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        within "#addon-gws-agents-addons-attendance-group_setting" do
          first(".addon-head h2").click
          fill_in "item[affair_on_duty_working_minute]", with: affair_on_duty_working_minute2
          fill_in "item[affair_on_duty_break_minute]", with: affair_on_duty_break_minute2
        end

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      site.reload
      expect(site.affair_on_duty_working_minute).to eq affair_on_duty_working_minute2
      expect(site.affair_on_duty_break_minute).to eq affair_on_duty_break_minute2

      # check on gws/affair/duty_hours
      visit gws_affair_duty_hours_path(site: site)
      click_on I18n.t("gws/affair.default_duty_hour")
      within "#addon-basic" do
        expect(page).to have_content(affair_on_duty_working_minute2.to_s)
        expect(page).to have_content(affair_on_duty_break_minute2.to_s)
      end
    end
  end
end
