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
    SlaHolidayAdapters::NagerDate.any_instance.stubs(:holidays).returns([
      { 'date' => '2098-01-01', 'name' => 'National', 'national' => true, 'regions' => [] },
      { 'date' => '2098-01-02', 'name' => 'Regional', 'national' => false, 'regions' => ['FR-67'] }
    ])
    assert_no_difference 'SlaHoliday.count' do
      post :preview_import, params: { year: '2098', country: 'FR' }
      assert_response :success
    end
    assert_select 'input[name="selected[]"][checked]', count: 1
    token = css_select('input[name=preview_token]').first['value']
    assert_difference 'SlaHoliday.count', 1 do
      post :import_holidays, params: { preview_token: token, selected: ['0'] }
      assert_redirected_to sla_holidays_path
    end
    assert_equal 'National', SlaHoliday.find_by(date: '2098-01-01').name
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

end