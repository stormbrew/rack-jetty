require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rack/rewindable_input'
require 'rack_jetty/java_input'
require 'java'
java_import org.jruby.RubyString

class FakeInput
  def initialize( inner_io )
    @io = inner_io
  end

  def read( buffer, offset, length )
    if length == 0
      return 0
    elsif @io.eof?
      return -1
    else
      inbuf = "\0"*length
      string_read = @io.read( length, inbuf ).to_java_bytes
      string_read.length.times do |i|
        buffer[offset+i] = string_read[i]
      end
      string_read.length
    end
  end
end

class ByteAtATimeIO
  def initialize( content )
    @io = StringIO.new( content )
  end

  def read( n, buf )
    @io.read( 1, buf )
  end

  def eof?
    @io.eof?
  end
end


describe RackJetty::JavaInput do
  let( :content ) { "hello world" }

  shared_examples_for "an input stream wrapper" do

    it "should not corrupt input" do
      stream = FakeInput.new( io )
      input = RackJetty::JavaInput.new( stream )
      rio = Rack::RewindableInput.new( input )

      rio.read.should == content
    end
  end

  describe "with ordinary IO" do
    let( :io ) { StringIO.new( content ) }
    it_behaves_like "an input stream wrapper"
  end

  describe "with throttled IO" do
    let( :io ) { ByteAtATimeIO.new( content ) }

    it_behaves_like "an input stream wrapper"
  end

end
