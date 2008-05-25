#!/usr/bin/env python
# encoding: utf-8
"""
vcd2.py

Created by Nathaniel Pinckney on 2008-05-20.
Copyright (c) 2008 Nathaniel Pinckney. All rights reserved.
Released under GPL v3.
"""

# TODO Check if enable is an input port

import sys
import getopt
import ConfigParser
import re
from optparse import OptionParser

import VCDConfigParser

help_message = '''
The help message goes here.
'''


class Usage(Exception):
	def __init__(self, msg):
		self.msg = msg

class VCDPort(object):
	"""docstring for VCDPort"""
	def __init__(self, words):
		super(VCDPort, self).__init__()
		# TODO type is currently not used for anything
		self.type = words[1];
		self.size = words[2];
		# words[3] is the symbol for this, stored in parent dict 
		self.name = words[4];
		# FIXME this is a magic number
		if len(words) == 6:
			# TODO This would be better with a self.begin and self.end
			self.portnum = words[5];

class VCDData(object):
	"""Represents data parsed from VCD file"""
	def __init__(self):
		super(VCDData, self).__init__()
		self.ports = dict();
		self.curtime = 0

	# TODO Update this for better parsing (e.g. multi-line)
	def readfp(self,fname):
		def newTime(time):
			"""Process a new time"""
			self.oldtime = self.curtime
			self.curtime = time
			pass
			
		def readDecl(fname):
			"""Reads in a declaration"""
			string = ""
			for line in fname:
				line = line.strip()
				if line.find("#end"): return line
				string = line

		for line in file:
			line = line.strip()
			words = line.split()
			matchdate = re.match('^#(\d+)',line)
			if words[0] == '$date':
				self.date = readDecl(fname)
				print "Date:", self.date
			elif re.match('\$version',line):
				self.version = readDecl(fname)
				print "Version:", self.version
			elif re.match('\$timescale',line):
				self.timescale = readDecl(fname)
				print "Timescale", self.timescale
			elif words[0] == '$var':
				self.ports[words[3]] = VCDPort(words);
			elif matchdate:
				newTime(matchdate.group(1))
			elif re.match('\$dumpvars',line):
				pass
		
def main(argv=None):
	parser = OptionParser()
	parser.add_option("-f", "--file", dest="filename",
						help="write report to FILE", metavar="FILE")
	parser.add_option("-v", "--verbose",
						action="store_true", dest="verbose", default="False",
						help="Don't print status messages to stdout")
	(options, args) = parser.parse_args()
	
	parser.error("Filename must be specified!")
	
	if options.verbose:
		print "reading %s..." % options.filename
	
	config = ConfigParser.ConfigParser()
	
	fname = open("example.conf","r")
	config.readfp(fname)
	validate_config(config)
	
	vcd = VCDData()
	
	fname = open("example.vcd","r")
	vcd.readfp(fname)

		
def validate_config(config):
	"""Validates the configuation file, including checking for clock definitions"""
	# TODO Check if any sections exist

	# check all sections have clock statements
	for section in config.sections():
		# FIXME these should die instead of just print
		if not config.has_option(section,'clk'):
			print "Error: port", section, "does not have a clk in config file!"
		else:
			clk = config.get(section,'clk')
		if not config.has_option(section,'clkdir'):
			print "Error: port", section, "does not have a clkdir in config file!"
		if not config.has_section(clk):
			print "Error: no section for clock", clk, "from section", section
	
if __name__ == "__main__":
	sys.exit(main())
