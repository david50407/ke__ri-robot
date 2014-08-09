# encoding: utf-8
require './kekeri.rb'

instance = KeKeRi.new

puts instance.addPlurk <<-END, qualifier: 'feels'
今日ㄎ_ㄖ指數
運輸工具ㄎ_ㄖ：(bz)
天氣ㄎ_ㄖ：(bz)、運氣ㄎ_ㄖ：(bz)
宅氣ㄎ_ㄖ：(bz)、機械ㄎ_ㄖ：(bz)
地牛ㄎ_ㄖ：(bz)、身材ㄎ_ㄖ：(bz)
--
紅色：極為ㄎ_ㄖ、藍色：還滿ㄎ_ㄖ
綠色：略為ㄎ_ㄖ、黑色：極不ㄎ_ㄖ
END
