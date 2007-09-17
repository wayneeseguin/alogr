#require "lib/alogr"

describe "AlogR" do
  before :each do
    puts( "Removing log/ directory\n" )
    system("rm -rf log/")
    
    puts( "Creating new logger with a default and error log. \n" )
    $logger = AlogR.new(
    :log => "#{Dir.pwd}/log/default.log",
    :error => "#{Dir.pwd}/log/error.log"
    )
  end

  it "should create log/ then create and log to the files specified as a hash list :log => 'default.log', :error => 'error.log'" do
    File.exists?("log") and File.exists?("log/default.log") and File.exists?("log/error.log") 
  end

  it "should log messages to the error log when '.log(:error)' is called" do
    "This should go to the error log.".log(:error)

    File.read("log/error.log").strip.should eql("This should go to the error log.")
  end
  
  it "should log to the default log if no log level is specified" do
    "This should go to the default log.".log

    File.read("log/default.log").strip.should eql("This should go to the default log.")    
  end
end