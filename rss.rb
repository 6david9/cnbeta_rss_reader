require 'nokogiri'
require 'date'
require 'rainbow/ext/string'
require 'open-uri'

RSSArticle = Struct.new(:title, :link, :pub_date, :desc) do
	def inspect
		"#{title}\n#{link}\n#{pub_date}\n#{desc}\n"
	end
end

class RssParser
	def self.parse(rss)
		xml_doc = Nokogiri::XML(rss)
		items = xml_doc.css('channel>item')

		parsed_items = []

		items.each do |item|
			title = item.at_xpath('title').inner_html
			link = item.at_xpath('link').inner_html
			pub_date = DateTime.parse( item.at_xpath('pubDate').inner_html )
			desc = item.at_xpath('description').inner_html.gsub!(/<\/?\w+?\/?>/, '')

			parsed_items << RSSArticle.new(title, link, pub_date, desc)
		end

		parsed_items
	end
end

class RssManager

	def initialize(rss)
		@rss = RssParser.parse(rss)
		@index = 0
	end

	def reset
		@index = 0
	end

	def show_next_page(count = 10)
		start_index = @index
		end_index = (@index + count <= @rss.size) ? @index + count : @rss.size

		rss = @rss[start_index ... end_index]
		show_rss_items(rss, @index)
		@index = @index + count
	end

	def show_all
		show_rss_items(@rss)
	end

	def show_rss_items(items, showing_index = 0)
		return if items.nil?

		index = showing_index
		items.each do |item|
			print index.to_s + ". "
			puts item.title.color(:red) + " | " + item.pub_date.to_time.localtime.to_s[0...19]
			index = index + 1
		end
	end

	def show_desc(index)
		if index >= @rss.size
			puts "index #{index} out of range, max #{@rss.size-1}" 
			return false
		end
		
		item = @rss[index]
		puts item.desc
	end

	def open_index(index)
		item = @rss[index]

		`open #{item.link}` unless item.nil?
	end
end

class RssTerminal

	READ_COUNT = 20

	def self.run!(rss_url)
		f = open(rss_url)
		rss_manager = RssManager.new(f)
		f.close

		# 先显示 READ_COUNT 行
		rss_manager.show_next_page(READ_COUNT)

		loop do

			printf "options: "

			options = gets()
			parsed_options = options.split(/\s+/)

			case parsed_options.shift
			when 'n', 'next' # 下一页
				count = parsed_options.first.nil? ? READ_COUNT : Integer(parsed_options.shift)
				rss_manager.show_next_page(count)

			when 'a', 'all' # 显示全部
					rss_manager.show_all()

			when 'd', 'desc'
				index = Integer(parsed_options.shift)
				rss_manager.show_desc(index)

			when 'o', 'open' # 在浏览器中打开
				index = Integer(parsed_options.shift)
				rss_manager.open_index(index)

			when 'r', 'reset'
				rss_manager.reset
				rss_manager.show_next_page(READ_COUNT)
				
			when 'e', 'exit' # 退出
				break
			end

		end # loop
	end # self.run

end