module QDisk

  class OptionQuery
    @@values = /(interface|device|usage|type|uuid|label)=([^,]+)/
    @@predicates = /(removable|mounted|read_only|readonly)/
    @@match = Regexp.union(@@values, @@predicates)

    def self.match(args)
      any_bad = args.split(',').find do |x|
        match = @@match.match(x)
        if match and match[0] == x
          false # matched entire section
        else
          true #bad
        end
      end

      if any_bad
        ""
      else
        args
      end
    end

    def self.convert(args)
      args.split(',').map do |q|
        if q =~ @@values
          [$1.to_sym, $2]
        elsif q =~ @@predicates
          pred = $1
          pred = 'read_only' if pred == 'readonly'
          (pred + '?').to_sym
        else
          raise InvalidArgument, q
        end
      end
    end

  end

  def parse_options(args)

    commands = ['unmount', 'cp', 'wait', 'query']

    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: qdisk command [options]"
      opts.version = QDisk::VERSION

      opts.separator ""
      opts.separator "Commands are #{commands.map{|x| "'" + x + "'"}.join(', ')}"
      opts.separator ""
      opts.separator "Query options:"

      opts.accept(OptionQuery, OptionQuery)

      opts.on("--query=query", OptionQuery, "query parameters") do |v|
        options[:query] ||= []
        options[:query].concat(v)
      end

      opts.on("--best", "Best guess match") do |v|
        options[:best] = v
      end

      opts.separator "Controlling cardinality:"

      opts.on("--multi", "Allow more than one result") do |v|
        options[:only] = v
      end
      opts.on("--only", "Error if more than one queried", "Default for 'cp', 'unmount'") do |v|
        options[:only] = v
      end

      opts.separator "Controlling time:"

      opts.on("--timeout=timeout", Float, "Fail if operation takes longer than ", "'timeout' seconds. Decimals allowed") do |v|
        options[:timeout] = v
      end

      opts.separator ""
      opts.separator "Common options:"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
      opts.on("-n", "--[no-]act", "Don't take any action") do |v|
        options[:no_act] = v
      end

    end

    args = parser.parse(args)
    if args.length == 0
      raise MissingRequiredArgument.new('command', parser.to_s)
    elsif ! commands.member?(args.first)
      raise UnknownCommand.new(args.first, parser.to_s)
    end
    [options, args]

  rescue OptionParser::ParseError => e
    puts(e.message)
    puts(parser)
    raise
  end

end
