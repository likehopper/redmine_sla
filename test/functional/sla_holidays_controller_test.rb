# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_holidays_controller_test.rb
# Redmine SLA - Redmine's Plugin 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require_relative "../application_sla_functionals_test_case"

class SlaHolidaysControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  ### As anonymous ###

  test "should get 302 on index as anonymous" do
    with_settings :default_language => "en" do
      get :index
      assert_response 302
    end
  end

  test "should get 302 on show as anonymous" do
    with_settings :default_language => "en" do
      get :show,
        :params => {:id => 1}
      assert_response 302
    end
  end

  test "should get 302 on edit as anonymous" do
    with_settings :default_language => "en" do
      get :edit,
        :params => {:id => 1}
      assert_response 302
    end
  end

  ### As admin #1 ###

  test "should get success on index as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index,
        params: { sort: 'date' }
      assert_response :success
      # links to visible issues
      assert_select 'a[href="/sla/holidays/1"]', :title => "Show"
      assert_select 'a[href="/sla/holidays/1/edit"]', :title => "Edit"
      assert_select 'a[href="/sla/holidays/1"]', :title => "Delete", :method => "delete"
    end
  end

  test "should return success on get show as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :show,
        :params => {:id => 1}
      assert_response :success
    end
  end

  test "should return success on get edit as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :edit,
        :params => {:id => 1}
      assert_response :success
    end
  end

  ### As manager #2 ###

  test "should return 403 on get index as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :show,
        :params => {:id => 1}
      assert_response 403
    end
  end

  test "should return 403 on get edit as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :edit,
        :params => {:id => 1}
      assert_response 403
    end
  end

  ### As developper #3 ###

  test "should return 403 on get index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :show,
        :params => {:id => 1}
      assert_response 403
    end
  end

  test "should return 403 on get edit as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :edit,
        :params => {:id => 1}
      assert_response 403
    end
  end

  ### As sysadmin #4 ###

  test "should return 403 on get index as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :show,
        :params => {:id => 1}
      assert_response 403
    end
  end

  test "should return 403 on get edit as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :edit,
        :params => {:id => 1}
      assert_response 403
    end
  end

  ### As reporter #5 ###

  test "should return 403 on get index as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 403
    end
  end

  test "should return 403 on get edit as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :edit,
        :params => {:id => 1}
      assert_response 403
    end
  end

  ### As other #6 ###

  test "should return 403 on get index as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :show,
        :params => {:id => 1}
      assert_response 403
    end
  end

  test "should return 403 on get edit as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :edit,
        :params => {:id => 1}
      assert_response 403
    end
  end


  test "import form verifies access and offers countries" do
    @request.session[:user_id] = 1
    SlaHolidayAdapters::NagerDate.any_instance.expects(:available_countries).returns([['France', 'FR']])
    get :import_form
    assert_response :success
    assert_select 'select[name=country] option[value=FR]', 'France'
    assert_select 'select[name=language] option[value=local][selected]'
  end

  test "unavailable API displays an error without writes" do
    @request.session[:user_id] = 1
    SlaHolidayAdapters::NagerDate.any_instance.expects(:available_countries).raises(SlaHolidayAdapters::NagerDate::Error, 'unavailable')
    assert_no_difference 'SlaHoliday.count' do
      get :import_form
      assert_response :success
      assert_select '#flash_error'
      assert_select 'input[type=submit][disabled]'
    end
  end

  test "preview and import selected holidays with signed data" do
    @request.session[:user_id] = 1
    SlaHolidayAdapters::NagerDate.any_instance.stubs(:available_countries).returns([['France', 'FR']])
    SlaHolidayAdapters::NagerDate.any_instance.expects(:holidays).with(year: '2098', country: 'FR', language: 'local').returns([
      { 'date' => '2098-01-01', 'name' => 'National', 'national' => true, 'regions' => [] },
      { 'date' => '2098-01-02', 'name' => 'Regional', 'national' => false, 'regions' => ['FR-67'] }
    ])
    assert_no_difference 'SlaHoliday.count' do
      post :preview_import, params: { year: '2098', country: 'FR', language: 'local' }
      assert_response :success
    end
    assert_select 'input[name="selected[]"][checked]', count: 1
    token = css_select('input[name=preview_token]').first['value']
    SlaHolidayAdapters::NagerDate.any_instance.expects(:available_countries).never
    SlaHolidayAdapters::NagerDate.any_instance.expects(:holidays).never
    assert_difference 'SlaHoliday.count', 1 do
      post :import_holidays, params: { preview_token: token, selected: ['0'] }
      assert_redirected_to sla_holidays_path
    end
    assert_equal 'National 2098', SlaHoliday.find_by(date: '2098-01-01').name
  end

  test "invalid and expired previews never write" do
    @request.session[:user_id] = 1
    verifier = Rails.application.message_verifier(:sla_holiday_import)
    tokens = ['tampered', verifier.generate({ 'user_id' => 1, 'expires_at' => 1, 'holidays' => [] }),
              verifier.generate({ 'user_id' => 2, 'expires_at' => 15.minutes.from_now.to_i, 'holidays' => [] })]
    tokens.each do |token|
      assert_no_difference 'SlaHoliday.count' do
        post :import_holidays, params: { preview_token: token, selected: ['0'] }
        assert_redirected_to import_sla_holidays_path
      end
    end
  end

  test "non administrators cannot access any import action" do
    @request.session[:user_id] = 6
    SlaHolidayAdapters::NagerDate.any_instance.expects(:available_countries).never
    get :import_form
    assert_response :forbidden
    post :preview_import, params: { year: '2026', country: 'FR' }
    assert_response :forbidden
    assert_no_difference 'SlaHoliday.count' do
      post :import_holidays, params: { preview_token: 'invalid' }
      assert_response :forbidden
    end
  end

  test "invalid country is refused before fetching holidays" do
    @request.session[:user_id] = 1
    SlaHolidayAdapters::NagerDate.any_instance.expects(:available_countries).returns([['France', 'FR']])
    SlaHolidayAdapters::NagerDate.any_instance.expects(:holidays).never
    assert_no_difference 'SlaHoliday.count' do
      post :preview_import, params: { year: '2026', country: 'XX' }
      assert_response :success
      assert_select '#flash_error', text: l(:sla_holiday_import_error_invalid_selection)
      assert_select 'input[name=preview_token]', count: 0
    end
  end

  test "holiday service errors during preview never offer an import" do
    @request.session[:user_id] = 1
    SlaHolidayAdapters::NagerDate.any_instance.stubs(:available_countries).returns([['France', 'FR']])
    %w[unavailable invalid_response invalid_selection].each do |reason|
      SlaHolidayAdapters::NagerDate.any_instance.stubs(:holidays).raises(SlaHolidayAdapters::NagerDate::Error, reason)
      assert_no_difference 'SlaHoliday.count' do
        post :preview_import, params: { year: '2026', country: 'FR' }
        assert_response :success
        assert_select '#flash_error', text: l("sla_holiday_import_error_#{reason}")
        assert_select 'input[name=preview_token]', count: 0
      end
    end
  end

  test "invalid selection indices never import or call the provider" do
    @request.session[:user_id] = 1
    token = Rails.application.message_verifier(:sla_holiday_import).generate({
      'user_id' => 1, 'expires_at' => 15.minutes.from_now.to_i,
      'holidays' => [{ 'date' => '2098-01-01', 'name' => 'National' }]
    })
    SlaHolidayAdapters::NagerDate.any_instance.expects(:available_countries).never
    SlaHolidayAdapters::NagerDate.any_instance.expects(:holidays).never
    %w[-1 1 invalid].each do |index|
      assert_no_difference 'SlaHoliday.count' do
        post :import_holidays, params: { preview_token: token, selected: [index] }
        assert_redirected_to import_sla_holidays_path
        assert_equal l(:sla_holiday_import_expired), flash[:error]
      end
    end
  end

  test "failed import rolls back and displays an error" do
    @request.session[:user_id] = 1
    token = Rails.application.message_verifier(:sla_holiday_import).generate({
      'user_id' => 1, 'expires_at' => 15.minutes.from_now.to_i,
      'holidays' => [{ 'date' => '2098-01-01', 'name' => 'Valid' },
                     { 'date' => '2098-01-02', 'name' => '' }]
    })
    assert_no_difference 'SlaHoliday.count' do
      post :import_holidays, params: { preview_token: token, selected: ['0', '1'] }
      assert_redirected_to import_sla_holidays_path
      assert_equal l(:sla_holiday_import_failed), flash[:error]
    end
  end

  ### Access audit: SLA holidays are managed by administrators only ###

  test "should render new and context menu on SLA holidays as admin" do
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    get :context_menu, params: { ids: [1] }
    assert_response :success
    assert_select "a[href=?]", edit_sla_holiday_path(1)
  end

  test "should create, update, delete with calendar links and bulk delete SLA holidays as admin" do
    @request.session[:user_id] = 1
    assert_difference "SlaHoliday.count", 1 do
      post :create, params: { sla_holiday: { name: "Created SLA holiday", date: "2099-12-25" } }
    end
    assert_redirected_to sla_holidays_path
    patch :update, params: { id: 1, sla_holiday: { name: "Updated SLA holiday" } }
    assert_redirected_to sla_holidays_path
    assert_equal "Updated SLA holiday", SlaHoliday.find(1).name
    linked_calendar_count = SlaCalendarHoliday.where(sla_holiday_id: 1).count
    assert_operator linked_calendar_count, :>, 0
    assert_difference -> { SlaCalendarHoliday.count } => -linked_calendar_count, -> { SlaHoliday.count } => -1 do
      delete :destroy, params: { id: 1 }
    end
    deletables = create_deletable_sla_holidays
    assert_difference "SlaHoliday.count", -3 do
      delete :destroy, params: { ids: deletables.map(&:id) }
    end
    assert_redirected_to sla_holidays_path
  end

  { "anonymous" => nil, "project SLA manager" => 2, "reporter without SLA permission" => 5 }.each do |label, user_id|
    test "should deny new and context menu on SLA holidays to #{label}" do
      @request.session[:user_id] = user_id
      get :new
      assert_access_denied(user_id)
      get :context_menu, params: { ids: [1] }
      assert_access_denied(user_id)
    end

    test "should deny SLA holiday writes to #{label} without changing data" do
      deletables = create_deletable_sla_holidays
      assert SlaCalendarHoliday.exists?(sla_holiday_id: 1)
      assert_no_difference "SlaCalendarHoliday.count" do
        assert_denied_without_change(user_id, SlaHoliday.find(1)) do
          post :create, params: { sla_holiday: { name: "Denied SLA holiday", date: "2099-12-25" } }
          assert_access_denied(user_id)
          patch :update, params: { id: 1, sla_holiday: { name: "Denied SLA holiday change" } }
          assert_access_denied(user_id)
          delete :destroy, params: { id: 1 }
          assert_access_denied(user_id)
          delete :destroy, params: { ids: deletables.map(&:id) }
          assert_access_denied(user_id)
        end
      end
      assert_equal deletables.size, SlaHoliday.where(id: deletables.map(&:id)).count
    end

    # The token is signed for the requesting user, so only the admin check can stop the import.
    test "should deny holiday import actions to #{label} without fetching or writing" do
      @request.session[:user_id] = user_id
      SlaHolidayAdapters::NagerDate.any_instance.expects(:available_countries).never
      SlaHolidayAdapters::NagerDate.any_instance.expects(:holidays).never
      token = Rails.application.message_verifier(:sla_holiday_import).generate({
        'user_id' => (user_id || User.anonymous.id), 'expires_at' => 15.minutes.from_now.to_i,
        'holidays' => [{ 'date' => '2099-07-14', 'name' => 'Denied import 2099' }]
      })
      assert_no_difference "SlaHoliday.count" do
        get :import_form
        assert_access_denied(user_id)
        post :preview_import, params: { year: '2099', country: 'FR' }
        assert_access_denied(user_id)
        post :import_holidays, params: { preview_token: token, selected: ['0'] }
        assert_access_denied(user_id)
      end
    end
  end

  # Fresh holidays without calendar links, on dates absent from the fixtures.
  def create_deletable_sla_holidays
    Array.new(3) { |index| SlaHoliday.create!(name: "Deletable SLA holiday #{index}", date: Date.new(2099, 1, index + 1)) }
  end

end
