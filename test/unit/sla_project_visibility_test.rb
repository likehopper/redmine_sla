# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_project_visibility_test.rb
# Purpose:
#   Protect project-scoped visibility for SLA configuration catalogs.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaProjectVisibilityTest < ApplicationSlaUnitsTestCase

  def setup
    super
    User.current = User.find(3) # Resolver in projects 1 and 4.
  end

  def teardown
    User.current = nil
    super
  end

  test "visible scopes include only catalogs from authorized projects" do
    assert_equal [1, 2, 7, 8], Sla.visible.order(:id).pluck(:id)
    assert_equal [1, 2, 9, 10], SlaLevel.visible.order(:id).pluck(:id)
    assert_equal [1], SlaCalendar.visible.order(:id).pluck(:id)
  end

  test "project scopes include only catalogs used by that project" do
    project = Project.find(1)

    assert_equal [1, 2], Sla.in_project(project).order(:id).pluck(:id)
    assert_equal [1, 2], SlaLevel.in_project(project).order(:id).pluck(:id)
    assert_equal [1], SlaCalendar.in_project(project).order(:id).pluck(:id)
  end

  test "level query filter values do not expose other project catalogs" do
    query = SlaLevelQuery.new(project: Project.find(1))

    assert_equal [["SLA TMA tracker_bug_request", "1"],
                  ["SLA TMA tracker_support_request", "2"]], query.all_sla_values
    assert_equal [["TMA - HO", "1"]], query.all_sla_calendar_values
    assert_empty query.all_sla_custom_fields_values
  end

  test "custom field filter excludes fields used only by forbidden projects and unused fields" do
    IssueCustomField.find(2).update_column(:is_required, true)
    SlaLevel.find(3).update_column(:custom_field_id, 2)

    assert_equal [["SlaPriorityScf", "1"]], SlaLevelQuery.new.all_sla_custom_fields_values
    assert_equal [["SlaPriorityScf", "1"]],
                 SlaLevelQuery.new(project: Project.find(4)).all_sla_custom_fields_values
    assert_empty SlaLevelQuery.new(project: Project.find(2)).all_sla_custom_fields_values
  end

  test "custom field filter excludes fields hidden from the user" do
    IssueCustomField.find(1).update_column(:visible, false)

    assert_empty SlaLevelQuery.new.all_sla_custom_fields_values
  end

  test "custom field filter is empty without SLA permission or for anonymous users" do
    [User.find(5), User.anonymous].each do |user|
      User.current = user
      assert_empty SlaLevelQuery.new.all_sla_custom_fields_values
    end
  end

  test "administrator custom field filter includes referenced fields and respects project context" do
    User.current = User.find(1)
    IssueCustomField.find(2).update_column(:is_required, true)
    SlaLevel.find(3).update_column(:custom_field_id, 2)

    assert_equal [["SlaPriorityScf", "1"], ["IsNotRequired", "2"]],
                 SlaLevelQuery.new.all_sla_custom_fields_values.sort_by { |_, id| id.to_i }
    assert_equal [["IsNotRequired", "2"]],
                 SlaLevelQuery.new(project: Project.find(2)).all_sla_custom_fields_values
  end

end
