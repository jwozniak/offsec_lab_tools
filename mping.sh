#!/usr/bin/env bash
#===================================================================================
#
#  FILE: mping.sh
#  
#  USAGE: mping.sh [-v] [-t threads] [ip ranges]
#   
#  DESCRIPTION: Just a simple Bash script that indentifies all live hosts 
#               (responding to ping) on a given network(s).
# 
# AUTHOR: Jerry Wozniak <jerry@pstree.org>
# VERSION: 0.1
# CREATED: 2013-09-12
#
#===================================================================================

#-----------------------------------------------------------------------
# Defaults
#-----------------------------------------------------------------------
THREADS=50
VERBOSE=0
#DEBUG=1

#-----------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------
usage () {

echo "Usage: $0 [-t] <IP Range>[,<IP Range>]
  Options:
  -t <n>: Number of ping threads to use (Default: $THREADS)
  -v    : Verbose mode

  Example:
      $0 192.168.11.200-192.168.11.254
      $0 -t 100 192.168.1.1-192.168.1.100,10.1.0.0-10.2.1.1"
}

# Check if the user passed the correct range
# TODO: this is only a simple IP regex 
# won't reject things like 871.878.999.666
validate_range () {
  local range=$1
  if ! [[ $1 =~ ([0-9]{1,3}\.){3}[0-9]{1,3}-([0-9]{1,3}\.){3}[0-9]{1,3} ]]; then
  printf "ERROR - Invalid range used: %s\n\n" $1
  usage
  exit 3
fi
}

# Convert a decimal number to IP address 
int2ip () { 
  local int=$@
  for e in {3..0}; do
    (( octet = int / (256 ** e) ))
    (( int -= octet * 256 ** e))
    ip+=$dot$octet
    local dot=.
  done
  printf '%s\n' "$ip" 
}

# Convert an IP address to a decimal number
ip2int () {
  local a b c d ip=$1
  local saveIFS=$IFS
  IFS=. 
  read -r a b c d <<< "$ip"
  printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
  IFS=$saveIFS
}

# Expand a single IP range
expand_range () {
  local min=$(ip2int $1)
  local max=$(ip2int $2)
  local saveIFS=$IFS
  local ips
  unset IFS
  for i in $(eval "echo {$min..$max}"); do
    ips+=$(int2ip $i)" "
  done
  printf "%s " $ips
  IFS=$saveIFS
}

# Expand multiple ranges using expand_range()
expand () {
  local range=$1
  local saveIFS=$IFS
  IFS=','
  for word in $range; do 
    validate_range $word
    beg=${word%-*}
    end=${word#*-}
    local ips+=$(expand_range $beg $end)
  done
  printf "%s " $ips
  IFS=$saveIFS
}

# Ping the host using xargs with parallelisation
ping () {
  local list=$@
  local shell="bash -c"
  [ -n "$DEBUG" ] && shell="bash -xc"
  echo $list | tr " " "\n" | \
    xargs -P$THREADS -I{} $shell \
    "[ $VERBOSE -eq 1 ] && echo 'Probing... {}'; 
     ping -q -f -c3 {} -w0 -p\$RANDOM > /dev/null 2>&1; 
     RET=\$?;
     if [ $VERBOSE -eq 0 ]; then 
       [ \$RET -eq 0 ] && echo {};
     else
       if [ \$RET -eq 0 ]; then
         echo '{}: UP'
       else 
        echo '{}: DOWN'
      fi
    fi"

}

#-----------------------------------------------------------------------
# MAIN
#-----------------------------------------------------------------------

while getopts ":t:v:" opt; do 
  case $opt in 
    t) 
      THREADS=$OPTARG
      shift
      shift
      ;;
    v) 
      VERBOSE=1
      shift
      ;;
    h)
      usage 
      shift
      exit 5
      ;;
    \?) 
      echo "Invalid opton -$OPTARG" >&2
      usage
      exit 2
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done
[ $# -eq 0 ] && usage
ip_list=$(expand $1)
[ -n "$DEBUG" ] && echo $ip_list
ping $ip_list
exit 0 
