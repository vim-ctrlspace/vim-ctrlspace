#encoding: utf-8
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

  def self.get_buflist_string(buflist)
    # TODO test how much slower to return only the list and join in vim
    buflist.map {|bufitem| bufitem['text']}.join
  end

  def self.decorate_with_indicators(name, bufnum, preview_mode_orginal_buffer, bufwinnr, modified, ctrlspace_unicode_font)
    indicators = ' '
    name

    if (preview_mode_orginal_buffer == bufnum)
        indicators += ctrlspace_unicode_font ? "☆" : "*"
    elsif (bufwinnr != -1)
        indicators += ctrlspace_unicode_font ? "★" : "*"
    end

    if modified
        indicators += "+"
    end

    if indicators.length > 1
        name += indicators
    end

    name
  end

  def self.get_magic_bufname(entry, columns, dots_symbol, dots_symbol_size, workspace_mode, active_workspace_name, star_symbol, file_mode, active_workspace_digest, workspace_digest, bufwinnr, preview_mode_orginal_buffer, modified, ctrlspace_unicode_font)

      if (!file_mode && !workspace_mode)


        bufname = entry['raw']
        if (bufname.length + 6 > columns)
            bufpart = bufname.length - columns + 6 + dots_symbol_size
            bufname = bufname[bufpart..-1]
            bufname = "#{dots_symbol}#{bufname}"
        end

        if (workspace_mode)
            if (entry['raw'] == active_workspace_name)
                bufname += star_symbol

                if (active_workspace_digest != workspace_digest)
                    bufname += "+"
                end
            end
        end

    else
        bufname = self.decorate_with_indicators(entry['raw'], entry['number'], preview_mode_orginal_buffer, bufwinnr, modified, ctrlspace_unicode_font)
    end

      bufname
  end

  def self.space_pad(bufname, columns, ctrlspace_unicode_font)

    if (bufname.length < columns)
       bufname += " " * (columns - bufname.length)
    end

    if (ctrlspace_unicode_font)
      bufname += "  "
    end

    bufname = "  " + bufname + "\n"

    bufname
  end

end
