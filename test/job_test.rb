require 'test_helper'

class JobTest < Minitest::Test
  def test_add_file
    job = build
    job.add_file('foobar', __FILE__)
    assert_equal 1, job.files.length
  end

  def test_write
    job = build('foo' => 'bar')
    job.add_file('job_test.rb', __FILE__)

    out = IODouble.new
    job.write('foobar', out)

    assert_equal({ 'foobar.job' => 'foo=bar', 'job_test.rb' => File.read(__FILE__) }, out.written)
  end

  private

  def build(params = {})
    AzkabanScheduler::Job.new(params)
  end
end
