# frozen_string_literal: true

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

require_relative "../../test_helper"

class Redmine::ApiTest::SlasTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper

  test "GET /sla/slas.xml should return slas" do
    sla = Sla.find(1)

    get('/sla/slas.xml', :headers => {'CONTENT_TYPE' => 'application/xml'}.merge(credentials('admin')))
    assert_response :success
    assert_equal 'application/xml', @response.media_type

    assert_select 'slas' do
      assert_select '[total_count=?]', 8
    end    
    assert_select 'slas>entity:first-child' do
      assert_select '>id', :integer => sla.id
      assert_select '>name', :text => sla.name
    end
  end

  test "GET /sla/slas.json should return slas" do
    sla = Sla.find(1)

    get('/sla/slas.json', :headers => {'CONTENT_TYPE' => 'application/json'}.merge(credentials('admin')))
    assert_response :success
    assert_equal 'application/json', @response.media_type

    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['slas']
    assert_kind_of Hash, json['slas'].first
    assert json['slas'].first.has_key?('id')
    assert json['slas'].first.has_key?('name')
    assert_equal(sla.id, json['slas'].first['id'])
    assert_equal(sla.name, json['slas'].first['name'])
    assert_equal(8, json['total_count'])
  end


end