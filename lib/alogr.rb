require "aio_logger"

module AlogR
  Levels = { :emergency => 0, :alert => 1, :critical => 2, :error => 3, :warning => 4, :notice => 5, :info => 6, :debug => 7 }
  
  class Logger

    class << self
      attr_accessor :default_log_level
    end

    def initialize(options = {})
      puts "In Ruby initialize method"
      case options
      when String:
        options = {:log => options}
      when Hash: 
        options[:log] ||= "log/default.log"
      else
        raise "AlogR: Invalid configuration"
      end

      @log_interval = options[:log_interval] || 0.01

      default_log_level = options[:default_log_level] || :info

      AlogR::Levels.keys.each do | key |
        file_name = options[key] || options[:log]
        $alogr_log_files[AlogR::Levels[key]] = file_name
        system("mkdir -p #{File.dirname(file_name)} ; touch #{file_name}")
      end

      Thread.abort_on_exception = true
      Thread.new do
        loop do
          sleep( @log_interval )
          flush_log_buffer
        end
        Thread.exit
      end
    end

    def log(string, level = default_log_level)
      $alogr_buffer << [level, string]
    end

    def method_missing(meth, *options)
      puts "method: #{meth.inspect}, options: #{options.inspect}"
      if AlogR::Levels.include?( meth )
        log(meth, options.first)
      else
        super.method_missing(meth, *options)
      end
    end

  end
end

require "alogr/version"

class Object

  def log(level = :info)
    if self.class == String
      if AlogR::Levels.has_key?(level)
        $logger.log(self, AlogR::Levels[level])
      else
        raise "Error: No such log level #{level}"
      end
    else
      self.to_s.log
    end
    self
  end

end
