module CtrlSpace
  def self.find_subsequence(bufname, offset, search_letters)
    positions      = []
    noise          = 0
    current_offset = offset

    search_letters.each do |letter|
      matched_position = bufname.index(/#{letter}/i, current_offset)

      if matched_position.nil?
        return [-1, []]
      else
        noise += (matched_position - positions[-1]).abs - 1 unless positions.empty?
        positions << matched_position
        current_offset = matched_position + 1
      end
    end

    [noise, positions]
  end

  def self.find_lowest_search_noise(bufname)
    search_letters       = VIM.evaluate("s:search_letters")
    noise                = -1
    matched_string       = ""

    if search_letters.count == 0
      return 0
    elsif search_letters.count == 1
      noise          = bufname.index(/#{search_letters[0]}/i) || -1
      matched_string = search_letters[0]
    else
      offset      = 0
      bufname_len = bufname.length

      while offset < bufname_len
        subseq = find_subsequence(bufname, offset, search_letters)

        if subseq[0] == -1
          break
        elsif (noise == -1) || (subseq[0] < noise)
          noise          = subseq[0]
          offset         = subseq[1][0] + 1
          matched_string = bufname[subseq[1][0]..subseq[1][-1]]
        else
          offset += 1
        end
      end
    end

    if noise > -1 && !matched_string.empty?
      VIM.command("let b:search_patterns['#{matched_string}'] = 1")
    end

    noise
  end
end
