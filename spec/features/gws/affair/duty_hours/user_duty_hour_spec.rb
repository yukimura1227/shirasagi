require 'spec_helper'

describe "gws_affair_duty_hours", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user1) { create :gws_user, group_ids: [ group.id ], gws_role_ids: user.gws_role_ids }
  let!(:user2) { create :gws_user, group_ids: [ group.id ], gws_role_ids: user.gws_role_ids }
  let!(:item1) { create :gws_affair_duty_hour, member_ids: [ user1.id ] }
  let!(:item2) { create :gws_affair_duty_hour, member_group_ids: [ group.id ] }

  it do
    login_user user

    visit gws_user_profile_path(site: site)
    within ".main-box" do
      expect(page).to have_content(I18n.t("gws/affair.default_duty_hour"))
    end

    visit gws_users_path(site: site)
    click_on user.name
    within "#addon-gws-agents-addons-user-duty_hour" do
      expect(page).to have_content(I18n.t("gws/affair.default_duty_hour"))
    end

    login_user user1

    visit gws_user_profile_path(site: site)
    within ".main-box" do
      expect(page).to have_content(item1.name)
    end

    visit gws_users_path(site: site)
    click_on user1.name
    within "#addon-gws-agents-addons-user-duty_hour" do
      expect(page).to have_content(item1.name)
    end

    login_user user2

    visit gws_user_profile_path(site: site)
    within ".main-box" do
      expect(page).to have_content(item2.name)
    end

    visit gws_users_path(site: site)
    click_on user2.name
    within "#addon-gws-agents-addons-user-duty_hour" do
      expect(page).to have_content(item2.name)
    end
  end
end
