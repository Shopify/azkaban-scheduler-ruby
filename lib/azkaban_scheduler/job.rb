module AzkabanScheduler
  class Job
    def initialize(params)
      @params = params
    end

    def write(io)
      @params.each do |key, value|
        io.puts("#{key}=#{value}")
      end
    end
  end
end
