# encoding: utf-8

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
    search_letters    = VIM.evaluate("s:search_letters")
    search_resonators = VIM.evaluate("g:ctrlspace_search_resonators")
    noise             = -1
    matched_string    = ""

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

          unless search_resonators.empty?
            noise += 1 if (subseq[1][0] != 0) && !search_resonators.include?(bufname[subseq[1][0] - 1])
            noise += 1 if (subseq[1][-1] != bufname_len - 1) && !search_resonators.include?(bufname[subseq[1][-1] + 1])
          end
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

  def self.prepare_buftext_to_display(buflist)
    columns                 = VIM.evaluate("&columns")
    unicode_font            = VIM.evaluate("g:ctrlspace_unicode_font") > 0
    file_mode               = VIM.evaluate("s:file_mode") > 0
    workspace_mode          = VIM.evaluate("s:workspace_mode") > 0
    tablist_mode            = VIM.evaluate("s:tablist_mode") > 0
    preview_mode            = VIM.evaluate("s:preview_mode") > 0
    active_workspace_name   = VIM.evaluate("s:active_workspace_name")
    active_workspace_digest = VIM.evaluate("s:active_workspace_digest")

    buftext                 = ""

    buflist.each do |entry|
      bufname = (RUBY_VERSION.to_f < 1.9) ? entry["raw"].to_s : entry["raw"].to_s.force_encoding("UTF-8")

      if bufname.length + 7 > columns
        dots_symbol = unicode_font ? "…" : "..."
        bufname = "#{dots_symbol}#{bufname[(bufname.length - columns + 7 + dots_symbol.length)..-1]}"
      end

      if !file_mode && !workspace_mode && !tablist_mode
        indicators = ""

        indicators << "+" if VIM.evaluate("getbufvar(#{entry["number"]}, '&modified')") > 0

        if preview_mode && (VIM.evaluate("s:preview_mode_original_buffer") == entry["number"])
          indicators << (unicode_font ? "☆" : "*")
        elsif VIM.evaluate("bufwinnr(#{entry["number"]})") != -1
          indicators << (unicode_font ? "★" : "*")
        end

        bufname << " #{indicators}" unless indicators.empty?
      elsif workspace_mode
        if entry["raw"] == active_workspace_name
          bufname << " "
          bufname << "+" if active_workspace_digest != VIM.evaluate("<SID>create_workspace_digest()")
          bufname << (unicode_font ? "★" : "*")
        end
      elsif tablist_mode
        indicators = ""
        indicators << "+" if VIM.evaluate("ctrlspace#tab_modified(#{entry["number"]})") > 0
        indicators << (unicode_font ? "★" : "*") if entry["number"] == VIM.evaluate("tabpagenr()")
        bufname << " #{indicators}" unless indicators.empty?
      end

      while bufname.length < columns
        bufname << " "
      end

      buftext << "  #{bufname}\n"
    end

    buftext
  end
end
