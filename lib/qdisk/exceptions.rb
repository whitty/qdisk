module QDisk

  class NotFound < Exception
    def initialize
      super("No matching device found")
    end
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
