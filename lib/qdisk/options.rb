module QDisk

  def parse_options(args)

    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: qdisk [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
      opts.on("-n", "--[no-]act", "Don't take any action") do |v|
        options[:no_act] = v
      end
      opts.on("--best", "Best guess match") do |v|
        options[:best] = v
      end

      opts.on("--query=[query]", "query parameters") do |v|
        options[:query] ||= []
        options[:query] << v
      end
    end
    args = parser.parse(args)
    [options, args]

  rescue OptionParser::ParseError => e
    puts(e.message)
    puts(parser)
    raise
  end

end
