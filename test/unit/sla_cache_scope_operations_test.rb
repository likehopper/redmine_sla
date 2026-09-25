# frozen_string_literal: true

require_relative '../application_sla_units_test_case'

class SlaCacheScopeOperationsTest < ApplicationSlaUnitsTestCase
  def teardown
    User.current = nil
    super
  end

  [SlaCache, SlaCacheSpent].each do |model|
    test "#{model} visible scope applies project and issue permissions independently of list joins" do
      [User.find(1), User.find(3), User.find(5), User.anonymous].each do |user|
        User.current = user
        expected = model.all.select do |record|
          user.allowed_to?(:view_sla, record.project) && record.issue.visible?(user)
        end.map(&:id).sort
        assert_equal expected, model.visible(user).order(:id).pluck(:id)
      end
    end

    test "#{model} project purge removes orphan rows and preserves other projects" do
      project = Project.find(1)
      affected = model.where(project_id: project.id).order(:id).to_a
      assert_not_empty affected
      kept_ids = model.where.not(project_id: project.id).order(:id).pluck(:id)
      assert_not_empty kept_ids
      # Simulate historical damage: list joins must not hide rows from cleanup.
      reference = model == SlaCache ? :sla_level_id : :sla_cache_id
      model.connection.disable_referential_integrity do
        affected.first.update_column(reference, 999_999_999)
      end

      model.purge(project)

      assert_empty model.unscoped.where(project_id: project.id)
      assert_equal kept_ids, model.unscoped.order(:id).pluck(:id)
      if model == SlaCache
        assert_empty SlaCacheSpent.unscoped.where(sla_cache_id: affected.map(&:id))
      end
    end
  end

  test "destroy by issue removes only that issue cache and its spent rows" do
    cache = SlaCache.first
    kept_ids = SlaCache.where.not(id: cache.id).order(:id).pluck(:id)

    SlaCache.destroy_by_issue_id(cache.issue_id)

    assert_equal kept_ids, SlaCache.order(:id).pluck(:id)
    assert_empty SlaCacheSpent.where(sla_cache_id: cache.id)
  end

  test "destroying a project tracker removes only its matching caches" do
    link = SlaProjectTracker.find_by!(project_id: 1, tracker_id: 1)
    affected_ids = SlaCache.where(project_id: link.project_id, tracker_id: link.tracker_id).pluck(:id)
    kept_ids = SlaCache.where.not(id: affected_ids).order(:id).pluck(:id)
    assert_not_empty affected_ids

    link.destroy!

    assert_equal kept_ids, SlaCache.order(:id).pluck(:id)
    assert_empty SlaCacheSpent.where(sla_cache_id: affected_ids)
  end
end
