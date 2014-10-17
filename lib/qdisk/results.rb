module QDisk
  extend self

  def print(results, op, options = {})
    return unless results
    return if results.empty?
    partitions, disks = results.partition {|x| x.partition?}
    partition_indent = disks.empty? ? 0 : 1

    all_cols = []

    if disks.empty?
      all_cols = partitions.map do |part|
        partition_get_cols(partition_indent, part, op, options)
      end
    else
      disks.each do |disk|
        all_cols << disk_get_cols(0, disk, op, options)
        partitions.select {|x| x.parent == disk.object_name}.each do |partition|
          all_cols << partition_get_cols(partition_indent, partition, op, options)
        end
      end
    end

    widths = col_widths(all_cols)

    # expand widths to match
    new_widths = widths
    while new_widths.inject {|x,y| x + y} < 72
      widths = new_widths
      new_widths = widths.map {|x| x + 1}
    end

    all_cols.each do |part|
      emit_col(part, widths, op)
    end

  end

  def partition_get_cols(indent, partition, op, options)
    print_common(indent, partition, op, options) do |values|
      cols = [:type, :mount_paths, :mounted_by_uid]
      values + cols.map do |method|
        partition.send(method).to_s
      end
    end
  end

  def disk_get_cols(indent, disk, op, options)
    print_common(indent, disk, op, options)
  end

  private
  def print_common(indent, device, op, options, &block)
    values = [("  " * indent) + device.device_name]
    return values if options.fetch(:short, false)
    return block.call(values) if block
    return values
  end

  def col_widths(cols)
    lengths = cols.map do |arr|
      arr.map {|x| x.length + 2} # allow for space padding
    end

    # find longest lengths
    lengths.inject do |xarr, yarr|
      # create new array z of pairs of [x[0],y[0], ..x[n],y[n]]
      zarr = if xarr.length > yarr.length
        xarr.zip(yarr)
      else
        yarr.zip(xarr)
      end
      # then replace with the largest of each
      zarr.map do |x,y|
        if y.nil? or x > y
          x
        else
          y
        end
      end
    end
  end

  def emit_col(part, widths, op)
    row = part.enum_for(:each_with_index).map do |col, ix|
      format("%-#{widths[ix] - 1}s", col)
    end
    op.puts(row.join(" ").rstrip)
  end

end
