﻿# encoding: utf-8
require './plurk.rb'
require './setting.rb'
require 'time'
require 'net/http'

class KeKeRi
	REGEXP_CHANNEL = /^CometChannel\.scriptCallback\((.*)\);/
	attr_reader :setting

	def initialize
		@setting = Setting.new
		@plurkApi = Plurk.new(@setting.api_key, @setting.api_secret)
		@plurkApi.authorize(@setting.token_key, @setting.token_secret)
		puts "Ke Ke Ri Robot loaded."
	end

	def listenChannel
		getChannel while @channelUri.nil?
		getChannel if @channelOffset == -3
		params = { :channel => @channelName, :offset => @channelOffset }
		params = params.map { |k,v| "#{k}=#{v}" }.join('&')
		uri = URI.parse(@channelUri + "?" + params)
		http = Net::HTTP.new(uri.host, uri.port)
		http.read_timeout = 170
		retryGetting = 0
		begin
			res = http.start do |h|
				h.get(uri.path+"?"+params)
			end
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
		@channelOffset = json["new_offset"].to_i
		return if json["data"].nil?

		json["data"].each do |plurk|
			case plurk["type"]
			when "new_response"
			when "new_plurk"
				responseNewPlurk plurk
			end
		end
	end

	def addPlurk(content, options = {})
		options = { qualifier: ':', lang: 'tr_ch' }.merge options
		begin
			json = @plurkApi.post '/APP/Timeline/plurkAdd', options.merge(content: content)
		rescue
			str = %(#{Time.now.to_s} [ERROR] Adding plurk has error: #{$!.to_s})
			if json
				str << "(#{json["error_text"]})" if json.key? "error_text"
			end
			puts str
			sleep 120
			retry
		end
		return json
	end

	def addPrivatePlurk(content, user_id, options = {})
		options = { qualifier: ':', lang: 'tr_ch' }.merge options
		begin
			json = @plurkApi.post '/APP/Timeline/plurkAdd', options.merge(content: content, limited_to: [[user_id]])
		rescue
			str = %(#{Time.now.to_s} [ERROR] Adding private plurk has error: #{$!.to_s})
			if json
				str << "(#{json["error_text"]})" if json.key? "error_text"
			end
			puts str
			sleep 120
			retry
		end
	end

	def responsePlurk(plurk_id, content, options = {})
		options = { qualifier: ':', lang: 'tr_ch' }.merge options
		begin
			res = @plurkApi.post '/APP/Responses/responseAdd', options.merge(plurk_id: plurk_id, content: content)
		rescue
			puts %(#{Time.now.to_s} [ERROR] Responsing plurk has error: #{$!.to_s})
		end
	end

	def checkUnreadPlurk
		json = @plurkApi.post '/APP/Timeline/getUnreadPlurks', limit: 20
		return if json["plurks"].nil?

		json["plurks"].each do |plurk|
			responseNewPlurk plurk
		end
	end

	private

	def getUnreadPlurk
		begin 
			json = @plurkApi.post '/APP/Timeline/getUnreadPlurks'
		rescue
			puts %(#{Time.now.to_s} [ERROR] Getting unread plurks has error: #{$!.to_s})
			sleep 5
			retry
		end

		return json
	end

	def responsed?(plurk_id)
		begin
			json = @plurkApi.post '/APP/Responses/get', plurk_id: plurk_id
		rescue
			puts %(#{Time.now.to_s} [ERROR] Getting response has error: #{$!.to_s})
			sleep 5
			retry
		end
		json["responses"].each do |res|
			return false if res["user_id"] == 10428113 #<--- 10428113 robot id
		end
		true
	end

	UCCU_KE_EMOS = [
		[%(http://emos.plurk.com/c24f5a2d357cf6bed76097cb2917135c_w48_h48.jpeg)] * 10,
		[%(http://emos.plurk.com/c75c14b823b317b9485f551dc3be8adc_w48_h48.jpeg)] * 10,
		[%(http://emos.plurk.com/e01d1a6e849e6fc957a551fdc8f8d189_w48_h48.png)] * 10,
		[%(http://emos.plurk.com/4307884b41c65c081c00d7a707b3457a_w48_h48.png)] * 10,
		[%(http://emos.plurk.com/2ab4aa6dfacda9b2443a083915bef84f_w48_h48.jpeg --Double Kill--)] * 1
	].flatten
	UCCU_EMOS = %W(
		//emos.plurk.com/0ff9b6499d9fc067076299e4e84cb9f9_w48_h48.jpeg
		//emos.plurk.com/40727c48d696d04cbdc8461205e8d127_w48_h48.jpeg
		//emos.plurk.com/0dda843baf91d5fc522416746e470d8a_w43_h48.png
		//emos.plurk.com/0159d81c5f0d0eee1679d1546a16d430_w48_h48.jpeg
		//emos.plurk.com/d560946c25c7238688f1920de0127d33_w48_h48.jpeg
		//emos.plurk.com/54a61a948246082c94245b31fc3eb22f_w48_h48.jpeg
		//emos.plurk.com/4732b82e8d81f1a147cf5f32ea8f189e_w48_h48.jpeg
		//emos.plurk.com/df73fcc3007ead42cc871049677d5e58_w48_h48.jpeg
		//emos.plurk.com/a428060b74d0f7f46d72f50eb3ffe8e9_w48_h48.jpeg
		//emos.plurk.com/ce5f816d361977120209f9ecba5b5fc1_w48_h48.jpeg
		//emos.plurk.com/94accbcde00b9f8e85721a8df10b2acc_w48_h48.jpeg
		//emos.plurk.com/1815edc3b780b32136a10775878121d8_w48_h48.jpeg
		//emos.plurk.com/785a8439633d9cc2343bd0b25d4446b7_w48_h48.jpeg
		//emos.plurk.com/16b7f9906d55be0fabf3d0bbbd35d86a_w48_h48.jpeg
		//emos.plurk.com/7618969bf18f69f64db8e41750159c5a_w48_h48.jpeg
		//emos.plurk.com/fb20cd88b72e8af6378228d764b68996_w48_h48.jpeg
		//emos.plurk.com/266e229f51fb03183241c458c7ecd859_w48_h48.jpeg
		//emos.plurk.com/b3a65f97fb489e4e97c9f613d486bae7_w48_h48.gif
		//emos.plurk.com/b6fbf8deeb375f417ecb8e290bfd7ca5_w48_h48.jpeg
		//emos.plurk.com/c75c14b823b317b9485f551dc3be8adc_w48_h48.jpeg
		//emos.plurk.com/c24f5a2d357cf6bed76097cb2917135c_w48_h48.jpeg
		//emos.plurk.com/e01d1a6e849e6fc957a551fdc8f8d189_w48_h48.png
		//emos.plurk.com/2ab4aa6dfacda9b2443a083915bef84f_w48_h48.jpeg
		//emos.plurk.com/4307884b41c65c081c00d7a707b3457a_w48_h48.png
		//emos.plurk.com/2eed93c518b44ed937e1d8d82fe83fd5_w48_h48.jpeg
		//emos.plurk.com/738d3c68a21ef02777ea0f964d96e030_w48_h48.jpeg
	)
	def responseNewPlurk(plurk)
		return unless responsed? plurk["plurk_id"]
		resp = []
		case plurk["owner_id"]
		when 10428113 # bot id
			case plurk["content"]
			when /今日ㄎ_ㄖ指數/
				resp << "ㄎ＿ㄖ的粉專是「 https://www.facebook.com/IamMasterILoveLoly (無限期支持蘿莉控ㄎ＿ㄖ大濕) 」\n" + 
					"歡迎大家相邀厝邊頭尾、親朋好友及舊雨新知來按讚！ " + UCCU_KE_EMOS.sample
			end
		when 5845208 # andy810625
			if plurk["content"].match /無聊/
				responsePlurk(plurk["plurk_id"], "無聊嗎? 聽我講個笑話吧~ 有一個人叫ㄎ_ㄖ然後他就被ㄎ_ㄖ了...(lmao)", { qualifier: 'says' })
			else
				if rand(100) > 12
					resp << "ㄎ__ㄖ"
				else
					resp << "我說我是蘿莉控，當時是為了向這個社會證明雨神的ㄎㄖ是真的。\n" +
						"我這樣講，是為了整個ㄎㄖ神社的和諧，可是你今天在講我是蘿莉控的時候，你是在撕裂整個社會，謀的是你個人的政治利益。\n" +
						"我看待蘿莉控，跟看待你一樣，你們都是我的獵物。作為ㄎㄖ，你們都是獵物而已。"
				end
			end
		else # others
			case plurk["content"]
			when	/ㄎ[_＿]*ㄖ/
				resp << "ㄎ__ㄖ"
			when /UCCU/i, /<a[^>]*href="http:\/\/www.plurk.com\/andy810625"[^>]*>/ # @andy810625
				resp << UCCU_KE_EMOS.sample
			when *UCCU_EMOS.map { |uccu| /<img[^>]*src="[^"]*#{uccu}"[^>]*>/ }
				resp << UCCU_KE_EMOS.sample
			when /笑話/, /好笑/, /XD/i, /\/\/s\.plurk\.com\/92b595a573d25dd5e39a57b5d56d4d03\.gif/, /\/\/s\.plurk\.com\/615f18f7ea8abc608c4c20eaa667883b\.gif/, /\/\/s\.plurk\.com\/8600839dc03e6275b53fd03a0eba09cf\.gif/
				resp << "有一個人很機車，他就被騎走了，有一隻猴子叫ㄎㄖ，他就被……咦，我還以為我記得這個笑話說。"
			end
		end
		return if resp.empty?
		responsePlurk(plurk["plurk_id"], resp * " ")
		@plurkApi.post '/APP/Timeline/mutePlurks', ids: [[plurk["plurk_id"]]]
	end

	def getChannel
		begin
			resp = @plurkApi.post("/APP/Realtime/getUserChannel")
		rescue Timeout::Error
			sleep 2 # let it take a rest
			retry
		end
		if resp["comet_server"].nil?
			puts 'Failed to get channel.'
			return false
		end
		@channelUri = resp["comet_server"]
		@channelName = resp["channel_name"]
		@channelOffset = -1
		puts 'Get channel uri: ' + @channelUri
		puts 'Get channel name: ' + @channelName
		return true
	end
end
