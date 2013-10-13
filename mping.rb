#!/usr/bin/env ruby
#
# == mping.rb
#
# A ruby tool to perform a ping sweep 
#
# == Usage 
#  
# mping.sh [-v] [-t threads] [ip ranges]
#   
# == Description 
# 
# Just a simple Ruby script that indentifies all live hosts 
# (responding to ping) on a given network(s).
# 
# == Author 
# 
# Jerry Wozniak <jerry@pstree.org>
#
# == Version
# 
# mping-0.1
#
# == Created
#  
# 2013-09-12
#
#===================================================================================

require 'rubygems'
require 'net/ping'
require 'optparse'
require 'parallel'
require 'ruby-progressbar'


# This class provides a set of static methods to manipulate Inet Addresses
class InetAddr 
  # Convert ip to a decimal number 
  def self.ip2dec( ipaddr )
    ipaddr.split('.').inject(0) { |s,x| (s << 8) + x.to_i }
  end
  # Convert a decimal number to ip
  def self.dec2ip ( ipnum )
    [24, 16, 8, 0].collect {|b| (ipnum >> b) & 255}.join('.')
  end
  def self.range(start_ip, stop_ip)
    (ip2dec(start_ip)..ip2dec(stop_ip)).to_a.map!{|dip| self.dec2ip(dip)} 
  end
end

# A simple ping sweep class 
class MPing
  # Lets make the results accessible
  attr_accessor :result

  def initialize (hosts, threads=50)
    @hosts = hosts
    @threads = threads
    @result = []
    #Check if we can use raw sockets for ICMP - root privilege required 
    begin
      Net::Ping::ICMP.new()
    rescue RuntimeError => e
      puts "ERROR: #{e.message}"
      exit 7
    end
  end

  def run ()
    #Define the standard progressbar
    progress = ProgressBar.create(:title => "Ping",:format => '%e |%b>>%i| %p%% %t', :total => @hosts.count)
    #Run the ping sweep
    @result = Parallel.map(@hosts, :in_processes=>@threads.to_i, :finish => lambda { |item, i| progress.increment }) do |host|
    begin
      result = Net::Ping::ICMP.new(host, timeout=1).ping
    rescue Errno::EACCES => e
    end
      [host,result]
    end
  end

end
# MAIN
# -----
# Command line options
options = {}
options[:threads] = 50
# Prettify the script's name
script_name = File.basename($0)
# Collect the options
OptionParser.new do |opts|
  opts.banner = "Usage:\n"+ 
                "    #{script_name} [options]"
  opts.on("-t", "--thread [N]", "Threads to spawn") do |t|
    options[:threads] = t
  end
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-h", "--help", "Show help") do |v|
    puts opts
  end
  opts.on_tail("Example:", 
                "    #{script_name} 192.168.10.200-192.168.10.254\n" +
                "    #{script_name} -t 100 10.1.2.3-10.1.2.254,192.168.1.1-192.168.10.254")
 begin      
    opts.parse!(ARGV)
  rescue OptionParser::InvalidOption => e
    puts e
    puts opts
    exit(1)
  end
  if ARGV.empty?
    puts opts
    exit 5
  end
end

#
hosts = []

# For every range specified, expand and add to hosts array
ARGV[0].split(/,/).each do |range|
  minmax = range.split(/-/)
  hosts << InetAddr::range(minmax[0], minmax[1])
end

# Use MPing to rung the ping sweep in parallel
ping = MPing.new(hosts.flatten, options[:threads])
ping.run
# Display the collected results
ping.result.each do |host,result|
  puts host if result
end

