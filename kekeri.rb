# encoding: utf-8
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
				if plurk["owner_id"] == 5845208
					next unless responsed? plurk["plurk_id"]
					responsePlurk plurk["plurk_id"], "ㄎ__ㄖ"
					@plurkApi.post '/APP/Timeline/mutePlurks', ids: [[plurk["plurk_id"]]]
				elsif plurk["content"].match /ㄎ[_＿]*ㄖ/
					next unless responsed? plurk["plurk_id"]
					responsePlurk plurk["plurk_id"], "ㄎ__ㄖ"
					@plurkApi.post '/APP/Timeline/mutePlurks', ids: [[plurk["plurk_id"]]]
				end
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
			if plurk["owner_id"] == 5845208
				next unless responsed? plurk["plurk_id"]
				responsePlurk plurk["plurk_id"], "ㄎ__ㄖ"
				@plurkApi.post '/APP/Timeline/mutePlurks', ids: [[plurk["plurk_id"]]]
			elsif plurk["content"].match /ㄎ[_＿]*ㄖ/
				next unless responsed? plurk["plurk_id"]
				responsePlurk plurk["plurk_id"], "ㄎ__ㄖ"
				@plurkApi.post '/APP/Timeline/mutePlurks', ids: [[plurk["plurk_id"]]]
			end
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
			return false if res["user_id"] == 10428113 && res["content_raw"] == "ㄎ__ㄖ"  #<--- 10428113 robot id
		end
		true
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
