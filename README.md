# AzkabanScheduler

Azkaban client that can update the schedule.

Azkaban scheduler was designed to make it easy to maintain both the
job definitions and the schedule for the jobs from within a projects
code. This allows you to easily keep the jobs in azkaban in sync
with your code.

## Installation

Add this line to your application's Gemfile:

    gem 'azkaban_scheduler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install azkaban_scheduler

## Usage

```ruby
require 'azkaban_scheduler'

client = AzkabanScheduler::Client.new('https://localhost:8443')
session = AzkabanScheduler::Session.start(client, 'admin', ENV['AZKABAN_PASSWORD'])
project = AzkabanScheduler::Project.new('Demo', 'A simple project to get you started')

flow_name = 'hello-world'
job = AzkabanScheduler::Job.new(type: 'command', command: '/bin/bash run')
job.add_file('run', '/path/to/run/script')

project.add_job(flow_name, job)
begin
  session.create_project(project)
rescue AzkabanScheduler::ProjectNotFoundError
end
session.upload_project(project)

session.remove_all_schedules(project.name)
start_time = Time.now + 60
session.post_schedule(project.id, project.name, flow_name, start_time, period: '12h')
```

## Contributing

1. Fork it ( https://github.com/Shopify/azkaban-scheduler-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
