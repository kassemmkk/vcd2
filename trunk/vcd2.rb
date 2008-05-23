require 'pp'
require 'ostruct'

#
# Defines data from a .VCD file
#
class VCDData
  attr_reader :ports, :date, :version, :timescale
  
  def readDecl(file)
    string = nil
    while line = file.gets
      line.strip!
      return string if line =~ /\$end/ 
      string = line
    end
  end  
  
  def newTime(time)
    @oldtime = @curtime
    @curtime = time
    @dump[@curtime] = {}
    ports.each { |k, v| @dump[@curtime][k] = v }
  end
  
  def initialize(file)
    @ports = {}
    @dump = {}
    @dump[0] = {}
    @oldtime = 0
    @curtime = 0
    
    while(line = file.gets)
      line.strip!
      case line
      when /\$date/           # Date
        @date = readDecl(file)
      when /\$version/        # Version
        @version = readDecl(file)
      when /\$timescale/      # Timescale
        @timescale = readDecl(file)
      when /\$var/            # Variable Definition
        words = line.split
        @ports[words[3]] = VCDPort.new(words)
        puts "Just added #{@ports[words[3]].name}#{@ports[words[3]].range.to_s}"
      when /^#(\d+)/          # Time
        newTime $1
      when /\$dumpvars/       # Dump variable
      when /^(x|0|1)(\S+)/    # Signal
      when /^b(\S+)\s+(\S+)/  # Bus
      # else
        # puts "Warning: could not parse \"#{line}\"!"
        # exit
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

class PortRange
  attr_reader :begin, :end
  
  def initialize(str_range)
    if str_range == ''
      @bus = false
      @begin = 0
      @end = 0
    else
      @bus = true
      if str_range =~ /\[(\d+):(\d+)\]/
        @end = $1
        @begin = $2
      end
    end
  end
  
  def to_s
    if bus?
      if @begin != @end 
        "[#{@end}:#{@begin}]"
      else
        "[#{@begin}]"
      end
    else
      ''
    end
  end
  
  # True if bus
  def bus?
    @bus
  end
  
  # True if signal
  def signal?
    not @bus
  end
  
  def size
    @end - @begin    
  end
end

vcddata = VCDData.new(File.new("example.vcd", "r"))