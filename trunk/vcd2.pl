#!/usr/bin/perl
#
# vcd2sp.pl: Converts a Verilog Value Change Dump
# to a spice digital vector stimulus.
#
# Date: February 14, 2008
# Author: Nathaniel Pinckney
#

use File::Basename;

# Parse a VCD file and return its data.
sub parseVCD() {
	%VCD;
	
	open(INFILE, $vcdFilename) or die "Can't open VCD file: $!\n";
	while(<INFILE>) {
		$_ = trim($_);
		if(/\$date/) {
			$VCD{date} = readDeclaration();
			next;
		} elsif(/\$version/) {
			$VCD{version} = readDeclaration();
			next;
		} elsif(/\$timescale/) {
			my $tmptime = readDeclaration();
			# For right now we just extract the units
			# in the future we'd want to keep track of the scale.
			$tmptime =~ /(\ws)/g;
			$VCD{timescale} = $1;
			next;
		} elsif(/\$var/) {
			# A variable definition
			$_ = split(/ /);
			if($_[1] =~ /(reg|wire)/) {
				my $size = $#_;
				# $VCD{'ports'}{$_[3]}{'type'} = $1;
				$VCD{'ports'}{$_[3]}{'name'} = $_[4];
				$VCD{'ports'}{$_[3]}{'size'} = $_[2];
				if($size == 6) {
					$VCD{'ports'}{$_[3]}{'portnum'} = $_[5];
				}
				if(grep $_ eq $VCD{'ports'}{$_[3]}{'name'}, @input) {
					$VCD{'ports'}{$_[3]}{'type'} = 'input';
				} elsif(grep $_ eq $VCD{'ports'}{$_[3]}{'name'}, @output) {
					$VCD{'ports'}{$_[3]}{'type'} = 'output';
				} elsif(grep $_ eq $VCD{'ports'}{$_[3]}{'name'}, @inout) {
					$VCD{'ports'}{$_[3]}{'type'} = 'inout';
				} else {
					print STDERR @foo . "\n";
					die("Port " . $VCD{'ports'}{$_[3]}{'name'} . " not found in configuration file");
				}
			}
		} elsif(/^#\d+/) {
			# Time marker
			newTime();
		} elsif(/\$dumpvars/) {
			# begin a variable dump
			readDumpVars();
		} elsif(isVar) {
			processVar();
		}
	}
	close(INFILE) or die "Can't close VCD file: $!\n";
}

sub isVar() {
	if(/^(x|0|1)(\S+)/) {
		return 1;
	} elsif(/^b(\S+)\s+(\S+)/) {
		return 1;
	} else {
		return 0;
	}
}

sub processVar() {
	if(/^(x|0|1)(\S+)/) {
		# This is a single assignment
		$VCD{'dump'}{$curtime}{"$VCD{'ports'}{$2}{'name'}$VCD{'ports'}{$2}{'portnum'}"} = $1;
		if(1 != portSize($VCD{'ports'}{$2}{'portnum'})) {
			die("Port $VCD{'ports'}{$2}{'name'}$VCD{'ports'}{$2}{'portnum'} was incorrect size.")
		}
	}
	if(/^b(\S+)\s+(\S+)/) {
		# This is a bus assignment		
		my $tmpstr = extendVector($1,portSize($VCD{'ports'}{$2}{'portnum'}));
		$VCD{'dump'}{$curtime}{"$VCD{'ports'}{$2}{'name'}$VCD{'ports'}{$2}{'portnum'}"} = $tmpstr;
	}
	
}

sub extendVector(my $str, my $size) {
	my $str = $_[0];
	my $size = $_[1];
	if(length($str) > $size) {
		die("Port $VCD{'ports'}{$2}{'name'}$VCD{'ports'}{$2}{'portnum'} was too big.");
	} else {
		my $chr = substr($str,-1);
		$chr =~ tr/10zxZX/00zxZX/;
		$str = ($chr x ($size - length($str))) . $str;
	}
	return $str;
}

sub newTime() {
	/^#(\d+)/;
	my $oldtime = $curtime;
	$curtime = $1;
	addTime($curtime, $oldtime);
	#if($curtime != 0) { 
	#	for(my $time = $oldtime + 1; $time <= $curtime; $time++) { 
	#		addTime($time, $oldtime);
	#	}
	#} else {
	#	# for first time, hope it is a $dumpvar
	#	# TODO: check for this
	#}
}

sub addTime() {
	my $time = $_[0];
	my $oldtime = $_[1];
	foreach my $k (sort keys %{$VCD{'ports'}}) {
		my %port = %{$VCD{'ports'}{$k}};
		#if($port{'type'} eq 'wire') {
		#	# Output, don't care if not specified.
		#	$VCD{'dump'}{$time}{"$port{'name'}$port{'portnum'}"} = 'x' x portSize($port{'portnum'});
		#} else {
			# Input, hold inputs.
			$VCD{'dump'}{$time}{"$port{'name'}$port{'portnum'}"} = $VCD{'dump'}{$oldtime}{"$port{'name'}$port{'portnum'}"};
		#}
	}
}

# Read in a dump var.  Initial list of variables.
sub readDumpVars() {
	while(<INFILE>) {
		$_ = trim($_);
		if(/\$end/) { last; }
		processVar();
	}	
}

# Can handle both a bus and single variable.
sub readValue() {
	# [Radix][Values] [Identifier]
	# [Value][Identifier]
}

sub readDeclaration() { 
	my $string;
	
	while(<INFILE>) {
		$_ = trim($_);
		if(/\$end/) { return $string };
		$string = $_ if not $string;
	}
}

# Returns port size of a register/wire
sub portSize() {
	$_= $_[0];
	if(/\[(\d+):(\d+)\]/) {
		return ($1 - $2 + 1);
	} elsif(/\[(\d+)\]/) {
		return 1;
	} else {
		return 1;
	}
	
}

### Utilities
sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

return true;
