require "fileutils"
require "alogr"

describe "AlogR" do

  before do
    @log_dir = File.join Dir.pwd, "log"
    @log_file = File.join @log_dir, "default.log"
  end

  after do
    FileUtils::rm_rf @log_dir
  end
  
  it "should create global array $alogr_buffer" do
    $alogr_buffer.should == []
  end

  it "should create global array $alogr_log_files" do
    $alog_log_files.should == []
  end
  
  it "should define Object#log" do
    Object.should respond_to(:log)
  end

  it "should create a log directory" do
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
