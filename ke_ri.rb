# encoding: utf-8
require './plurk.rb'
require './setting.rb'
require 'time'
#Setup OAuth client by create a instance of Plurk class
settinginit() #read setting file
$plurk = Plurk.new(@setting["APIKEY"], @setting["APISECRET"])
$plurk.authorize(@setting["TOKENKEY"], @setting["TOKENSECRET"])
$mysite = @setting["MYSITE"]

$prevent_flag = true

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
	
		if res["user_id"]==9472755 && res["content_raw"]=="是 知道了"
			i = false	
		end
	}
	return i

end

def checkcommand()
	
	t = Time.now
	f = false
	json = nil
	begin 
		while true
			if $prevent_flag == true
				json = $plurk.post('/APP/Timeline/getPlurks',{:limit=>10})
				break
			end
		end
	rescue
		ss = to_s + "get plurk has error" + "\n" + $!.to_s
		print ss + "\n"
		#recordError(ss)
		sleep 5
		retry
	end	
	if json == nil
		print "get plurk return nil"+"\n"
		return json 
	end
	json["plurks"].each{|pl|
		if pl["owner_id"] == 8514425  #5845208  <---ㄎㄎㄖid
			
			responsePlurk(pl["plurk_id"],"UCCU")
		else 
			print("none\n")

		end
		
	}
	
	return f
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

Thread.new{
	while true
		t = Time.now
		begin
		#print "checkcommand start "+"\n"
		#checkcommand()
		#print "checkcommand end "+"\n"
		sleep 1
		rescue
		print t.to_s + "checkcmd has errer" + "\n" + $!.to_s + "\n"
		sleep 5
		retry
		end
	end
	
}

while true

	#cmd = gets.chomp	
	
	case gets.chomp

		when "check"
			p(checkcommand())
		
		when "get"
			print(getUnreadPlurk())
		
		when "close"
			break
	end

 end
