#!/usr/bin/env ruby
#
# == mping.rb
#
# A ruby tool to perform a ping sweep 
#
# == Usage 
#  
# axfr.rb [-v] -n [nameserver] <domain>
#   
# == Description 
# 
# Just a simple Ruby script that uses dnsruby gem
# to pefrom a zone transfer
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
# 2013-09-12
#

require 'rubygems'
require 'dnsruby'
require 'optparse'
require 'timeout'

options = {}
options[:timeout]=15
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options] zone"
  opts.separator("\nAvailable options:")
  opts.on('-n','--nameserver HOSTNAME',"Specify the nameserver to AXFR zone from") { |host| options[:nameserver]=host }
  opts.on('-w','--timeout SECONDS',"Wait timeout in seconds") { |t| options[:timeout] = t }
  opts.on('-v','--verbose',"Be more verbose") { |v| options[:verbose]=v }
  opts.on('-h','--help', "Show this help") do |h| 
    puts opts 
    exit 1 
  end
  if ARGV.empty?
    puts opts
    exit 1
  end
end.parse!

domain = ARGV.pop
puts "Attempting to transfer #{domain}" if options[:verbose]

zt = Dnsruby::ZoneTransfer.new
zt.transfer_type = Dnsruby::Types.AXFR
zone = []
if options[:nameserver]
  zt.server = options[:nameserver] 
end
begin
  status = Timeout::timeout(options[:timeout]) do
    zone = zt.transfer(domain)
  end
rescue Exception => e
 puts "Zone transfer error: #{e.message}"
 exit 2
end
zone.each do |line| 
  puts line
end
puts "[*] Total #{zone.count} recodrds transferred." if options[:verbose]
