#!/usr/bin/env ruby
#
# == ftpfuzz.rb
#
# Ftp command fuzzer
#
# == Usage 
#  
#Uage: ftpfuzz.rb [options] ftp-host[:port]
#
#Where available options:
#    -u, --user USER                  FTP Username
#    -p, --pass PASS                  FTP Password
#    -c, --command COMMAND            FTP command to fuzz
#    -P, --payload PAYLOAD            Payload to repeat
#    -i, --increment INT              Increment the payload times
#    -v, --verbose                    Verbose output
#    -h, --help                       Show this help
#   
# == Description 
# 
# Just a simple Ruby script that uses TCPSocket to
# fuzz an FTP server
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
# 2013-10-20
#

require 'optparse'
require 'socket'

class FtpFuzz
  
  def initialize(host, port)
    @host, @port = host, port
  end

  def connect(verbose=false)
    @tcp = TCPSocket.new(@host, @port)
    @banner = @tcp.gets
    puts @banner if verbose
  end
  
  def login(user, pass, verbose=false)
    response = command("USER #{user}\r\n", verbose)
    response = command("PASS #{user}\r\n", verbose)
    response = @tcp.gets
    puts response if verbose
  end

  def command(command, verbose=false)
    puts command if verbose
    @tcp.write("#{command}\r\n")
    response = @tcp.gets
    puts response if verbose
  end

  def fuzz(command, payload, increment, verbose=false)
    data = payload
    puts "[*] Using: #{command} #{payload}"
    while true
      puts "[*] Sending #{payload} of size #{data.length} characters"
      @tcp.write("#{command} #{data}\r\n")  
      response = @tcp.gets
      puts response if verbose
      data = data + payload*increment
    end
  end

end

#Defaults
options = {}
options[:user]      = 'anonymous'
options[:pass]      = 'anonymous@example.com'
options[:command]   = 'APPE'
options[:payload]   = 'A' #0x41
options[:increment] = 20

op = OptionParser.new do |opt|
  opt.banner = "Usage: #{File.basename($0)} [options] ftp-host[:port]"
  opt.separator("\nWhere available options:")
  opt.on("-u", "--user USER", "FTP Username")                    { |o| options[:user]         = o }
  opt.on("-p", "--pass PASS", "FTP Password")                    { |o| options[:pass]         = o }
  opt.on("-c", "--command COMMAND", "FTP command to fuzz" )      { |o| options[:command]      = o }
  opt.on("-P", "--payload PAYLOAD", "Payload to repeat")         { |o| options[:payload]      = o }
  opt.on("-i", "--increment INT", "Increment the payload times") { |o| options[:increment]    = o }
  opt.on("-v", "--verbose", "Verbose output")                    { options[:verbose] = true       }
  opt.on("-h", "--help", "Show this help")                       { puts opt; exit 1               }
  if ARGV.empty? 
    puts opt
    exit 1
  end
end
op.parse!

host, port = ARGV.pop.to_s.split(/:/)
port = 21 if port.nil?

fz = FtpFuzz.new(host, port)
fz.connect(options[:verbose])
fz.login(options[:user], options[:pass], options[:verbose])
puts fz.command(options[:command])
fz.fuzz(options[:command], options[:payload].to_s, options[:increment].to_i, options[:verbose])
