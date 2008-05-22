require 'pp'
require 'ostruct'

#
# Defines data from a .VCD file
#
class VCDData
  attr_reader :ports, :date, :version, :timescale
  
  def initialize(file)
    @ports = {}
    while(line = file.gets)
      line.strip!
      case line
      when /\$date/
        @date = 0
      when /\$version/
        @version = 0
      when /\$timescale/
        @timescale = 0
      when /\$var/
        words = line.split
        @ports[words[3]] = VCDPort.new(words)
        puts "Just added #{@ports[words[3]].name}#{@ports[words[3]].range.bus?}"
      end
    end
end
  
  
end

class VCDPort
  attr_reader :type, :size, :name, :range
  def initialize(words)
    # TODO type is currently not used for anything
		@type = words[1];
		@size = words[2];
		# words[3] is the symbol for this, stored in parent dict 
		@name = words[4];
		# FIXME this is a magic number
		if words.size == 7
			@range = PortRange.new(words[5])
		else
		  @range = PortRange.new('')
		end
  end
end

class PortRange < Range
  def initialize(str_range)
    if str_range == ''
      @bus = false
      # begin = end = 0
    else
      @bus = true
      if str_range =~ /\[(\d+):(\d+)\]/
        @end = $2
        @begin = $1
        puts "begin #{$1} and end #{$2}"
      end
    end
  end
  
  def to_s
    "here"
  end
  
  def bus?
    @bus
  end
  
  def signal?
    not @bus
  end
end

vcddata = VCDData.new(File.new("example.vcd", "r"))