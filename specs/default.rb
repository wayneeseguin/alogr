#require "lib/alogr"

describe "AlogR" do
  before do
    puts "Removing log/ directory"
    system("rm -rf log/")
  end
  
  it "should create a default log 'log/default.log' from the current directory." do
    $logger = AlogR.new
    File.exists?("log") and File.exists?("log/default.log") 
  end
end