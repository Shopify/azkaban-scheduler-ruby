require 'cgi'
require 'net/http/post/multipart'

module AzkabanScheduler
  class Session
    attr_accessor :id

    def self.start(client, username, password)
      params = {'action' => 'login', 'username' => username, 'password' => password}
      response = client.post('/', params)
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      unless result["status"] == "success"
        error_message = result["error"]
        if error_message == "Incorrect Login. Username\/Password not found."
          raise AuthenticationError, error_message
        end
        raise AzkabanError, error_message
      end
      new(client, result['session.id'])
    end

    def initialize(client, id)
      @client = client
      @id = id
    end

    def create_project(project)
      response = @client.post('/manager', {
        'session.id' => @id,
        'action' => 'create',
        'name' => project.name,
        'description' => project.description,
      })
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      if result['status'] != 'success'
        error_message = result['message']
        if error_message == "Active project with name #{project.name} already exists in db."
          raise ProjectExistsError, error_message
        elsif error_message == "Project names must start with a letter, followed by any number of letters, digits, '-' or '_'."
          raise InvalidProjectNameError, error_message
        elsif error_message == "Description cannot be empty."
          raise ProjectDescriptionEmptyError, error_message
        end
        raise AzkabanError, error_message
      end
      result
    end

    def upload_project(project)
      response = @client.multipart_post('/manager', {
        'session.id' => @id,
        'ajax' => 'upload',
        'project' => project.name,
        'file' => UploadIO.new(project.build, 'application/zip', 'file.zip'),
      })
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      if error_message = result['error']
        if error_message == "Installation Failed. Project '#{project.name}' doesn't exist."
          raise ProjectNotFoundError, error_message
        end
        raise AzkabanError, error_message
      end
      project.id = result['projectId']
      project.version = result['version']
      result
    end

    def delete_project(project_name)
      response = @client.get('/manager', {
        'session.id' => @id,
        'project' => project_name,
        'delete' => 'true',
      })
      response.error! unless response.kind_of?(Net::HTTPSuccess) || response.kind_of?(Net::HTTPRedirection)
      cookies = response_cookies(response)
      unless cookies['azkaban.success.message']
        error_message = cookies['azkaban.failure.message']
        if error_message == "Project #{project_name} doesn't exist."
          return false
        end
        raise AzkabanError, error_message
      end
      true
    end

    def get_project_id(project_name)
      result = fetch_project_flows(project_name)
      result['projectId']
    end

    def list_flow_ids(project_name)
      result = fetch_project_flows(project_name)
      result['flows'].map{ |flow| flow['flowId'] }
    end

    def fetch_project_flows(project_name)
      response = @client.get('/manager', {
        'session.id' => @id,
        'ajax' => 'fetchprojectflows',
        'project' => project_name,
      })
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      JSON.parse(response.body)
    end

    def fetch_flow_executions(project_name, flow_id, offset=0, limit=10)
      response = @client.get('/manager', {
        'session.id' => @id,
        'ajax' => 'fetchFlowExecutions',
        'project' => project_name,
        'flow' => flow_id,
        'start' => offset,
        'length' => limit,
      })
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      JSON.parse(response.body)
    end

    def list_schedules
      response = @client.post('/schedule', { 'ajax' => 'loadFlow' }, session_id_cookie)
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      result['items'] || []
    end

    def remove_schedule(schedule_id)
      response = @client.post('/schedule', {
        'action' => 'removeSched',
        'scheduleId' => schedule_id,
      }, session_id_cookie)
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      unless result['status'] == 'success'
        error_message = result['message']
        return false if error_message == "Schedule with ID #{schedule_id} does not exist"
        raise AzkabanError, error_message
      end
      true
    end

    def remove_all_schedules(project_name)
      list_schedules.each do |schedule|
        next unless schedule['projectname'] == project_name
        schedule_id = schedule['scheduleid']
        remove_schedule(schedule_id)
      end
    end

    def post_schedule(project_id, project_name, flow, start_time, options={})
      response = @client.post('/schedule', {
        'ajax' => 'scheduleFlow',
        'project' => project_name,
        'projectName' => project_name,
        'projectId' => project_id,
        'flow' => flow,
        'disabled' => options[:disabled] || '[]',
        'period' => options[:period] || "1d",
        'scheduleTime' => start_time.utc.strftime("%I,%M,%p,UTC"),
        'scheduleDate' => start_time.utc.strftime("%m/%d/%Y"),
        'is_recurring' => options[:period] ? 'on' : 'off',
        'concurrentOption' => options[:concurrent_option] || 'skip',
        'failureEmailsOverride' => (!!options[:failure_emails_override]).to_s,
        'successEmailsOverride' => (!!options[:success_emails_override]).to_s,
        'failureAction' => options[:failure_action] || 'finishCurrent',
        'failureEmails' => Array(options[:failure_emails]).join(', '),
        'successEmails' => Array(options[:success_emails]).join(', '),
        'notifyFailureFirst' => (!!options[:notify_failure_first]).to_s,
        'notifyFailureLast' => (!!options[:notify_failure_last]).to_s,
      }, session_id_cookie)
      response.error! unless response.kind_of?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      unless result['status'] == 'success'
        raise AzkabanError, result['message']
      end
      nil
    end

    private

    def response_cookies(response)
      response['Set-Cookie'].split(',').each_with_object({}) do |cookie, hash|
        name, value = cookie.split(';')[0].split('=', 2)
        value = value.to_s.strip
        value = value[1...-1] if value[0] == '"'.freeze && value[-1] == '"'.freeze
        hash[name.strip] = value
      end
    end

    def session_id_cookie
      { 'Cookie' => "azkaban.browser.session.id=#{@id}" }
    end
  end
end
