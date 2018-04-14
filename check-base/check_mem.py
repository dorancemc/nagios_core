#!/usr/bin/env python

"""
    Nagios plugin to report Memory usage by parsing /proc/meminfo

    by L.S. Keijser <keijser@stone-it.com>
    by Dorance <dorancemc@gmail.com> (was modified to show memory used and performance data)

    This script takes Cached memory into consideration by adding that
    to the total MemFree value.
"""

from optparse import OptionParser
import sys

checkmemver = '0.2'

# Parse commandline options:
parser = OptionParser(usage="%prog -w <warning threshold> -c <critical threshold> [ -h ]",version="%prog " + checkmemver)
parser.add_option("-w", "--warning",
    action="store", type="string", dest="warn_threshold", help="Warning threshold in percentage")
parser.add_option("-c", "--critical",
    action="store", type="string", dest="crit_threshold", help="Critical threshold in percentage")
parser.add_option("-G",
    action="store_true", dest="gigabytes", help="Show values in GB (MB by default)")
parser.add_option("-K",
    action="store_true", dest="kilobytes", help="Show values in KB (MB by default)")
(options, args) = parser.parse_args()

def readLines(filename):
    f = open(filename, "r")
    lines = f.readlines()
    return lines

def readMemValues():
    global memTotal, memFree, memCached, memUsed, memUsedprc
    for line in readLines('/proc/meminfo'):
        if line.split()[0] == 'MemTotal:':
            memTotal = line.split()[1]
        if line.split()[0] == 'MemFree:':
            memFree = line.split()[1]
        if line.split()[0] == 'Cached:':
            memCached = line.split()[1]
    if options.gigabytes:
        size = 1024 * 1024
    elif options.kilobytes:
        size = 1
    else:
        size = 1024

    memUsed = int(memTotal) - (int(memFree) + int(memCached))
    memUsedprc = ((int(memUsed) * 100) / int(memTotal))
    memTotal = float(memTotal) / float(size)
    memUsed = float(memUsed) / float(size)
    memFree = float(memFree) / float(size)
    memCached = float(memCached) / float(size)

def go():
    if not options.crit_threshold:
        print "UNKNOWN: Missing critical threshold value."
        sys.exit(3)
    if not options.warn_threshold:
        print "UNKNOWN: Missing warning threshold value."
        sys.exit(3)
    if options.gigabytes:
        size = "GB"
    elif options.kilobytes:
        size = "KB"
    else:
        size = "MB"
    if int(options.crit_threshold) <= int(options.warn_threshold):
        print "UNKNOWN: Critical percentage can't be equal to or bigger than warning percentage."
        sys.exit(3)
    readMemValues()
    if int(memUsedprc) >= int(options.crit_threshold):
        print "CRITICAL: used memory percentage is %.2f%% - (Total/Used/Free/Cached: %.2f %.2f %.2f %.2f %s) | percent_memory=%.2f%%;%s;%s " % (memUsedprc, memTotal, memUsed, memFree, memCached, size, memUsedprc, options.warn_threshold, options.crit_threshold )
        sys.exit(2)
    if int(memUsedprc) >= int(options.warn_threshold):
        print "WARNING: used memory percentage is %.2f%% - (Total/Used/Free/Cached: %.2f %.2f %.2f %.2f %s) | percent_memory=%.2f%%;%s;%s " % (memUsedprc, memTotal, memUsed, memFree, memCached, size, memUsedprc, options.warn_threshold, options.crit_threshold )
        sys.exit(1)
    else:
        print "OK: used memory percentage is %.2f%% - (Total/Used/Free/Cached: %.2f %.2f %.2f %.2f %s) | percent_memory=%.2f%%;%s;%s " % (memUsedprc, memTotal, memUsed, memFree, memCached, size, memUsedprc, options.warn_threshold, options.crit_threshold )
        sys.exit(0)

if __name__ == '__main__':
    go()
