#!/usr/bin/env ruby
#
# == smtpvrfy.rb
#
#  SMTP VRFY enumeration tool
#
# == Usage 
#  
# smtpvrfy [-d] -u [users_dict] SERVER
#   
# == Description 
# 
# Yet another VRFY enumeration tool. It is multithreaded
# and extends the standar ruby Net::SMTP
# 
# == Author 
# 
# Jerry Wozniak <jerry@pstree.org>
#
# == Version
# 
# 0.1
#
# == Created
#  
# 2013-09-16
#


require 'net/smtp'
require 'optparse'
require 'parallel'
require 'ruby-progressbar'

class Net::SMTP
  def vrfy(user)
    getok("VRFY #{user}")
  end
end

# Just a list of a few default users - only used when -u is not specified
stdusers = %w(root daemon admin mail news postmaster administrator info)

options = {}
# Let's use 50 threads by default
options[:threads] = 50
# We will check 3 users by default and close the connection
options[:chunk] = 3
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options] SMTP_SERVER[:PORT]" 
  opts.separator("Where available options:")
  opts.on("-t", "--threads N", "Number of threads (connections) to use - Default: #{options[:threads]}") do |t|
    options[:threads] = t
  end
  opts.on("-c", "--chunk N", "Recycle the connection (thread) after N number of users checked - Default: #{options[:chunk]}") do |c|
    options[:chunk] = c
  end
  opts.on("-u", "--user FILE", "Read a dict file with users") do |file|
    options[:users] = file.to_s
  end
  opts.on("-d", "--debug","Enable session debug") { options[:debug] = true }
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit 1
  end
end.parse!

if ARGV.empty?
  puts "ERROR: Please specify the smtp server"
  exit 1
end

#Default tcp port if not specified
port = 25
#Match email in server's responses
mailregex = Regexp.new(/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/)
stdusers = File.read(options[:users]).split(/\n/) if options[:users]
stdusers =  stdusers.each_slice(options[:chunk])
server = ARGV.pop
server, port = server.split(/:/)
# Show a little progress bar
progress = ProgressBar.create(:title => "VRFY",:format => '%e |%b>>%i| %p%% %t', :total => stdusers.count) if ! options[:debug]
result = Parallel.map(stdusers, :in_processes=>options[:threads].to_i, :finish => lambda { |item, i| progress.increment }) do |stdusers|
  smtp = Net::SMTP.new(server, port)
  smtp.set_debug_output $stderr if options[:debug]
  #Use ESMTP by default
  smtp.esmtp=true
  discovered_users = []
  #Start the session
  smtp.start('example.com') do |smtp|
    stdusers.each do |user|
      begin 
        # Inspect the response also as we might match a full email addres
        # and not the username
        email_match=smtp.vrfy(user).message.match(mailregex)
        if email_match
          discovered_users << email_match[0]
        else
          discovered_users << user
        end
      rescue Exception => e
         # Sometime SMTP will disclose the email in 5xx message, let's catch it
        rescue_match=e.message.match(mailregex)
        discovered_users << rescue_match[0] if rescue_match
      end
    end
    discovered_users
  end
end
result = result.flatten.uniq.sort
result.each do |user|
  puts user
end
puts "[*] Total #{result.length} users discovered"
