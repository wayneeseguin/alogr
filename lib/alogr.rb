require "aio_logger"
# require "yaml"

module AlogR
  
  Levels =
  { 
    :name => { :emergency => 0, :alert => 1, :critical => 2, :error => 3, :warning => 4, :notice => 5, :info => 6, :debug => 7 },
    :id => { 0 => :emergency, 1 => :alert, 2 => :critical, 3 => :error, 4 => :warning, 5 => :notice, 6 => :info, 7 => :debug }
  }

  Version = "0.0.1"
  
  class Logger

    # hash of logs, keys are the handles (stdin, ), values are the objects
    attr_accessor :config
        
    def initialize(options = {})
      # Each log gets it's own buffer
      config = {}
      
      config[:log_level] = options[:log_level].to_i || Levels[:name][:info]
      
      if options == nil
        add_log(:default => $stdin)
      elsif options.class == String
        if options.match(/\.yml/)
          load_config(:yaml, options)
        else
          add_log(:default => options)
        end
      elsif options.class == Hash
        # allow for either specification of yaml or values right in the hash:
        # {:config => "config/alogr.yml"}
        # {:config => {:default => "log/default.log", :info => "log/info.log"}}
        # if options[:config] is set, read config yaml file
        if options[:config].nil?
          add_log(:default => $stdin)
        elsif options[:config].kind_of?(String)
          add_log(:default => options[:config])
        elsif options[:config].kind_of?(Hash)
          options[:config].each_pair do |key, value|
            add_log(key, value)
          end
        end
      else
        raise ArgumentError, "Invalid AlogR configuration specified"
      end

      # OLD:
      # AlogR::Levels.keys.each do | key |
      #   file_name = options[key] || options[:log] || options[:default]
      #   $alogr_log_files[AlogR::Levels[key]] = file_name.freeze
      #   # TODO: Verifiy valid filename, if not raise an error
      #   system( "mkdir -p #{File.dirname(file_name)} ; touch #{file_name}" )
      # end
      
      # TODO: Is "master" the best word?
      $logger = self unless options[:master] == false
      
      # This opt-in, so that AlogR can be used within frameworks.
      # Otherwise flush should be called manually
      threaded_worker if options[:thread]
      
      self # Return the newly configured logger so that it can be used
    end
    
    # Examples:
    # add(:info, "log/info.log")
    # add(:debug, "tmp/other_app.sock")
    # add(/paypal/,"log/paypal.log")
    # add(/asdf/,$stdout)
    def add_log(key, io)
      # TODO: create file and directory if missing
      if config[key]
        raise ArgumentError, "log key: #{key} already exists"
      else
        config[key] = {
          :buffer => [],
          :io => initialize_io(io)
        }
      end
    end
    
    def set_log(key,io)
      nuke_log(key)
      add_log(key,io)
    end
    
    def remove_log(key)
      if config.has_key?(key) && key != :default
        nuke_log(key)
      end
    end
    
    private

    def nuke_log(key)
      if config.has_key?(key)
        config[key][:io].close if config[key][:io].respond_to?(:close)
        config.delete(key)
      end      
    end
    
    def load_config(kind, config_file)
      if kind == :yaml
        unless File.exists(config_file)
          raise Exception, "Configuration file #{config_file} does not exist."
        end
        config = YAML.load_file(config_file)
        # Question: Should we detect if 'config_file' is a file or a stream and then call 
        # YAML.load_stream if it is a stream?
        if config.kind_of?(hash)
          config.each_pair do |key, value|
            add_log(key, value)
          end
        else
          raise Exception, "Specified yaml config file is not a hash."
        end
      else
        raise ArgumentError, "Invaid config file type."
      end
    end
    
    # Spin up a thread to process log buffers.
    def threaded_worker
      Thread.abort_on_exception = true
      Thread.new do
        loop do
          sleep(@@config[:log_interval] || 0.25)
          # TODO: re-write this to use new buffers
          # packet = $alogr_buffer.shift
          # while !packet.nil? do
          #   string = packet.shift
          #   level = packet.shift
          #   puts "packet: string: #{string}, filename: #{$alogr_log_files[level]}"
          #   aio_log( string, $alogr_log_files[level])
          #   packet = $alogr_buffer.shift
          # end
          
          #unless flush_log_buffer
          #  raise "Unable to open a log file" # TODO: Be more specific
          #end
        end

        Thread.exit
      end
      
      # When the thread exits
      #at_exit do
      #  sleep(@@config[:log_interval].to_f * 1.2) # Allow log buffer to get emptied before exiting
      #end      
    end
    
    # TODO: refactor buffer method to use new config
    def buffer(string, level = (@@config[:default_log_level] || :info))
      level = AlogR::Levels[level] if AlogR::Levels.has_key?(level)
      string << @@config[:line_ending]
      $alogr_buffer << [string, level]
    end

    def initialize_io(io)
      if io.class == String && File.exists?()
        File.open(io)
      elsif io.kind_of?(IO)
        io
      else
        raise ArgumentError, "Invalid IO specified."
      end
    end

    def flush(string, io)
      if io.respond_to?(:write_nonblock)
        io.write_nonblock(string) #@buffer.slice!(0..-1).to_s unless @buffer.size == 0
      else
        io.write(string) #(@buffer.slice!(0..-1).to_s) unless @buffer.size == 0
      end
    end

    def method_missing(method, *options)
      if AlogR::Levels.include?(method)
        log(options.first, method)
      else
        super.method_missing(method, *options)
      end
    end
    
  end
end

class Kernel
  class << self ; attr_accessor :logger ; end

  def log(*args)
    Kernel.logger ||= AlogR::Logger.new
    
    if self.class == String
      level = args.first || :info
      unless AlogR::Levels[level.to_sym].nil?
        Kernel.logger.buffer( self, AlogR::Levels[level.to_sym] )
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
