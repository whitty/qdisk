module QDisk

  class UnknownCommand < Exception
    def initialize(command, detail = nil)
      str = "Unknown command #{command}"
      if detail and detail.length > 0
        str += "\n #{detail}"
      end
      super(str)
    end

    def code ; 2 end
  end

  class MissingRequiredArgument < Exception
    def initialize(argument, detail = nil)
      str = "Missing required argument '#{argument}'"
      if detail and detail.length > 0
        str += "\n #{detail}"
      end
      super(str)
    end
    def code ; 2 end
  end

  class NotFound < Exception
    def initialize(what = 'device')
      super("No matching #{what} found")
    end
    def code ; 4 end
  end

  class NotUnique < Exception
    def initialize(devices)
      @names = devices.map {|x| x.device_name }
      @devices = devices
      super("Expected one device, but got #{devices.length}")
    end

    attr_reader :names, :devices
  end

  class CommandException < Exception
    def initialize(exception_message, fail_message)
      @fail_message = fail_message
      super(exception_message)
    end

    attr_reader :fail_message
  end

  class UnmountFailed < CommandException
    def initialize(partition, fail_message)
      @partition = partition
      super("Failed to unmount partition #{partition.device_name}", fail_message)
    end

    attr_reader :partition
  end

  class DetachFailed < CommandException
    def initialize(disk, fail_message)
      @disk = disk
      super("Failed to detach disk #{disk.device_name}", fail_message)
    end

    attr_reader :disk
  end

  class CommandFailed < CommandException
    def initialize(command, fail_message)
      super("Command failed: #{command}", fail_message)
    end
  end

end
