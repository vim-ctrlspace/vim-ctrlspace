vim9script

# Matching and highlight conversion adapted from fuzzbox.vim's
# autoload/fuzzbox/internal/selector.vim at
# 006fffcec7f67fd19ec56f35ba45dabfcac73d64.
# Copyright (c) 2023 vim-fuzzbox. MIT license: third_party/fuzzbox/LICENSE.
#
# This extraction has no popup, plugin-global, or runtimepath dependencies.
# CtrlSpace keeps each candidate's identity and renders its own list window.

export def Search(items: list<dict<any>>, query: string,
        limit: number = 200): list<dict<any>>
    var matches: list<dict<any>> = []
    if empty(items)
        return matches
    endif

    if empty(query)
        var count = limit > 0 ? min([limit, len(items)]) : len(items)
        for idx in range(count)
            var item = copy(items[idx])
            item.positions = []
            item.score = 0
            add(matches, item)
        endfor
        return matches
    endif

    # Preserve CtrlSpace's case-insensitive, ordered subsequence queries.
    # Do not use matchfuzzypos()'s limit: that stops at the first N matches,
    # potentially missing a better candidate at the end of a large project.
    var results = matchfuzzypos(items, tolower(query), {key: 'text', matchseq: 1})
    var count = limit > 0 ? min([limit, len(results[0])]) : len(results[0])
    for idx in range(count)
        var item = copy(results[0][idx])
        item.positions = results[1][idx]
        item.score = results[2][idx]
        add(matches, item)
    endfor
    return matches
enddef

# Fuzzbox's AddHlPositions, returning explicit byte lengths for every run.
# Native fuzzy positions count characters, not bytes; byteidx() also keeps
# composing marks with their base character when constructing a byte range.
export def HighlightPositions(text: string, positions: list<number>,
        lnum: number): list<list<number>>
    var highlights: list<list<number>> = []
    # Multiword matchers may return repeated or unordered positions. Keep this
    # converter usable independently of Search()'s matchseq option as well.
    var sorted_positions = uniq(sort(copy(positions), 'n'))
    var i = 0
    while i < len(sorted_positions)
        var start = sorted_positions[i]
        var j = i + 1
        while j < len(sorted_positions)
                && sorted_positions[j] == sorted_positions[j - 1] + 1
            j += 1
        endwhile
        var col = byteidx(text, start)
        var end_col = byteidx(text, sorted_positions[j - 1] + 1)
        if col >= 0 && col < strlen(text) && end_col > col
            add(highlights, [lnum, col + 1, end_col - col])
        endif
        i = j
    endwhile
    return highlights
enddef
