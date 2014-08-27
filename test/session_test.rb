require 'test_helper'

class SessionTest < Minitest::Test
  include SessionTestHelper

  def setup
    @project = AzkabanScheduler::Project.new('Azkaban_Scheduler_Test', 'Used by the test suite')
    @project.add_job('first', AzkabanScheduler::Job.new(type: 'command', command: 'echo "hello world"'))
    @@once ||= setup_once || true
  end

  def setup_once
    session.remove_all_schedules(@project.name)
    session.delete_project(@project.name)
  end

  def test_start
    refute session.id.empty?
  end

  def test_start_with_incorrect_password
    assert_raises(AzkabanScheduler::AuthenticationError) do
      AzkabanScheduler::Session.start(client, 'foo', 'bar')
    end
  end

  def test_create_and_upload_project
    session.create_project(@project)
    result = session.upload_project(@project)
    assert result['projectId']
    assert result['version']
    assert_equal result['projectId'], @project.id
    assert_equal result['version'], @project.version
    assert_equal true, session.delete_project(@project.name)
  end

  def test_post_schedule
    session.create_project(@project)
    session.upload_project(@project)
    flow_name = 'first'
    start_time = Time.now
    session.post_schedule(@project.id, @project.name, flow_name, start_time,
                          period: '6h',
                          failure_emails_override: true,
                          notifyFailureFirst: true,
                          failure_emails: ['azkaban-scheduler-test@localhost'])
    schedule = session.list_schedules.detect { |item| item['projectname'] == @project.name && item['flowname'] == flow_name }
    assert schedule['scheduleid']
    assert_equal (start_time.to_i - start_time.sec) * 1000, schedule['time']
    assert_equal 6 * 60 * 60 * 1000, schedule['period']
  ensure
    session.remove_all_schedules(@project.name)
    session.delete_project(@project.name)
  end

  def test_create_existing_project
    session.create_project(@project)
    assert_raises(AzkabanScheduler::ProjectExistsError) do
      session.create_project(@project)
    end
  ensure
    session.delete_project(@project.name)
  end

  def test_create_project_with_invalid_name
    project = AzkabanScheduler::Project.new('Azkaban Scheduler Test', "description")
    assert_raises(AzkabanScheduler::InvalidProjectNameError) do
      session.create_project(project)
    end
  end

  def test_create_project_with_invalid_name
    project = AzkabanScheduler::Project.new('Azkaban_Scheduler_Test', "")
    assert_raises(AzkabanScheduler::ProjectDescriptionEmptyError) do
      session.create_project(project)
    end
  end

  def test_upload_missing_project
    assert_raises(AzkabanScheduler::ProjectNotFoundError) do
      session.upload_project(@project)
    end
  end

  def test_delete_missing_project
    assert_equal false, session.delete_project(@project.name)
  end
end
