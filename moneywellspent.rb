#!/usr/bin/env ruby 
# encoding: utf-8

require 'rubygems'
require 'mechanize'

class MoneyWellSpent
  def self.usage()
    puts "moneywellspent.rb YEAR USERNAME PASSWORD"
    exit 1
  end

  def self.run()
    usage unless ARGV.length == 3
    year=ARGV[0]
    username=ARGV[1]
    password=ARGV[2]
    site="https://www.amazon.de/gp/css/order-history?opt=ab&digitalOrders=1&unifiedOrders=1&orderFilter=year-"+year

    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Firefox'
    agent.cookie_jar.clear!
    agent.follow_meta_refresh = true
    agent.redirect_ok = true

    puts "MoneyWellSpent"
    page = agent.get(site)
    login_form = page.form('signIn')
    login_form.email = username
    login_form.password = password

    puts "Logging in"
    page = agent.submit(login_form, login_form.buttons.last)

    print "Retrieving Orderhistory"
    arr=[]
    arr = page.parser.xpath('//*[@class="price"]').xpath('text()').to_a
    while !(page.link_with(:text => 'Weiter »').nil?)
      page = page.link_with(:text => 'Weiter »').click
      arr.concat(page.parser.xpath('//*[@class="price"]').xpath('text()').to_a)
      print "."
    end

    sum=0
    arr.each do |price|
      value = price.content.split(' ')[1].gsub(/\./, '').gsub(/,/, '.').to_f
      sum += value
    end
    puts
    puts sum.round(2)
  end
end

MoneyWellSpent.run
