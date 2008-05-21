#!/usr/bin/perl
#
# vcd2sp.pl: Converts a Verilog Value Change Dump
# to a spice digital vector stimulus.
#
# Date: February 14, 2008
# Author: Nathaniel Pinckney
#

use File::Basename;

package main;
require "vcd2.pl";

main();

sub print_header() {
	print "|$basename.cmd\n";
#	print "///////////////////////////////////////////////////////////////////////\n";
#	print "// $basename.cmd\n";
#	print "// IRSIM .cmd file\n";
#	print "//\n";
#	print "// Automatically generated by vcd2cmd from '$vcdFilename'\n";
#	print "// Original .vcd file from $VCD{version} ($VCD{date})\n";
#	print "///////////////////////////////////////////////////////////////////////\n";	
	print "\n";
	print "stepsize $irsimstepsize\n";
	print "\n";
}

sub printVectors() {
	my $oldclk;
	my $clk;
	my $oldtime;
	my %oldvector;
	
	$resetcount=0;
	$runcount=0;
	my $count = 0;
	
	foreach my $time (sort {$a <=> $b} keys %{$VCD{'dump'}}) {
		my %vector = %{$VCD{'dump'}{$time}};
		
		# Todo: Case insentitivity
		$oldclk = $clk;
		$clk = $vector{$clkname};
		if(($oldclk == 1 && $clk == 0 && $clkdir eq "fall") or
		   ($oldclk == 0 && $clk == 1 && $clkdir eq "rise")) {
			if($clkdelay == 1) { print1Vector($oldtime, $count); }
			else { print1Vector($time, $count);	}
			# Count run vs reset
			if($vector{'reset'} eq '1' || $vector{'resetb'} eq '0') { $resetcount++; }
			else { $runcount++; }
			$count++;
		}
		$oldtime = $time;
	}
	# Print the last vector, inputs are XXX's
	%oldvector = %{$VCD{'dump'}{$oldtime}};
	print1Vector($oldtime, $count);
	
	print "\n";
}

sub print1Vector {
	my ($time, $count) = @_;
	my %vector = %{$VCD{'dump'}{$time}};

	print "| $count\n";

	if($clkdir eq "rise") {
		print "h $clkname\n";
	} elsif($clkdir eq "fall") {
		print "l $clkname\n";
	}
	
	# Inout
	foreach my $k (sort keys %{$VCD{'ports'}}) {
		my %port = %{$VCD{'ports'}{$k}};

		if($port{'type'} eq 'inout') {	
			if($enable{$port{'name'}} =~ /^(~)?(\S+)$/) {
				if(($1 eq '~' and $vector{$2} eq '0') or
				   ($1 eq '' and $vector{$2} eq '1')) {
					# output
					if($vector{'reset'} eq '1' or $vector{'resetb'} eq '0') {
						next;
					}

					if($port{'portnum'} =~ /\[(\d+):(\d+)\]/) {
						($start, $end) = ($2, $1);
						 for(my $i = $end; $i >= $start; $i--) {
							print "x " . lc($port{'name'}) . '[' . $i . ']' . "\n";
						}
					} elsif($port{'portnum'} =~ /\[(\d+)\]/) {
						print "x " . lc($port{'name'}) . '[' . $1 . ']' . "\n";
					} else {
						print "x " . lc($port{'name'}) . "\n";
					}
				}
			} 
		}
	}
	
	print "s\n";
	print "s\n";
	
	# A step
	if($clkdir eq "rise") {
		print "l $clkname\n";
	} elsif($clkdir eq "fall") {
		print "h $clkname\n";
	}
	print "s\n";
	
	# Need two passes: inputs then outputs.

	# Inputs
	foreach my $k (sort keys %{$VCD{'ports'}}) {
		my %port = %{$VCD{'ports'}{$k}};
		# TODO: This should be a list
		#if($port{'name'} =~ /(clk|reset|ph1|ph2)/i) {
		if($port{'name'} =~ /(clk|ph[0123456789])/i) {
			next;
		} 	
		if($port{'type'} eq 'input')  {
			# input
			if($port{'portnum'} =~ /\[(\d+):(\d+)\]/) {
				($start, $end) = ($2, $1);
				 for(my $i = $end; $i >= $start; $i--) {
					if(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "0") {
						print "l " . lc($port{'name'}) . '[' . $i . ']' . "\n";
					} elsif(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "1") {
						print "h " . lc($port{'name'}) . '[' . $i . ']' . "\n";
					} 
				}
			} elsif($port{'portnum'} =~ /\[(\d+)\]/) {
				if($vector{"$port{'name'}$port{'portnum'}"}  eq "0") {
					print "l " . lc($port{'name'}) . '[' . $1 . ']' . "\n";
				} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
					print "h " . lc($port{'name'}) . '[' . $1 . ']' . "\n";
				}
			} else {
				if($vector{"$port{'name'}$port{'portnum'}"} eq "0") {
					print "l " . lc($port{'name'}) . "\n";
				} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
					print "h " . lc($port{'name'}) . "\n";
				}
			}
		}
	}	
	
	
	# Inout
	foreach my $k (sort keys %{$VCD{'ports'}}) {
		my %port = %{$VCD{'ports'}{$k}};

		if($port{'type'} eq 'inout') {	
			if($enable{$port{'name'}} =~ /^(~)?(\S+)$/) {
				if(($1 eq '~' and $vector{$2} eq '0') or
				   ($1 eq '' and $vector{$2} eq '1')) {
					# output
					if($vector{'reset'} eq '1' or $vector{'resetb'} eq '0') {
						next;
					}

					if($port{'portnum'} =~ /\[(\d+):(\d+)\]/) {
						($start, $end) = ($2, $1);
						 for(my $i = $end; $i >= $start; $i--) {
							if(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "0") {
								print "assert " . lc($port{'name'}) . '[' . $i . ']' . " 0\n";
							} elsif(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "1") {
								print "assert " . lc($port{'name'}) . '[' . $i . ']' . " 1\n";
							} 
						}
					} elsif($port{'portnum'} =~ /\[(\d+)\]/) {
						if($vector{"$port{'name'}$port{'portnum'}"}  eq "0") {
							print "assert " . lc($port{'name'}) . '[' . $1 . ']' . " 0\n";
						} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
							print "assert " . lc($port{'name'}) . '[' . $1 . ']' . " 1\n";
						}
					} else {
						if($vector{"$port{'name'}$port{'portnum'}"} eq "0") {
							print "assert " . lc($port{'name'}) . " 0\n";
						} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
							print "assert " . lc($port{'name'}) . " 1\n";
						}
					}
				} else {
					# input
					if($port{'portnum'} =~ /\[(\d+):(\d+)\]/) {
						($start, $end) = ($2, $1);
						 for(my $i = $end; $i >= $start; $i--) {
							if(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "0") {
								print "l " . lc($port{'name'}) . '[' . $i . ']' . "\n";
							} elsif(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "1") {
								print "h " . lc($port{'name'}) . '[' . $i . ']' . "\n";
							} 
						}
					} elsif($port{'portnum'} =~ /\[(\d+)\]/) {
						if($vector{"$port{'name'}$port{'portnum'}"}  eq "0") {
							print "l " . lc($port{'name'}) . '[' . $1 . ']' . "\n";
						} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
							print "h " . lc($port{'name'}) . '[' . $1 . ']' . "\n";
						}
					} else {
						if($vector{"$port{'name'}$port{'portnum'}"} eq "0") {
							print "l " . lc($port{'name'}) . "\n";
						} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
							print "h " . lc($port{'name'}) . "\n";
						}
					}
				}
			} 
		}
	}

	
	# Outputs
	foreach my $k (sort keys %{$VCD{'ports'}}) {
		my %port = %{$VCD{'ports'}{$k}};
		# TODO: This should be a list
		# if($port{'name'} =~ /(clk|reset)/i) {
		# 	next;
		# }
		if($vector{'reset'} eq '1' or $vector{'resetb'} eq '0') {
			next;
		}
		if($port{'type'} eq 'output') {
			# output
				if($port{'portnum'} =~ /\[(\d+):(\d+)\]/) {
					($start, $end) = ($2, $1);
					 for(my $i = $end; $i >= $start; $i--) {
						if(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "0") {
							print "assert " . lc($port{'name'}) . '[' . $i . ']' . " 0\n";
						} elsif(substr($vector{"$port{'name'}$port{'portnum'}"},$end - $i,1) eq "1") {
							print "assert " . lc($port{'name'}) . '[' . $i . ']' . " 1\n";
						} 
					}
				} elsif($port{'portnum'} =~ /\[(\d+)\]/) {
					if($vector{"$port{'name'}$port{'portnum'}"}  eq "0") {
						print "assert " . lc($port{'name'}) . '[' . $1 . ']' . " 0\n";
					} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
						print "assert " . lc($port{'name'}) . '[' . $1 . ']' . " 1\n";
					}
				} else {
					if($vector{"$port{'name'}$port{'portnum'}"} eq "0") {
						print "assert " . lc($port{'name'}) . " 0\n";
					} elsif($vector{"$port{'name'}$port{'portnum'}"} eq "1") {
						print "assert " . lc($port{'name'}) . " 1\n";
					}
				}
			
		}
	}
	
	print "s\n";

	print "\n";
}

sub writeCMD() {
	open(SAVEOUT, ">&STDOUT");
	open(STDOUT, ">$basename.cmd") or die("Can't open $basename.cmd for writing");
	
	# Print header
	print_header();

	# Print vectors here
	printVectors();
	
	close(STDOUT);
	open(STDOUT, ">&SAVEOUT") or die("Can't open original STDOUT");
}

sub main() {
	# Parse command line arguments
	$numArgs = $#ARGV + 1;
	$vcdFilename = $ARGV[$#ARGV];
	$basename = basename($vcdFilename, ".vcd");
	
	if($numArgs != 1) { usage() };
	
	eval('require "' . "$basename.conf" . '";') or die "Couldn\'t load config file $basename.conf";
	
	# Doubled because we do two steps per input/output pair.
	$irsimstepsize = $irsimspeed/4;
	
	parseVCD();
	writeCMD();
}

sub usage() {
	print STDERR "Usage: ./vcd2cmd.pl input.vcd\n";
	exit;
}