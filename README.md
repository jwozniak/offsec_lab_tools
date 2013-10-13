offsec_lab_tools
================

Offsec PWB Lab Tools



mping.sh
---------
#  DESCRIPTION: Just a simple Bash script that indentifies all live hosts 
#               (responding to ping) on a given network(s).


Usage: ./mping.sh [-t] <IP Range>[,<IP Range>]
  Options:
  -t <n>: Number of ping threads to use (Default: 50)
  -v    : Verbose mode

  Example:
      ./mping.sh 192.168.11.200-192.168.11.254
      ./mping.sh -t 100 192.168.1.1-192.168.1.100,10.1.0.0-10.2.1.1


mping.rb
--------
# Just a simple Ruby script that indentifies all live hosts 
# (responding to ping) on a given network(s).

# ./mping.rb 
Usage:
    mping.rb [options]
    -t, --thread [N]                 Threads to spawn
    -v, --verbose                    Run verbosely
    -h, --help                       Show help
Example:
    mping.rb 192.168.10.200-192.168.10.254
    mping.rb -t 100 10.1.2.3-10.1.2.254,192.168.1.1-192.168.10.254



# ./mping.rb -t100 192.168.11.200-192.168.11.254,192.168.13.200-192.168.13.254,192.168.15.200-192.168.15.254,192.168.17.200-192.168.17.254 
Time: 00:00:10 |===============================================================================================================================================================================>>| 100% Ping
192.168.11.201
192.168.11.202
192.168.11.205
192.168.11.206
192.168.11.208

