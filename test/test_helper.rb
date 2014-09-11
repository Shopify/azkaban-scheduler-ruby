require 'azkaban_scheduler'

require "minitest/autorun"
require 'yaml'
require 'pathname'
require 'vcr'

DEFAULT_CONFIG = {
  'url' => 'http://localhost:8081',
  'username' => 'admin',
  'password' => 'password'
}

def test_config
  @test_config ||= begin
    path = Pathname.new(File.dirname(__FILE__)).join('azkaban.yml')
    path.exist? ? YAML.load(path.read) : DEFAULT_CONFIG
  end
end

VCR.configure do |c|
  c.cassette_library_dir = File.expand_path('../fixtures', __FILE__)
  c.hook_into :webmock
  c.filter_sensitive_data("<URL>") { test_config['url'].sub(/https?:\/\//, 'http://') }
  test_config.each do |key, value|
    c.filter_sensitive_data("<#{key.upcase}>") { test_config[key] }
  end
end

module SessionTestHelper
  def config
    test_config
  end

  def client
    @@client ||= AzkabanScheduler::Client.new(config['url'])
  end

  def session
    @@session ||= AzkabanScheduler::Session.start(client, config['username'], config['password'])
  end
end
