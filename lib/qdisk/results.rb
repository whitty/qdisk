module QDisk
  extend self

  def print(results, op, options = {})
    return if results.nil?
    partitions, disks = results.partition {|x| x.partition?}
    if disks.empty?
      results.each do |x|
        print_partition(0, x, op, options)
      end
    elsif partitions.empty?
      results.each do |x|
        print_disk(0, x, op, options)
      end
    else
      disks.each do |disk|
        print_disk(0, disk, op, options)
        partitions.select {|x| x.parent == disk.object_name}.each do |partition|
          print_partition(1, partition, op, options)
        end
      end
    end
  end

  def print_partition(indent, partition, op, options)
    print_common(indent, partition, op, options) do |_|
      cols = [:type]
      cols.concat [:mounted_by_uid, :mount_paths] if partition.mounted?

      cols.each do |method|
        op.printf(" \t%s", partition.send(method))
      end
    end
  end

  def print_disk(indent, disk, op, options)
    print_common(indent, disk, op, options)
  end

  private
  def print_common(indent, device, op, options, &block)
    op.print("  " * indent)
    op.print(device.device_name)
    return if options.fetch(:short, false)
    block.call(op) if block
    op.print "\n"
  end
end
