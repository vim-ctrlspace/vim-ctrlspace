-- Native Neovim counterpart of CtrlSpace's bundled Vim9 matcher.
-- Adapted from fuzzbox.vim's ProcessResults, FuzzySearch and AddHlPositions:
-- https://github.com/vim-fuzzbox/fuzzbox.vim
-- Revision: 006fffcec7f67fd19ec56f35ba45dabfcac73d64
-- Copyright (c) 2023 vim-fuzzbox. MIT; see third_party/fuzzbox/LICENSE.

local M = {}

local function copy_item(item)
  local result = {}
  for key, value in pairs(item) do
    result[key] = value
  end
  return result
end

--- Match item.text and return copied items in descending native score order.
--- Existing fields (including index and indicators) are preserved. Added fields
--- are score and positions, the zero-based character offsets from matchfuzzypos.
--- Equal scores retain input order. A nonpositive limit returns all matches;
--- an empty query preserves input order and adds empty positions and score 0.
function M.search(items, query, limit)
  limit = limit or 0
  local matches, positions, scores
  if query == "" then
    matches = items
  else
    -- matchseq preserves CtrlSpace's literal, ordered query, including spaces.
    -- Native limit stops at the first N matches, not the best N: trim only
    -- after every candidate has been scored so late exact matches can win.
    -- Recent Neovim versions use smart case. Lowercase the query to retain
    -- CtrlSpace's case-insensitive matching regardless of editor options.
    local results = vim.fn.matchfuzzypos(items, vim.fn.tolower(query), {
      key = "text",
      matchseq = 1,
    })
    matches, positions, scores = results[1], results[2], results[3]
  end

  local count = #matches
  if limit > 0 then
    count = math.min(count, limit)
  end
  local result = {}
  for index = 1, count do
    local item = copy_item(matches[index])
    item.positions = positions and positions[index] or {}
    item.score = scores and scores[index] or 0
    result[index] = item
  end
  return result
end

--- Convert native character offsets into matchaddpos byte ranges.
--- Return {line, one-based byte column, byte length}, merging adjacent matches.
--- byteidx skips composing characters, matching matchfuzzypos's offsets; the
--- explicit length highlights a complete multibyte character or composing run.
function M.highlight_positions(text, positions, lnum)
  -- Native word matching can return overlapping or out-of-order offsets.
  -- Normalize a copy so callers can safely reuse the original search result.
  local ordered = {}
  for index, position in ipairs(positions) do
    ordered[index] = position
  end
  table.sort(ordered)
  local unique = {}
  for _, position in ipairs(ordered) do
    if #unique == 0 or position ~= unique[#unique] then
      unique[#unique + 1] = position
    end
  end

  local result = {}
  local index = 1
  while index <= #unique do
    local start = unique[index]
    local next_index = index + 1
    while next_index <= #unique
      and unique[next_index] == unique[next_index - 1] + 1
    do
      next_index = next_index + 1
    end
    local column = vim.fn.byteidx(text, start)
    local end_column = vim.fn.byteidx(text, start + next_index - index)
    if column >= 0 and end_column > column then
      result[#result + 1] = { lnum, column + 1, end_column - column }
    end
    index = next_index
  end
  return result
end

return M
