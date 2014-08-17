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

    if search_letters.count == 1
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
      VIM.command("let b:last_search_pattern = '#{matched_string}'")
    end

    noise
  end

  def self.get_file_search_results(max_results)
    results        = []
    patterns       = []
    noises         = []
    found          = 0

    files          = VIM.evaluate("s:files")
    search_letters = VIM.evaluate("s:search_letters")

    files.each.with_index do |name, index|
      bufname = (RUBY_VERSION.to_f < 1.9) ? name.to_s : name.to_s.force_encoding("UTF-8")
      search_noise = search_letters.empty? ? 0 : find_lowest_search_noise(bufname)
      i = index + 1

      if search_noise == -1
        next
      elsif max_results.zero?
        found += 1
        results  << "{ 'number': #{i}, 'raw': '#{bufname}', 'search_noise': #{search_noise} }"
        patterns << VIM.evaluate("b:last_search_pattern")
      elsif found < max_results
        found += 1
        results  << "{ 'number': #{i}, 'raw': '#{bufname}', 'search_noise': #{search_noise} }"
        patterns << VIM.evaluate("b:last_search_pattern")
        noises   << search_noise
      else
        max_index = noises.index(noises.max)
        if noises[max_index] > search_noise
          results[max_index]  = "{ 'number': #{i}, 'raw': '#{bufname}', 'search_noise': #{search_noise} }"
          patterns[max_index] = VIM.evaluate("b:last_search_pattern")
          noises[max_index]   = search_noise
        end
      end
    end

    if results.size > 0
      VIM.command("let b:file_search_results = [#{results.join(",")}]")
      VIM.command("let b:file_search_patterns = ['#{patterns.join("','")}']")
    else
      VIM.command("let b:file_search_results = []")
      VIM.command("let b:file_search_patterns = []")
    end
  end

  def self.prepare_buftext_to_display(buflist)
    columns                 = VIM.evaluate("&columns")
    unicode_font            = VIM.evaluate("g:ctrlspace_unicode_font") > 0
    star1                   = VIM.evaluate("g:ctrlspace_symbols.star1")
    star2                   = VIM.evaluate("g:ctrlspace_symbols.star2")
    file_mode               = VIM.evaluate("s:file_mode") > 0
    workspace_mode          = VIM.evaluate("s:workspace_mode") > 0
    tablist_mode            = VIM.evaluate("s:tablist_mode") > 0
    bookmark_mode           = VIM.evaluate("s:bookmark_mode") > 0
    active_workspace_name   = VIM.evaluate("s:active_workspace_name")
    active_workspace_digest = VIM.evaluate("s:active_workspace_digest")
    active_bookmark         = VIM.evaluate("s:active_bookmark")
    start_window            = VIM.evaluate("t:ctrlspace_start_window")

    buftext                 = ""

    if RUBY_VERSION.to_f < 1.9
      star1 = star1.to_s
      star2 = star2.to_s
    else
      star1 = star1.to_s.force_encoding("UTF-8")
      star2 = star2.to_s.force_encoding("UTF-8")
    end

    buflist.each do |entry|
      bufname = (RUBY_VERSION.to_f < 1.9) ? entry["raw"].to_s : entry["raw"].to_s.force_encoding("UTF-8")

      if bufname.length + 7 > columns
        dots_symbol = unicode_font ? "…" : "..."
        bufname = "#{dots_symbol}#{bufname[(bufname.length - columns + 7 + dots_symbol.length)..-1]}"
      end

      if !file_mode && !workspace_mode && !tablist_mode && !bookmark_mode
        indicators = ""

        indicators << "+" if VIM.evaluate("getbufvar(#{entry["number"]}, '&modified')") > 0

        win = VIM.evaluate("bufwinnr(#{entry["number"]})")

        if win == start_window
          indicators << star2
        elsif win != -1
          indicators << star1
        end

        bufname << " #{indicators}" unless indicators.empty?
      elsif workspace_mode
        if entry["raw"] == active_workspace_name
          bufname << " "
          bufname << "+" if active_workspace_digest != VIM.evaluate("<SID>create_workspace_digest()")
          bufname << star2
        end
      elsif tablist_mode
        indicators = ""
        indicators << "+" if VIM.evaluate("ctrlspace#tab_modified(#{entry["number"]})") > 0
        indicators << star2 if entry["number"] == VIM.evaluate("tabpagenr()")
        bufname << " #{indicators}" unless indicators.empty?
      elsif bookmark_mode
        indicators = ""

        unless active_bookmark.empty?
          bookmarks = VIM.evaluate("s:bookmarks")
          indicators << star2 if bookmarks[entry["number"] - 1]["directory"] == active_bookmark["directory"]
        end

        bufname << " #{indicators}" unless indicators.empty?
      end

      while bufname.length < columns
        bufname << " "
      end

      buftext << "  #{bufname}\n"
    end

    buftext.gsub!('"', '\"')
    buftext
  end
end
