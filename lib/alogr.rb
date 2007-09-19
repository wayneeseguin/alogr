require "aio_logger"

module AlogR
  
  Levels = { :emergency => 0, :alert => 1, :critical => 2, :error => 3, :warning => 4, :notice => 5, :info => 6, :debug => 7 }
  
  class Logger

    class << self
      attr_accessor :config
      
      def log( string, level = ( config[:default_log_level] || :info ) )
        level = AlogR::Levels[level] if AlogR::Levels.has_key?( level )
        $alogr_buffer << [config[:newline] ? (string << "\n") : string, level]
      end

      def method_missing( method, *options )
        if AlogR::Levels.include?( method )
          log( method, options.first )
        else
          super.method_missing( method, *options )
        end
      end
      
    end

    def initialize( options = {} )
      
      if options.class ==  String
        options = { :log => options }
      elsif options.class == Hash
        options[:log] ||= "log/default.log"
      else
        raise "AlogR: Invalid configuration"
      end
      
      config = options

      AlogR::Levels.keys.each do | key |
        file_name = options[key] || options[:log]
        $alogr_log_files[AlogR::Levels[key]] = file_name.freeze
        # TODO: Verifiy valid filename, if not raise an error
        system("mkdir -p #{File.dirname(file_name)} ; touch #{file_name}")
      end
      
      Object.logger = self # This becomes the default logger
      
      Thread.abort_on_exception = true
      Thread.new do
        loop do
          sleep( config[:log_interval] || 0.25 )
          flush_log_buffer
        end
        Thread.exit
      end

      self
    end
    
  end
end

class Object
  class << self
    attr_accessor :logger
  end

  def log(*args) # level = :info
    Object.logger ||= AlogR::Logger.new
    
    if self.class == String
      require "ruby-debug" and debugger
      level = args.first || :info
      unless AlogR::Levels[level].nil?
        Object.logger.log(self, AlogR::Levels[level])
      else
        raise "Error: No such level: #{level}"
      end
    else
      self.to_s.log
    end
    self
  end

end

at_exit do
  sleep(1) # Allow log buffer to get emptied
end
