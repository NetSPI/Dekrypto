class Utilities
 def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.file = ""
    options.threadsize = 1
    options.sortfile = false
    options.verbose = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: Demo.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"

      # Sort temprary results
      opts.on("-s", "--sort", "Sort temporary results") do |s|
        options.sortfile = s
      end

      # Verbose
      opts.on("-v", "--verbose", "Show debug messages") do |v|
        options.verbose = v
      end

      # Threadpool size
      opts.on("-t", "--threads SIZE", "Set threadpool size") do |size|
        options.threadsize = Integer(size)
      end

      # Save to file
      opts.on("-f", "--file FILE","Save temporary results to file") do |file|
        options.file = file
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
    opt_parser.parse!(args)
    options
  end

  def self.parse_sessionfile(file)
    results=[]
    begin
      text=File.open(file).read
      text.force_encoding('UTF-8').gsub!(/\r\n?/, "\n")
      text.each_line do |line|
      results[Integer(line.split(',',2)[0])]=line.split(',',2)[1].gsub("\n","")
      end
    return results
    end
  rescue
    File.open(file, 'w') do |f|
    end
    end

  def self.sort_sessionfile(file)
    results=[]
    text=File.open(file).read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      results[Integer(line.split(',',2)[0])]=line.split(',',2)[1]
    end
    File.open(file, 'w') do |f|
    end
    results.each_with_index do |result,i|
      File.open(file, 'a') do |f|
        if (result.nil?)
          f << "#{i},\n"
        else
          f << "#{i},#{result}"
        end
      end
    end
  end

end