require 'azkaban_scheduler'

require "minitest/autorun"
require 'yaml'
require 'pathname'


module SessionTestHelper
  def config
    @@config ||= YAML.load(Pathname.new(File.dirname(__FILE__)).join('azkaban.yml').read)
  end

  def client
    @@client ||= AzkabanScheduler::Client.new(config['url'])
  end

  def session
    @@session ||= AzkabanScheduler::Session.start(client, config['username'], config['password'])
  end
end
