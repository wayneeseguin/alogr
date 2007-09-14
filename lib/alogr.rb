class AlogR

  Levels = { :emergency => 0, :alert => 1, :critical => 2, :error => 3, :warning => 4, :notice => 5, :info => 6, :debug => 7 }

  class << self
    attr_accessor :default_log_level
  end

  def initialize(options = {})
    puts "In Ruby initialize method"
    case options
    when String:
      options = {:log => options}
    when Hash: 
      options[:log] ||= "log/alogr.log"
    else
      raise "AlogR: Invalid configuration"
    end

    default_log_level = options[:default_log_level] || :info
    
    AlogR::Levels.keys.each do | key |
      file_name = options[key] || options[:log]
      $alogr_log_files[AlogR::Levels[key]] = file_name
      system("mkdir -p #{File.dirname(file_name)} ; touch #{file_name}")
    end

    init_munchers

  end

  def log(string, level = default_log_level)
    $alogr_buffer << [level, string]
    signal_munchers
  end

end

require "alogr_ext"

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
