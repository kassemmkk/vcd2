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

help_message = '''
The help message goes here.
'''


class Usage(Exception):
	def __init__(self, msg):
		self.msg = msg


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

		
def validate_config(config):
	"""Validates the configuation file, including checking for clock definitions"""
	# TODO Check if any sections exist

	# check all sections have a clock statements
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
