#!/usr/bin/env python
# encoding: utf-8
"""
VCDConfigParser.py

Created by Nathaniel Pinckney on 2008-05-24.
Copyright (c) 2008 Nathaniel Pinckney. All rights reserved.
"""

import sys
import os
from ConfigParser import *

# TODO ensure that this implements everything from ConfigParser()
# TODO Checks for duplicate names
class VCDConfigParser(ConfigParser):
	"""
	Implements a config parser for VCD2
	The biggest difference is that it forces all options and sections
	to be upper case.  Mostly a hack because there is no sectionxform().
	Does not change write() to all uppercase, though.
	"""
	def __realsection(self, section):
		if not section: return None
		for i in ConfigParser.sections(self):
			if self.sectionxform(i) == self.sectionxform(section):
				return i
		return None
	
	def add_section(self, section):
		ConfigParser.add_section(self, __realsection(section) or section)
	
	def optionxform(self, option):
		return option.upper()
		
	def sectionxform(self, section):
		return section.upper()
	
	def get(self, section, option):
		return ConfigParser.get(self, self.__realsection(section), option)
		
	def sections(self):
		return map(lambda x: self.sectionxform(x), ConfigParser.sections(self))
	
	def has_option(self, section, option):
		return ConfigParser.has_option(self, self.__realsection(section), option)
		
	def has_section(self, section):
		return ConfigParser.has_section(self, self.__realsection(section))
	
	def items(self, section):
		return ConfigParser.items(self, self.__realsection(section))
		
	def set(self, section, option, value):
		return ConfigParser.set(self, self.__realsection(section), option, value)
		
	def remove_option(self, section, option):
		return ConfigParser.remove_option(self, self.__realsection(section), option)
		
	def remove_section(self, section):
		return ConfigParser.remove_section(self, self.__realsection(section))	

	def validate(self, data=None):
		"""Validate VCD configuration is correct"""
		def error(port, sig):
			print "Error: port %s does not have %s in config file!" % (port, sig)
			quit()
		
		# TODO cleanup, check that DEFAULT has these
		self._clks = []
		self._clks += [self.defaults()['CLK']]
		
		for section in self.sections():
			if(not self.has_option(section, 'CLK')):
				error(section, 'CLK')
			if(not self.has_option(section, 'CLKDIR')):
				error(section, 'CLKDIR')
			if(not self.has_section(self.get(section,'CLK'))):
				error(section, 'no clock section %s' % self.get(section,'CLK')) 
			self._clks += [self.get(section,'CLK')]
		
		self._clks = list(set(self._clks))
		
		# If we were passed a .VCD data object, validate all sections exist
		if data:
			for port in data.ports():
				if not self.has_section(port):
					print "Warning: no section for port '%s' in .conf file" % port
		
	def clks(self):
		return self._clks

def main():
	config = VCDConfigParser()
	config.read('example.conf')
	config.write(sys.stdout)
	print config.has_option("reseTb", "clk")
	print config.sections()
	config.validate()

if __name__ == '__main__':
	main()

