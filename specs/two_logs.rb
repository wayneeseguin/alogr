require "alogr"

describe "AlogR" do

  after do
    FileUtils::rm_rf @log_dir
  end

  before do
    @log_dir = File.join Dir.pwd, "log"
    @default_log_file = File.join @log_dir, "default.log"
    @error_log_file = File.join @log_dir, "error.log"
    $logger = AlogR::Logger.new :log => @default_log_file, :error => @error_log_file
  end

  it "should create the default and error log files and the log dir" do
    true.should == File.directory?("log") and
      true.should == File.file?("log/default.log") and 
      true.should == File.file?("log/error.log") 
  end

  it "should log messages to the error log when '.log(:error)' is called" do
    message = "This should go to the error log."
    message.log :error
    contents = open(@error_log_file) { |io| io.read }
    contents.should =~ /#{ Regexp.escape message }/
  end
  
  it "should log to the default log if no log level is specified" do
    pending 'aio_logger.so tries to lookup undefined symbol: aio_writer64' do
      message = "This should go to the default log."
      message.log
      contents = open(@default_log_file) { |io| io.read }
      contents.should =~ /#{ Regexp.escape message }/
    end
  end

end
