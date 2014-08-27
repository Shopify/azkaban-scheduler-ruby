module AzkabanScheduler
  class Schedule
    Stats = Struct.new(:min, :max, :average)
    attr_accessor :id, :stats

    def initialize(project_name, flow_name, options={})
      @project_name = project_name
      @flow_name = flow_name
      @period = options[:period]
      @is_recurring = !!options[:period]
      @time = options[:time] || Time.now.to_i
      @failure_emails = options[:failure_emails]
      @success_emails = options[:success_emails]
    end
  end
end
