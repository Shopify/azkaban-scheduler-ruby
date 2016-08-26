module AzkabanScheduler
  class Job
    attr_reader :params, :files

    def initialize(params)
      @files  = {}
      @params = params
    end

    # Add an additional file to this job's zip
    def add_file(name, filepath)
      raise ArgumentError, "Invalid filepath: #{filepath}" unless File.file?(filepath)
      files[name] = filepath
    end

    def write(name, io)
      io.put_next_entry("#{name}.job")
      params.each do |key, value|
        io.puts("#{key}=#{value}")
      end
      write_files(io)
    end

    private

    # Write out the additional files to the IO stream
    def write_files(io)
      files.each do |entry_name, filepath|
        io.put_next_entry(entry_name)
        io.puts(File.read(filepath))
      end
    end
  end
end
