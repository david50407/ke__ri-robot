require './setting.rb'
CONVERTS = {
	:APIKEY => :api_key,
	:APISECRET => :api_secret,
	:TOKENKEY => :token_key,
	:TOKENSECRET => :token_secret
}

@setting = Setting.new false

def read
	puts "Reading old settings..."
	IO.readlines(@setting.filename).each do |line|
		Setting::REGEXP_SETTING_PAIR.match line.chomp do |md|
			old_key = md[:key].to_sym
			new_key = CONVERTS[old_key]
			value = md[:value]
			@setting[new_key] = value if CONVERTS.keys.include? old_key
		end																																																																
	end
end

def check
	puts "Settings are converting to new version below:"
	puts @setting.to_s
	print "Save it [y/N]? "
	act = gets.chomp
	if act == "y" or act == "Y"
		puts "Saving..."
		@setting.write!
		puts "Saved! You can start ke__ri robot now!"
	else
		puts "ABORT! If you sure to convert old settings, run again this script and type 'y'."
	end
end

read
check
