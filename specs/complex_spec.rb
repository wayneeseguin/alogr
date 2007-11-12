require "spec_helper"

describe AlogR, "for exactly two logs" do

  it "should log to many logs, as specified to the initialization."

  before do
    FileUtils::rm_rf @log_dir

    @log_dir = File.join(Dir.pwd, "log")
    @default_log_file = File.join(@log_dir, "default.log")
    @error_log_file = File.join(@log_dir, "error.log")
    $logger = AlogR::Logger.new(:log => @default_log_file, :error => @error_log_file)
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

end

describe AlogR, "for more than two logs" do

end
