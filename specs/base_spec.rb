require "spec_helper"

describe "AlogR" do

  before do
    @log_dir = File.join Dir.pwd, "log"
    @log_file = File.join @log_dir, "default.log"
  end

  after do
    FileUtils::rm_rf @log_dir
  end
  
  it "should create a global array $alogr_buffers" do
    $alogr_buffers.should == []
  end

  it "should create global array $alogr_log_files" do
    $alog_log_files.should == []
  end
  
  it "including AlogR should define Kernel#log" do
    Kernel.should respond_to(:log)
  end
  
  it "should create a log directory and log file when 'log/default.log' is passed in" do
    $logger = AlogR::Logger.new @log_file
    true.should == File.directory?(@log_dir)
  end

  it "should create a log to the file specified as a string" do
    $logger = AlogR::Logger.new @log_file
    true.should == File.file?(@log_file)
  end

  it "should create a log to the file specified as a hash :log => 'spec.log'" do
    $logger = AlogR::Logger.new :log => @log_file
    true.should == File.file?(@log_file)
  end

end
