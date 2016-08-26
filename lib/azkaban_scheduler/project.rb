require 'stringio'
require 'zip'

module AzkabanScheduler
  class Project
    attr_accessor :name, :description, :jobs
    attr_accessor :id, :version

    def initialize(name, description)
      @name = name
      @description = description
      @jobs = {}
    end

    def add_job(name, job)
      @jobs[name] = job
    end

    def build
      io = StringIO.new
      write(io)
      io.rewind
      io
    end

    def write(io)
      Zip::OutputStream.write_buffer(io) do |out|
        @jobs.each do |name, job|
          job.write(name, out)
        end
      end
    end
  end
end
