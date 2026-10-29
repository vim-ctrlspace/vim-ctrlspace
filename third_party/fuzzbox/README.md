# Bundled fuzzbox matching adapter

CtrlSpace includes a small adaptation of fuzzbox.vim's native matching and
highlight conversion code. It does not require a separate fuzzbox installation.

## Source

* Upstream: [vim-fuzzbox/fuzzbox.vim](https://github.com/vim-fuzzbox/fuzzbox.vim).
* Revision: `006fffcec7f67fd19ec56f35ba45dabfcac73d64`.
* Source file: [autoload/fuzzbox/internal/selector.vim](https://github.com/vim-fuzzbox/fuzzbox.vim/blob/006fffcec7f67fd19ec56f35ba45dabfcac73d64/autoload/fuzzbox/internal/selector.vim).
* Adapted functions: `FuzzySearch`, `ProcessResults`, and `AddHlPositions`.
* License: MIT, copyright (c) 2023 vim-fuzzbox. The original notice is preserved
  verbatim in [LICENSE](LICENSE).

## Integration

[autoload/ctrlspace/vendor/fuzzbox.vim](../../autoload/ctrlspace/vendor/fuzzbox.vim)
contains the Vim9 adaptation. The corresponding Neovim implementation is in
[lua/ctrlspace/matcher.lua](../../lua/ctrlspace/matcher.lua).
[autoload/ctrlspace/matcher.vim](../../autoload/ctrlspace/matcher.vim) dispatches
between them without loading Vim9 code in Neovim.

Both adapters call the editor's built-in `matchfuzzypos()` and convert its
parallel result lists into copied CtrlSpace candidate dictionaries, retaining
the original item indices and indicators. They convert character offsets into
byte ranges for `matchaddpos()`.

## Local changes

The extraction removes popup imports, plugin globals, selector state, and UI
callbacks. It exposes matching and highlight conversion only; CtrlSpace keeps
its existing lists, controls, tabs, and workspaces. The upstream popup UI,
commands, file collectors, and timer-based asynchronous selector are not
included.

Search accepts CtrlSpace dictionaries through the `text` key. Queries are
lowercased and use `matchseq` to preserve case-insensitive ordered matching,
including spaces. All candidates are scored before the adapter applies the
result limit. This differs from upstream's synchronous `max_results` cutoff,
which stops matching after the first requested number of hits. Native score
ordering and stable input order for ties are retained. CtrlSpace reverses the
results for its existing best-match-at-the-bottom presentation.

Highlight conversion sorts and deduplicates a copy of the positions, merges
adjacent offsets, and emits explicit byte lengths for every range, including
single multibyte characters and their composing marks. The caller handles
display clipping and line margins. No search regex or external protocol is
constructed.

The Vim9 adapter requires Vim 9.0+ with `+vim9script` and `matchfuzzypos()`.
The Lua counterpart requires Neovim 0.9+ with `matchfuzzypos()`. Native scores
can vary between editor versions; this adapter does not vendor or replace the
editor's fuzzy matching algorithm.
