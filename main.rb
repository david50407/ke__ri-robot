# encoding: utf-8
require './kekeri.rb'

instance = KeKeRi.new

# Thread.new {
#   while true
#     begin
#       instance.acceptAllFriends
#       sleep 30
#     rescue
#       sleep 10
#       retry
#     end
#   end
# }
Thread.new {
	begin
		instance.listenChannel while true
	rescue
		retry
	end
}

# check unreadPlurk once on start
begin
	instance.checkUnreadPlurk
rescue
	puts %(#{Time.now.to_s} [ERROR] Checking unread plurk has error: #{$!.to_s})
end

while true
	case gets.chomp
	when "check"
		p instance.checkUnreadPlurk
	when "get"
		p instance.getUnreadPlurk
	when "close"
		exit
	end
end
