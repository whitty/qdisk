require 'yaml'

module QDisk

  class Info

    class Disk

      def initialize(raw)
        data, tables = raw.split(/^=+$/, 2)
        tables = nil if tables =~ /\A\s+\z/

        @raw = raw
        @tables = tables

        lines = data.split("\n")
        @object_name = lines.shift
        @lines = parse(lines)
      end

      attr_reader :object_name, :device_name, :child_name, :tables, :raw

      private

      def parse(lines)
        rows = lines.map do |l|
          if l =~ /^( +)([^:]+):\s*(.*)/
            [$1.length / 2, $2, $3]
          else
            nil
          end
        end.select {|x| x}
        rows
      end
    end

    def self.load
      raw_entries = IO.popen(['udisks', '--dump']) do |f|
        f.read.split(/^=+\nShowing information for\s+/)
      end
      entries = []
      raw_entries.each do |x|
        entries << Disk.new(x) if x.length != 0
      end
      entries
    end
  end

end
