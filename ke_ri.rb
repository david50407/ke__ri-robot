# encoding: utf-8
require './plurk.rb'
require './setting.rb'
require 'time'
require 'net/http'
#Setup OAuth client by create a instance of Plurk class
puts @setting = Setting.new #read setting file
$plurk = Plurk.new(@setting.api_key, @setting.api_secret)
$plurk.authorize(@setting.token_key, @setting.token_secret)

$prevent_flag = true

def getChannel
	begin
	resp = $plurk.post("/APP/Realtime/getUserChannel")
	rescue Timeout::Error
		sleep 2 # let it take a rest
		retry
	end
	if resp["comet_server"].nil?
		puts 'Failed to get channel.'
		return false
	end
	$channelUri = resp["comet_server"]
	$channelName = resp["channel_name"]
	$channelOffset = -1
	puts 'Get channel uri: ' + $channelUri
	puts 'Get channel name: ' + $channelName
	return true
end

getChannel while $channelUri.nil?

REGEXP_CHANNEL = /^CometChannel\.scriptCallback\((.*)\);/
def listenChannel
	getChannel if $channelOffset == -3
	params = { :channel => $channelName, :offset => $channelOffset }
	params = params.map {|k,v| "#{k}=#{v}" }.join('&')
	uri = URI.parse($channelUri + "?" + params)
	http = Net::HTTP.new(uri.host, uri.port)
	http.read_timeout = 170
	retryGetting = 0
	begin
	res = http.start { |h|
			h.get(uri.path+"?"+params)
	}
	rescue
		retryGetting += 1
		sleep 3
		if retryGetting == 5
			getChannel
			return false
		end
		retry
	end
	res = REGEXP_CHANNEL.match res.body
	json = JSON.parse res[1]
	
	readed = []
	$channelOffset = json["new_offset"].to_i
	return if json["data"].nil?

	puts json["data"]
	json["data"].each do |plurk|
		case plurk["type"]
		when "new_response"
		when "new_plurk"
			if plurk["owner_id"] == 5845208
				next unless checkresponse plurk["plurk_id"]
				responsePlurk(plurk["plurk_id"],"ㄎ__ㄖ")
				$plurk.post('/APP/Timeline/mutePlurks', ids: plurk["plurk_id"])
			elsif plurk["content"].match /ㄎ[_＿]*ㄖ/
				next unless checkresponse plurk["plurk_id"]
				responsePlurk(plurk["plurk_id"],"ㄎ__ㄖ")
				$plurk.post('/APP/Timeline/mutePlurks', ids: plurk["plurk_id"])
			end
		end
	end
end

def addPlurk(t,p)
	if p==nil
		ti = Time.now
		json = nil
		begin
			$prevent_flag = false
			json = $plurk.post('/APP/Timeline/plurkAdd', {:content=>t.to_s, :qualifier=>':'})
			$prevent_flag = true
		rescue
			ti = Time.now
			s = ti.to_s + "addplurk has error" + "\n" + $!.to_s
			print s + "\n"
			recordError s
			if json != nil
				if json.key?("error_text")
					if json["error_text"] == "anti-flood-too-many-new"
						ti = Time.now
						s = ti.to_s + "too many new"
						print s + "\n"
						recordError(s)
						
						
					end
					return json
				end						
			end
			ti = Time.now
			s = ti.to_s + "addplurk will retry in 120 secend"+"\n"
			print s + "\n"
			recordError(s)
			sleep 120
			retry
		end
		ti = Time.now
		p ti.to_s + " addplurk"
		print "\n"
		p t
		print "\n"
		p json
		print "\n"
		return json
		
	else
		addprivatePlurk(t,p)
	end
	
end

def addprivatePlurk(t,user_id)
	
	ti = Time.now 
	begin
		json = $plurk.post('/APP/Timeline/plurkAdd', {:content=>t.to_s, :qualifier=>':',:limited_to => [user_id]})
	rescue
		print ti.to_s + "add private plurk ha error" + "\n" + $!.to_s + "\n" 
	end
	
	print ti.to_s + "addprivateplurk"
	print "\n"
	p json
	print "\n"
	
	
end

def responsePlurk(plurkid,text)
	
	t = Time.now
	begin
		res = $plurk.post('/APP/Responses/responseAdd',{:plurk_id=>plurkid , :content=>text , :qualifier=>':'})
	rescue
		print t.to_s + "response plurk ha error" + "\n" + $!.to_s + "\n"
	ensure
		p t.to_s + "addres"+"\n"
		p text
		print"\n"
		p res
		print "\n"
	end
end

def getUnreadPlurk
	
	begin 
		json = $plurk.post('/APP/Timeline/getUnreadPlurks')
	rescue
		print "get unread plurk has error" + "\n" + $!.to_s + "\n"
		sleep 5
		retry
	end
	
	return json
end


def checkresponse(plurkid)
	
	json = nil
	begin
		json = $plurk.post('/APP/Responses/get',{:plurk_id=>plurkid})
	rescue
		print "get response has error"+"\n" + $!.to_s + "\n"
		sleep 5
		retry
	end
	i = true
	json["responses"].each{|res|
	
		if res["user_id"]==10428113 && res["content_raw"]=="ㄎ__ㄖ"  #<--- 10428113 robot id
			i = false	
		end
	}
	return i

end

def checkUnreadPlurk
	json = $plurk.post('/APP/Timeline/getUnreadPlurks', limit: 20)
	return if json["plurks"].nil?

	json["plurks"].each do |plurk|
		if plurk["owner_id"] == 5845208
			next unless checkresponse plurk["plurk_id"]
			responsePlurk(plurk["plurk_id"], "ㄎ__ㄖ")
			$plurk.post('/APP/Timeline/mutePlurks', ids: plurk["plurk_id"])
		elsif plurk["content"].match /ㄎ[_＿]*ㄖ/
			next unless checkresponse plurk["plurk_id"]
			responsePlurk(plurk["plurk_id"], "ㄎ__ㄖ")
			$plurk.post('/APP/Timeline/mutePlurks', ids: plurk["plurk_id"])
		end
	end
end

def checkAlerts  # not finish
	
	alert = $plurk.post('/APP/Alerts/getActive')
	
	alert.each{|ale|
		print ale
		print "\n"
		print "------------------------"
		print "\n"
	}
	
end

def recordError(text)
	begin
		re = File.open("./record","a+")
		re.write(text + "\n")
		re.write("==============================="+"\n")
		re.close
	rescue
		print "record file has error" + $!.to_s + "\n"
	end
end

print "ke ke ri robot start"+"\n"

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
    listenChannel while true
  rescue
    retry
  end
}

# check unreadPlurk once on start
begin
	checkUnreadPlurk
rescue
	print Time.now.to_s + "checkcmd has errer" + "\n" + $!.to_s + "\n"
end

while true
	case gets.chomp
		when "check"
			p checkUnreadPlurk
		when "get"
			p getUnreadPlurk
		when "close"
			break
	end
end
