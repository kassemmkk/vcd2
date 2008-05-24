#!/usr/bin/env python
# encoding: utf-8
"""
VCD.py

Created by Nathaniel Pinckney on 2008-05-24.
Copyright (c) 2008 Nathaniel Pinckney. All rights reserved.
"""

import re
import string

class VCDPort(object):
	"""docstring for VCDPort"""
	def __init__(self, words):
		self.type = words[1]
		self.__size = int(words[2])
		# words[3] is the symbol for this, stored in parent dict 
		self.name = words[4].upper()
		
		# FIXME this is a magic number
		if len(words) == 7:
			self.__bus = True
			match = re.match('\[(\d+)(:(\d+))?\]',words[5])
			if match.group(2):
				self.__begin = int(match.group(3))
				self.__end = int(match.group(1))
			else:
				self.__begin = int(match.group(1))
				self.__end = int(match.group(1))
		else:
			self.__bus = False
	
	def is_bus(self): return self.__bus
	
	def is_signal(self): return not self.__bus
	
	def index_str(self):
		if self.is_bus():
			if(self.__begin == self.__end):
				return "[%i]" % self.__begin
			else:
				return "[%i:%i]" % (self.__end, self.__begin)
		elif self.is_signal():
			return ''

	def name_str(self):
		return "%s%s" % (self.name, self.index_str())
		
	# NOTE might want to throw an exception if not a bus
	def bits(self):
		if self.is_signal():
			return range(0, 1)
		else:
			return range(self.__end, self.__begin - 1, -1)

	def size(self):
		return self.__size

class VCDDump:
	"""docstring for VCDDump"""
	def __init__(self):
		self.__time = 0
		self.__dump = dict()
		self.__dump[0] = dict()
	


class VCDParser:
	"""Reads a .VCD file"""
	def __init__(self):
		self.__ports = dict()
		self.__dump = dict()
		self.__curtime = 0
		self.__dump[0] = dict()
		
	def __newTime(self, time):
		"""Process a new time"""
		self.__oldtime = self.__curtime
		self.__curtime = time
		self.__dump[time] = self.__dump[self.__oldtime].copy()
		
	def __readDecl(self, fname):
		"""Reads in a declaration"""
		string = ""
		for line in fname:
			line = line.strip()
			if line.find("#end"): return line
			string = line
	
	def __extend_vector(self, value, size):
		trans = string.maketrans('10zxZX', '00zxZX')
		char = value[0].translate(trans)
		newvalue = (char * (size - len(value))) + value
		return newvalue
	
	def read(self, filename):
		self.readfp(open(filename,'r'))
		
	def readfp(self, file):
		for line in file:
			# Strip whitespace
			line = line.strip()
			
			# Various regular expressions to parse
			match_date = re.match('\$date', line)
			match_version = re.match('\$version', line)
			match_timescale = re.match('\$timescale', line)
			match_var = re.match('\$var ', line)
			match_newtime = re.match('^#(\d+)', line)
			match_signal = re.match('^(x|0|1)(\S+)', line)
			match_bus = re.match('^b(\S+)\s+(\S+)', line)
			
			# Check which regexp matched
			if match_date:
				self.date = self.__readDecl(file)
				print "Date:", self.date
			elif match_version:
				self.version = self.__readDecl(file)
				print "Version:", self.version
			elif match_timescale:
				self.timescale = self.__readDecl(file)
				print "Timescale:", self.timescale
			# Variable definition
			elif match_var:
				words = line.split()
				self.__ports[words[3]] = VCDPort(words)
			# Time marker
			elif match_newtime:
				self.set_time(int(match_newtime.group(1)))
			# Bus
			elif match_bus:
				symbol = match_bus.group(2)
				port = self.__ports[symbol]
				value = match_bus.group(1)
				# Extend the vector
				value = self.__extend_vector(value, port.size())
				# Reverse
				value = value[::-1] 
				for bit in port.bits():
					self.set_bus(port.name, bit, value[bit])
			# Signal	
			elif match_signal:
				symbol = match_signal.group(2)
				value = match_signal.group(1)
				name = self.__ports[symbol].name
				self.set_signal(name, value)
		
	def ports(self):
		# FIXME remove duplicates and concatinate multiple ports
		arr = []
		for i in self.__ports:
			arr += [self.__ports[i].name]
		return arr
	
	# currently always assumes we'll never
	# go back in time and edit
	def set_time(self, time):
		if not time in self.__dump:
			self.__dump[time] = self.__dump[self.__time].copy()	
		self.__time = time

	def get_time(self):
		return self.__time

	def times(self):
		keys = self.__dump.keys()
		keys.sort()
		return keys

	def set_signal(self, port, value):
		"""docstring for set_signal"""
		dump = self.__dump[self.get_time()]
		dump[port] = value

	def get_signal(self, port):
		"""docstring for get_signal"""
		dump = self.__dump[self.get_time()]
		if type(dump.get(port)) != type(str()):
			return None
		else:
			return dump[port]

	def set_bus(self, port, bit, value):
		"""docstring for set_bus"""
		dump = self.__dump[self.get_time()]
		if type(dump.get(port)) != type(dict()):
			dump[port] = {}
		dump[port][bit] = value
		# print "Set port %s bit %i to value %s" % (port, bit, value)

	def get_bus(self, port, bit):
		"""docstring for get_bus"""
		dump = self.__dump[self.get_time()]
		if type(dump.get(port)) != type(dict()):
			return None
		else:
			return dump[port][bit]
			
	def __get_symbol(self,port):
		for symbol in self.__ports.keys():
			if self.__ports[symbol].name == port:
				return symbol
		return None
	
	def bits(self, port):
		symbol = self.__get_symbol(port)
		return self.__ports[symbol].bits()
		
	def is_bus(self, port):
		symbol = self.__get_symbol(port)
		return self.__ports[symbol].is_bus()
		
	def is_signal(self, port):
		symbol = self.__get_symbol(port)
		return self.__ports[symbol].is_signal()

def main():
	import VCDConfigParser
	
	config = VCDConfigParser.VCDConfigParser()
	config.read('example.conf')
	
	vcd = VCDParser()
	vcd.read('example.vcd')
	config.validate(vcd)
	
	for time in vcd.times():
		print "At time", time
		vcd.set_time(time)
		for port in vcd.ports():
			print "  Port", port, "of type", config.get(port,'type')
			if vcd.is_bus(port):
				for bit in vcd.bits(port):
					print "    Bit", bit, "is", vcd.get_bus(port,bit)
			else:
				print "    is", vcd.get_signal(port)

if __name__ == '__main__':
	main()

