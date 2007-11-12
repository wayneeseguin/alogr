require "spec_helper"

describe AlogR, "configuration" do

  it "should accept configuration"

  it "should log to $STDOUT if no parameters are specified." do
    $logger = AlogR.new
    $logger.stream.should == $STDOUT 
  end

end
