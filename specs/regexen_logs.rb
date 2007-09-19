require "lib/alogr"

describe "AlogR" do
  before do
    puts "Removing log/ directory"
    system("rm -rf log/")
  end
  
  it "should log to logs based on a RegExp, as specified to the initialization." do
  end
end