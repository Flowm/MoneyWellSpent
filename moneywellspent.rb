#!/usr/bin/env ruby
# encoding: utf-8

begin
  require 'rubygems'
  require 'optparse'
  require 'yaml'
  require 'highline/import'
  require 'mechanize'
  require 'bigdecimal'
  require 'logger'
rescue LoadError => err
  puts "Gem missing:\n #{err}"
  exit 1
end

# Logger
$log = Logger.new(STDOUT)
$log.level = Logger::INFO
$log.formatter = proc do |severity, datetime, progname, msg|
  "#{msg}"
end


class MoneyWellSpent
  def self.run()
    parseopts

    # Init
    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Firefox'
    agent.cookie_jar.clear!
    agent.follow_meta_refresh = true
    agent.redirect_ok = true

    $log.debug "DEBUG: Accessing #{@@cfg[:url]}\n"
    page = agent.get(@@cfg[:url])
    login_form = page.form('signIn')
    login_form.email = @@cfg[:login]
    login_form.password = @@cfg[:password]

    # Login
    $log.info "Logging in to amazon.#{@@cfg[:site]}\n"
    page = agent.submit(login_form, login_form.buttons.last)
    $log.debug "DEBUG: Page body\n#{page.body}\n"

    # Get first page of orders
    $log.info "Retrieving order history"
    xpath = '//div[@class="a-box a-color-offset-background order-info"]//div[@class="a-fixed-right-grid-col a-col-left"]'
    orders = page.parser.xpath(xpath).to_a
    if orders.empty?
      $log.warn "\nError retreiving orders or no orders available on " +
        "amazon.#{@@cfg[:site]} during #{@@cfg[:year]}\n" +
        "Is the supplied password correct?\n"
      exit 1
    end

    # Get remaining pages
    while !(page.link_with(:text => "#{@@cfg[:next]}→").nil?)
      page = page.link_with(:text => "#{@@cfg[:next]}→").click
      orders.concat(page.parser.xpath(xpath).to_a)
      print "." if $log.info?
    end
    $log.info "\n\n"

    # Parse order xml
    strdata = []
    orders.each do |order|
      strdata << order.xpath('./div/div/div[@class="a-row a-size-base"]/span[@class="a-color-secondary value"]').children.to_a.map do |val|
        val.text.gsub("\n", ' ').squeeze(' ').strip
      end
    end

    # Delocalization
    data = []
    strdata.each do |strdate, strprice|
      # Date delocalization
      if %w(de).include? @@cfg[:site]
        strdate.gsub!(/Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember/,
                   'Januar' => 'January',
                   'Februar' => 'February',
                   'März' => 'March',
                   'April' => 'April',
                   'Mai' => 'May',
                   'Juni' => 'June',
                   'Juli' => 'July',
                   'August' => 'August',
                   'September' => 'September',
                   'Oktober' => 'October',
                   'November' => 'November',
                   'Dezember' => 'December')
      end
      date = Date.parse(strdate)

      # Prize delocalization
      if %w(de fr).include? @@cfg[:site]
        strprice = strprice.gsub(/\./,'').scan(/EUR\s(\d+,\d\d)/).first.first.gsub(/,/, '.')
      elsif %w(com).include? @@cfg[:site]
        strprice = strprice.gsub(/,/,'').scan(/\$(\d+\.\d\d)/).first.first
      elsif %w(co.uk).include? @@cfg[:site]
        strprice = strprice.gsub(/,/,'').scan(/\£(\d+\.\d\d)/).first.first
      end
      price = BigDecimal(strprice)

      data << [date, price]
    end

    # Sort orders by date (data.reverse! would do the same in theory)
    data.sort! { |a,b| a.first <=> b.first }

    # Output
    sum = BigDecimal("0")
    data.each do |date, price|
      puts "#{date}   #{'%10.2f'%price}"
      sum += price
    end
    puts "Overall #{@@cfg[:year]}:#{'%10.2f'%sum}"

    # CSV
    if @@cfg[:csv]
      $log.info "\n"
      filepath = File.expand_path(@@cfg[:csv])
      begin
        $log.debug "Appending data to #{filepath}\n"
        file = File.new(filepath, 'a')
        data.each do |date, price|
          file.write "#{date};#{'%.2f'%price}\n"
        end
      rescue => e
        $log.fatal "Error writing csv #{filepath}.\n"
        $log.warn "#{e.message}\n"
        exit 1
      ensure
        file.close unless file.nil?
      end
      $log.info "Data successfully exported in csv format to #{filepath}\n"
    end
  end

  def self.parseopts()
    # Option/ configuration parsing

    # Parse the command line options
    attrs = {}
    options = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [OPTION]..."
      opts.separator "A script to summarize your money spent on Amazon"
      opts.separator "Options:"
      opts.on("-l [LOGIN]", "--login [LOGIN]",
        "Specify the username (e-mail) of your Amazon account") do |login|
        attrs[:login] = login
      end
      opts.on("-p [PASSWORD]", "--password [PASSWORD]",
        "Specify the password of your Amazon account") do |password|
        attrs[:password] = password
      end
      opts.on("-y [YEAR]", "--year [YEAR]",
        "Specify the year to be summed up") do |year|
        attrs[:year] = year
      end
      opts.on("-s [SITE]", "--site [SITE]",
        "Specify the site to be queried. " +
        "Currently amazon.{com,de,fr,co.uk} are supported") do |site|
        attrs[:site] = site
      end
      opts.on("-c [CSV]", "--csv [CSV]",
        "Export data to CSV") do |csv|
        attrs[:csv] = csv
      end
      opts.on("-d", "--debug", "Enable debug output") do
        $log.level = Logger::DEBUG
      end
      opts.on("-q", "--quiet", "Show less information") do
        $log.level = Logger::WARN
      end
      opts.on("-h", "--help", "Show this help") do
        puts options
        exit 0
      end
    end
    options.parse!

    # Read the default configuration file at ~/.moneywellspentrc
    configf = {}
    f = File.expand_path("~/.moneywellspentrc")
    if File.exist?(f)
      begin
        $log.debug "Loading configuration file #{f}\n"
        configf = YAML.load(File.read(f))
      rescue => e
        $log.warn "Error loading configuration file #{f}.\n"
        $log.info "#{e.message}\n"
        exit 1
      end
    else
      $log.info "No configuration file #{f} found. Asking interactively\n"
    end
    # Make sure configf["default"] exists
    configf["default"] ||= {}
    @@cfg = configf["default"].merge(attrs)

    # Ask for the settings if not given via command line or configuration file
    unless @@cfg[:site]
      $log.debug "No site given, asking"
      @@cfg[:site] = ask("Enter the site to be summed up:  ") { |q|
        q.echo = true
      }
    end
    unless @@cfg[:login]
      $log.debug "No logininfo given, asking"
      @@cfg[:login] = ask("Enter your #{@@cfg[:site]} username:  ") { |q|
        q.echo = true
      }
    end
    unless @@cfg[:password]
      $log.debug "No password given, asking"
      @@cfg[:password] = ask("Enter your #{@@cfg[:site]} password:  ") { |q|
        q.echo = "*"
      }
    end
    unless @@cfg[:year]
      $log.debug "No year given, asking"
      @@cfg[:year] = ask("Enter the year to be summed up:  ") { |q|
        q.echo = true
      }
    end

    # Site specific settings (URL + next_button)
    if %w(amazon.de amazn.de de).include? @@cfg[:site]
      @@cfg[:next] = "Weiter"
      @@cfg[:site] = "de"
    elsif %w(amazon.com amazn.com com us).include? @@cfg[:site]
      @@cfg[:next] = "Next"
      @@cfg[:site] = "com"
    elsif %w(amazon.co.uk amazn.co.uk co.uk uk).include? @@cfg[:site]
      @@cfg[:next] = "Next"
      @@cfg[:site] = "co.uk"
    elsif %w(amazon.fr amazn.fr fr).include? @@cfg[:site]
      @@cfg[:next] = "Suivant"
      @@cfg[:site] = "fr"
    else
      valid_sites = %w([amazon.]de [amazon.]com [amazon.]co.uk [amazon].fr)
      $log.warn "Invalid site specified. Available sites:"
      $log.warn "\t" + valid_sites.join(" ")
      exit 1
    end
    @@cfg[:url] = "https://www.amazon.#{@@cfg[:site]}/gp/css/order-history?" +
      "opt=ab&digitalOrders=1&unifiedOrders=0&orderFilter=year-#{@@cfg[:year]}"
  end
end

MoneyWellSpent.run
