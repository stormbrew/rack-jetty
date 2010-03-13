module RackJetty
  class JavaInput
    def initialize(input)
      @input = input
    end
    
    # reads count bytes into into_buffer, returns nil at EOF, otherwise
    # returns into_buffer.
    def read_bytes(count, into_buffer)
      data = "\0" * count
      data = data.to_java_bytes
      count = @input.read(data, 0, count)
      if (count == -1)
        return nil
      end
      into_buffer << String.from_java_bytes(data[0,count])
      return into_buffer
    end
    
    # Reads the entire string into_buffer
    def read_all(into_buffer)
      while (read_bytes(4096, into_buffer))
        # work is in the loop condition.
      end
      return into_buffer
    end

    # If count is nil, reads the entire input into the buffer. Otherwise,
    # reads up to count bytes from the stream and puts them into buffer.
    # either way, returns buffer.
    def read(count = nil, buffer = "")
      if (count.nil?)
        read_all(buffer)
      else
        buffer = read_bytes(count, buffer)
      end
      return buffer
    end
    alias_method :gets, :read
    
    # Reads the input as chunked data and yields it piece by piece.
    def each
      while (s = read_bytes(4096, ""))
        yield s
      end
    end
  end
end