# Example 2
require "lib/alogr"
$logger = AlogR.new(
:log => "/Users/wayne/projects/ruby/alogr/trunk/log/production.log", 
:error => "/Users/wayne/projects/ruby/alogr/trunk/log/error.log",
:info => "/Users/wayne/projects/ruby/alogr/trunk/log/info.log"
)
"this should go to info log".log
sleep(1)
"this should go to error log".log(:error)
sleep(1)
"this should go to production log".log(:warning)
sleep(2)
