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

	# TODO Update this for better parsing (e.g. multi-line)
	def readfp(self,fname):
		def newTime():
			"""docstring for newTime"""
			pass

		for line in fname:
			line = line.strip()
			words = line.split()
			if words[0] == '$date':
				print "Found a date"
				self.date = 1
			elif re.match('\$version',line):
				print "Found a version"
				self.version = 1
			elif re.match('\$timescale',line):
				print "Found a timescale"
				self.timescale = 1
			elif words[0] == '$var':
				self.ports[words[3]] = VCDPort(words);
			elif re.match('^#\d+',line):	# New time
				newTime()
			elif re.match('\$dumpvars',line):			# Begin dumpvar
				pass

def main(argv=None):
	if argv is None:
		argv = sys.argv
	try:
		try:
			opts, args = getopt.getopt(argv[1:], "ho:v", ["help", "output="])
		except getopt.error, msg:
			raise Usage(msg)
	
		# option processing
		for option, value in opts:
			if option == "-v":
				verbose = True
			if option in ("-h", "--help"):
				raise Usage(help_message)
			if option in ("-o", "--output"):
				output = value
	
	except Usage, err:
		print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
		print >> sys.stderr, "\t for help use --help"
		return 2
		
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
