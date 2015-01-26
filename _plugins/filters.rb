# coding: utf-8
module Jekyll
  module Filters
    def date_normal(input)
      time(input).strftime("%Y年%-m月%-d日")
    end
  end
end

#Liquid::Template.register_filter(Jekyll::Filters)
