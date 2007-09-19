require "lib/alogr"

describe "AlogR" do
  before :each do
    puts "Removing log/ directory"
    system("rm -rf log/")
  end
  
  it "should create two global array variables: $alogr_buffer and $alog_log_files" do
    $alogr_buffer.should eql([]) and $alog_log_files.should eql([])
  end
  
  it "should define a new method Object#log" do
    Object.should respond_to(:log)
  end

  it "should create log/ then create and log to the file specified as a string" do
    $logger = AlogR.new("#{Dir.pwd}/log/default.log")
    File.exists?("log") and File.exists?("log/default.log") 
  end

  it "should create log/ then create and log to the file specified as a hash :log => 'spec.log'" do
    $logger = AlogR.new(:log => "#{Dir.pwd}/log/default.log")
    File.exists?("log") and File.exists?("log/default.log") 
  end
end