#!/usr/bin/env python

"""
    Nagios plugin to report socket statistics usage by parsing ss -s

    by Dorance <dorancemc@gmail.com>

"""

from optparse import OptionParser
import sys
from tempfile import mkstemp
import os

checkconnstatsver="0.1"

# Parse commandline options:
parser = OptionParser(usage="%prog -w <warning threshold> -c <critical threshold> [ -h ]",version="%prog " + checkconnstatsver)
parser.add_option("-w", "--warning",
    action="store", type="string", dest="warn_threshold", help="Warning threshold")
parser.add_option("-c", "--critical",
    action="store", type="string", dest="crit_threshold", help="Critical threshold")
(options, args) = parser.parse_args()

def socket_statistics():
    fd, temp_path = mkstemp()
    os.system('ss -s >%s' % temp_path)
    file = open(temp_path, 'r')
    lines = file.readlines()
    file.close()
    os.close(fd)
    os.remove(temp_path)
    return lines

def ReadStatistics():
    global connTotal, connTCP, connUDP, statsTCP
    for line in socket_statistics():
        if line.split(' ')[0] == 'Total:':
            connTotal = line.split()[1]
        if line.split(' ')[0] == 'TCP:':
            connTCP = line.split()[1]
            statsTCP = line.partition("(")[2].partition(")")[0]

def go():
    if not options.crit_threshold:
        print "UNKNOWN: Missing critical threshold value."
        sys.exit(3)
    if not options.warn_threshold:
        print "UNKNOWN: Missing warning threshold value."
        sys.exit(3)
    if int(options.crit_threshold) <= int(options.warn_threshold):
        print "UNKNOWN: Critical can't be equal to or lower than warning ."
        sys.exit(3)
    ReadStatistics()
    if int(connTCP) >= int(options.crit_threshold):
        print "CRITICAL: TCP connections: %s - (Total %s / TCP %s : %s ) | tcp_connections=%s;%s;%s " % (connTCP, connTotal, connTCP, statsTCP, connTCP, options.warn_threshold, options.crit_threshold )
        sys.exit(2)
    if int(connTCP) >= int(options.warn_threshold):
        print "WARNING: TCP connections: %s - (Total %s / TCP %s : %s ) | tcp_connections=%s;%s;%s " % (connTCP, connTotal, connTCP, statsTCP, connTCP, options.warn_threshold, options.crit_threshold )
        sys.exit(1)
    else:
        print "OK: TCP connections: %s - (Total %s / TCP %s : %s ) | tcp_connections=%s;%s;%s " % (connTCP, connTotal, connTCP, statsTCP, connTCP, options.warn_threshold, options.crit_threshold )
        sys.exit(0)

if __name__ == '__main__':
    go()
