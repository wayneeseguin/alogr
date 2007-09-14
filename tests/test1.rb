# Example 1
require "lib/alogr"
$logger = AlogR.new(:log => "/Users/wayne/projects/ruby/alogr/trunk/log/production.log")
"a test, should go to the logs 10 times\n".log.log.log.log.log.log.log.log.log.log
sleep(5)