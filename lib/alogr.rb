require "aio_logger"
# require "yaml"

module AlogR
  
  Levels = { :emergency => 0, :alert => 1, :critical => 2, :error => 3, :warning => 4, :notice => 5, :info => 6, :debug => 7 }
  
  class Logger

    @@config = {}

    def initialize( options = {} )
      # TODO: Load config from YAML file, if :config has a valid filename and is valid yaml, 
      #       fallback to options hash values
      if options.class ==  String
        options = { :log => options }
      elsif options.class == Hash
        options[:log] ||= "log/default.log"
      else
        raise ArgumentError, "Invalid configuration specified"
      end
      
      @@config = options
      @@config[:line_ending] = options[:line_ending] || "\n" unless options[:newline] == false

      AlogR::Levels.keys.each do | key |
        file_name = options[key] || options[:log] || options[:default]
        $alogr_log_files[AlogR::Levels[key]] = file_name.freeze
        # TODO: Verifiy valid filename, if not raise an error
        system( "mkdir -p #{File.dirname(file_name)} ; touch #{file_name}" )
      end
      
      Object.logger = self # This becomes the default logger
      
      Thread.abort_on_exception = true
      Thread.new do
        loop do
          sleep( @@config[:log_interval] || 0.25 )
          packet = $alogr_buffer.shift
          while !packet.nil? do
            string = packet.shift
            level = packet.shift
            puts "packet: string: #{string}, filename: #{$alogr_log_files[level]ma}"
            aio_log( string, $alogr_log_files[level])
            packet = $alogr_buffer.shift
          end 
          #unless flush_log_buffer
          #  raise "Unable to open a log file" # TODO: Be more specific
          #end
        end
        Thread.exit
      end
      
      #at_exit do
      #  sleep(@@config[:log_interval].to_f * 1.2) # Allow log buffer to get emptied before exiting
      #end
      
      self
    end

    def buffer( string, level = ( @@config[:default_log_level] || :info ) )
      level = AlogR::Levels[level] if AlogR::Levels.has_key?( level )
      string << @@config[:line_ending]
      $alogr_buffer << [ string, level ]
    end

    def method_missing( method, *options )
      if AlogR::Levels.include?( method )
        log( options.first, method )
      else
        super.method_missing( method, *options )
      end
    end    
    
  end
end

class Object
  class << self
    attr_accessor :logger
  end

  def log( *args )
    Object.logger ||= AlogR::Logger.new
    
    if self.class == String
      level = args.first || :info
      unless AlogR::Levels[level.to_sym].nil?
        Object.logger.buffer( self, AlogR::Levels[level.to_sym] )
        self
      else
        raise ArgumentError, "Error: No such level: #{level}"
      end
    else
      if args.first.class == String
        args.first.log args[1]
      else
        self.to_s.log
      end
      self
    end
  end

end
