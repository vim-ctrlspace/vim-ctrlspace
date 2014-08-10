<div align="center">
<img alt="Vim-CtrlSpace" 
src="https://raw.github.com/szw/vim-ctrlspace/master/gfx/logo.png" />
</div>


#### Table of Contents

* [Overview](#overview)
  * [What's so special?](#whats-so-special)
  * [Demo](#demo)
* [Getting Started](#getting-started)
  * [Colors](#colors)
  * [Status Line](#status-line)
  * [Tabline](#tabline)
  * [Project Root](#project-root)
  * [User Interface](#user-interface)
  * [Tab Management](#tab-management)
* [Lists](#lists)
  * [Buffer List](#buffer-list)
  * [File List](#file-list)
  * [Tab List](#tab-list)
  * [Workspace List](#workspace-list)
  * [Bookmark List](#bookmark-list)
* [Common Modes](#common-modes)
  * [Search Mode](#search-mode)
  * [Nop Mode](#nop-mode)
* [Configuration](#configuration)
* [API ](#api)
  * [Commands](#commands)
  * [Functions](#functions)
* [Authors and License](#authors-and-license)


# Overview

**Vim-CtrlSpace** is a Vim plugin for creating and managing lists of
buffers, files, tabs, workspaces (sessions), and finally bookmarks (projects).
Its approach is somewhat unique, but certainly you will feel at home quickly,
especially if you used intensively split windows, tabs, buffers, etc.

You can think of it as a buffer/file/tab explorer mixed with a fuzzy finder
like [CtrlP](https://github.com/kien/ctrlp.vim), and a session and project
explorer. Pretty wide area, isn't it?

But this idea seems to work quite well and the plugin may become your coolest
companion. It can help you to manage your Vim workspace and increase your usage
of core Vim features like multiple buffers, tabs, and windows in a great degree.
The plugin can also provide you with some new concepts, like workspaces, named
tabs, or separate buffer lists. 

It is worth to say, both for me and other plugin users, Vim-CtrlSpace became the
most important tool in the Vim toolbox or a strong complement to their existing
workflow.


## What's so special?

Visually, Vim-CtrlSpace is just a temporary window that sticks to the bottom of
screen and contains a list from which you can select items. Although it acts as
a [_split
explorer_](http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/),
it doesn't show up in the split window itself. Rather, it creates a temporary
preview window similarly to [CtrlP](https://github.com/kien/ctrlp.vim).

<p align="center">
<img alt="Vim-CtrlSpace" 
src="https://raw.github.com/szw/vim-ctrlspace/master/gfx/plugin_window.png" /><br />
<em>Sample Plugin Window</em>
</p>

The plugin window can display various lists: a list of open tab pages, a Buffer
List (for current tab only or for all open buffers), a File List, a Workspace
List, and last but not least, a Bookmark List. Within those lists you can both
navigate to selected items and manage them as well - rename, add, delete, move,
copy, and so on.

Buffer and File Lists are rather obvious ones. You can look for buffers/files
with fuzzy search algorithm. But the special part here is this: each tab page
contains its own Buffer List with buffers related to that tab only. _Related_
means the given buffer has been shown in the given tab at least once. In that
way you have separate sets of buffers for each tab. And that's really useful. Of
course, the _all buffers_ mode is still available. 

The Workspace List is also something very unique. You can name your tabs and you
can save the whole set of tabs and buffers as a workspace in your project
directory and reopen it later. The Tab List is something comparable to Vim's
tabline. However the Vim's tabline has several limitations, like tab count or
tabline length. The Tab List was introduced as a convenient replacement of Vim
tabline. Needless to say, you can perform moving, copying, renaming, and
deleting operations on tab items too.

The last list available in Vim-CtrlSpace is the Bookmark list. Vim-CtrlSpace
tries to handle files and buffers relative to the current working directory. It
can also try to guess the project root. But of course you are not limited to one
project root only. You can change/navigate to various working directories even
through the `:cd` command. Bookmarks are just shortcuts to your favorite
directories (projects). You can save some time here by jumping to different
locations with friendly names. In that way you can literally jump between
various projects, manage (or interchange) files/buffers/workspaces between them,
etc. 

The plugin name follows the convention of naming similar plugins after their
default mappings (like _Command-T_ or _CtrlP_). Obviously, the plugin mapping is
by default `Ctrl + Space`. 

If you like the plugin please don't forget to add a star (:star:)! This will
help me to estimate the plugin popularity and that way I will proceed better its
further development :).

If you have starred this repo already, thank you! Thanks to you it's my pet
project now :). If you have a question, a feature request, or a new idea, don't
hesitate to post new issues or pull requests. The collaboration is the most
exciting thing in the open source community.


## Demo

If you are still a bit unsure whether is it something you should try, here's
a small demonstration. Viewing in HD advised!

<p align="center">
<a href="https://www.youtube.com/watch?v=U1hbGJm3J0g">
<img alt="Vim-CtrlSpace 4.0 Demo" 
src="https://raw.github.com/szw/vim-ctrlspace/master/gfx/screen_small.png" />
</a>
</p>

There is also an [older version available](https://www.youtube.com/watch?v=09l92uwKupI),
a bit more verbose.

The Demo has been recorded with: 

- a console Vim 7.4 (Monaco font)
- a bit modified [Seoul256 color scheme](https://github.com/szw/seoul256.vim)
- following Vim-CtrlSpace settings in .vimrc:

        hi CtrlSpaceSelected term=reverse ctermfg=187  ctermbg=23  cterm=bold
        hi CtrlSpaceNormal   term=NONE    ctermfg=244  ctermbg=232 cterm=NONE
        hi CtrlSpaceSearch   ctermfg=220  ctermbg=NONE cterm=bold
        hi CtrlSpaceStatus   ctermfg=230  ctermbg=234  cterm=NONE

- music licensed under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/)
  1. Kate Orange - [Oops](http://www.jamendo.com/pl/track/474843/oops)
  2. Alex F - [Rain](http://www.jamendo.com/pl/track/975564/rain)


# Getting Started

The plugin installation is really simple. You can use Vundle or Pathogen, or
just clone the repository to your `.vim` directory. In case of Vundle, add:

    Plugin 'szw/vim-ctrlspace' 

to your `.vimrc`.

To improve your overall experience please enable the `hidden` option too:

    set hidden

If you want to increase plugin speed (e.g. fuzzy search), make sure you have 
decent Ruby bindings enabled in (compiled into) your Vim. The plugin will try 
to use your Ruby by default.


## Colors

You should also improve default plugin colors to work well with your
colorscheme. For example, When I work in the terminal Vim I use slightly
modified [Seoul256](https://github.com/szw/seoul256.vim) colorscheme originally
developed by [Junegunn Choi](https://github.com/junegunn/seoul256.vim).

Therefore, I put following settings in my `.vimrc`:

```VimL
hi CtrlSpaceSelected term=reverse ctermfg=187   guifg=#d7d7af ctermbg=23    guibg=#005f5f cterm=bold gui=bold
hi CtrlSpaceNormal   term=NONE    ctermfg=244   guifg=#808080 ctermbg=232   guibg=#080808 cterm=NONE gui=NONE
hi CtrlSpaceSearch   ctermfg=220  guifg=#ffd700 ctermbg=NONE  guibg=NONE    cterm=bold    gui=bold
hi CtrlSpaceStatus   ctermfg=230  guifg=#ffffd7 ctermbg=234   guibg=#1c1c1c cterm=NONE    gui=NONE
```

If you use a terminal Vim you can use [that
chart](http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html) to
discover best colors matching your colorscheme. To find out more about enabling
256 colours in your terminal check e.g. Tom Ryder's blog 
\- [Arabesque](http://blog.sanctum.geek.nz/256-colour-terminals/).

For MacVim I use
[Solarized](https://github.com/altercation/vim-colors-solarized) color scheme
(dark background), so I found these settings to work well:

```VimL
hi CtrlSpaceSelected guifg=#021B25 guibg=#93A1A1 gui=bold
hi CtrlSpaceNormal   guifg=#839496 guibg=#021B25 gui=NONE
hi CtrlSpaceSearch   guifg=#9b1b06 guibg=NONE    gui=bold
hi CtrlSpaceStatus   guifg=#000000 guibg=#667B83 gui=NONE
```

Notice, it's worth to spent some time to adjust settings to someting
eye-pleasant, because chances are, you will use (a thus see) the plugin a lot ;). 

If you use a popular colorscheme and you would like to share your
settings, I'd love to add them here! Please post a pull request, an issue or
just an [email](mailto:szymon@wrozynski.com).


## Status Line

**Vim-CtrlSpace** requires a status bar. If you are using a plugin customizing
the status bar this might be a bit tricky. For example
[vim-airline](https://github.com/bling/vim-airline) plugin might require you to
set: `let g:airline_exclude_preview = 1` option and
[LightLine](https://github.com/itchyny/lightline.vim) will require to use custom
status line segments, provided by **Vim-CtrlSpace** API.


## Tabline

**Vim-CtrlSpace** can set a custom tabline. If the proper option is enabled
(`g:ctrlspace_use_tabline`), the plugin will set a custom tabline for you. The
tabs in that tabline are displayed in the following way (similar format is used
also in the Tab List):

| Format  | Tab number | Buffers | Modified | Buffer or tab name |
| ------- |:----------:|:-------:|:--------:|:------------------:|
| Unicode | `1`        | `²`     | `+`      | `[README.md]`      |
| ASCII   | `1`        | `:2`    | `+`      | `[README.md]`      |

If GUI tabs are detected, this option will also set the proper function to
`guitablabel`.

Notice, that if you intensify your tabs usage, the Vim tabline feature could
become less usable, because of increasing tab number, especially with long
names. However, there is no need to worry. Moreover, its perfectly fine to even
turn off tabline completely because plugin has a Tab List ready for you. If you
feel brave or you are just curious try to add `set showtabline=0` to your
`.vimrc` and try out plugin Tab List instead (press `l` in the plugin window).


## Project Root

Some plugin features require a project root to work properly. If you open the
File List for the first time it will try to find out the possible root
directory. First, it starts in the Vim's current working directory and check if
there are so called _root markers_. The root markers are characteristic
directories that are available in an exemplary project root directory, like e.g.
`.git` or `.hg` ones. You can define them yourself in the
`g:ctrlspace_project_root_markers` variable. If no markers were found the plugin
will check if perhaps this directory is a known root. The known roots are those
ones you provided (accepted) yourself when no markers were found. If the current
directory cannot be proven as a project root, the algorithm will repeat the
whole procedure in the parent one. 

After checking all predecessors it will ask you to provide the root folder
explicitly. After your acceptance that root folder will be stored pemanently in
the `.cs_cache` file as serve as a known root later.

If you add the directory to bookmarks, it will be considered as project root
automatically.


## User Interface

**Vim-CtrlSpace** contains 5 different lists: _Buffer List_, _File List_, _Tab
List_, _Workspace List_, and _Bookmark List_. Some of those have additional
modes. However, in a modal editor like Vim this should not fear you ;). 

You can jump between lists easily by pressing one of the following keys:

| Key      | Action                                                 |
|:--------:| ------------------------------------------------------ |
| `o`      | Jump to File List (aka Open List)                      |
| `O`      | Jump to File List (aka Open List) in Search Mode       | 
| `l`      | Jump to Tab List                                       |
| `w`      | Jump to Workspace List                                 |
| `b`      | Jump to Bookmark List                                  |

Since the _Buffer List_ is the default one, in order to jump to it press
one of those keys again (except `O`) or just hit `Backspace`.

User interface of the plugin is a window with a list. Its status line contains
important symbolic information:

| Unicode Symbol | ASCII Symbol  | List        | Description                |
|:--------------:|:-------------:| ----------- | -------------------------- |
| `⌗`            | `#`           | All         | Vim-CtrlSpace symbol       |
| `⊙`            | `TAB`         | Buffer      | Single Mode indicator      |
| `∷`            | `ALL`         | Buffer      | All Mode indicator         |
| `◎`            | `OPEN`        | File        | (Open) File List indicator |
| `⌕`            | `*`           | Buffer      | Preview Mode indicator     |
| `›_‹`          | `[_]`         | Buffer/File | Search Mode indicator      |
| `○●○`          | `-+-`         | Tab         | Tab List indicator         |
| `⋮ → ∙`        | `LOAD`        | Workspace   | Workspace Load Mode        |
| `∙ → ⋮`        | `SAVE`        | Workspace   | Workspace Save Mode        |
| `♡`            | `BM`          | Bookmark    | Bookmark List indicator    |

Items listed in the plugin window can have additional indicators (following the
item text):

| Unicode | ASCII | Indicator                |
|:-------:|:-----:| ------------------------ |
| `+`     | `+`   | Item modified            |
| `★`     | `*`   | Item visible (or active) |


## Tab Management

Tabs in **Vim-CtrlSpace** (like in Vim) are groups of related buffers. The
plugin lets you to perform many classic tab actions easily in the Buffer List
view and of course in the Tab List view (turned on with letter `l`). 
Those ones include e.g. switching (`[` and `]`), moving (`+` and `-`), 
closing (uppercase `C`), or renaming (`=`). 

You can also create empty tabs (`T`) or copy them (`Y`). The latter action is
useful if you want to split your tab (your group of buffers) into smaller ones.
Referring to the demo example, the tab `Users` (holding model files, controller
files and views) could be split into something like `Users (models)` and 
`Users (views)`. `Users (models)` could then have model and controller files 
whereas `Users (views)` could be storing controller and view ones. With the 
help of tab copying (`Y`) all you need is to copy the `Users` tab, close 
superfluous buffers in each (lowercase `c`), and finally rename both (`=`). 
Of course, the split shown in that example might be a bit dummy but in 
a typical project there are a lot of natural splits, like for example, 
backend and frontend layers.


# Lists

The most inner list is the Buffer List. It stores buffers for the given tab. The
File List is a special case here containing buffers and not opened yet files.
Similarly, the All Mode includes all listed buffers. The Tab List encloses many
Buffer Lists. Workspace List encloses many Tab Lists, and finally the Bookmark
List encloses many Workspace Lists (one per project root).

Here's the graphic illustration of those relations.

<p align="center">
<img alt="Vim-CtrlSpace Lists" 
src="https://raw.github.com/szw/vim-ctrlspace/master/gfx/lists.png" />
</p>


## Buffer List

This is the basic list of the plugin. Depending of its mode it can collect
buffers from the current tab or buffers from all tabs. 


### Single Mode

| Unicode | ASCII |
|:-------:|:-----:|
| `⊙`     | `TAB` |

The first mode of Buffer List is the Single one. In that mode, the plugin
shows you only buffers related to the current tab. Here's the full listing of
all available keys:


#### Opening

| Key      | Action                                               |
|:--------:| ---------------------------------------------------- |
| `Return` | Open a selected buffer                               |
| `Space`  | Open a selected buffer and stay in the plugin window |
| `Tab`    | Enter the Preview Mode for selected buffer           |
| `v`      | Open a selected buffer in a new vertical split       |
| `s`      | Open a selected buffer in a new horizontal split     |
| `t`      | Open a selected buffer in a new tab                  |


#### Searching & Sorting

| Key        | Action                                              |
|:----------:| --------------------------------------------------- |
| `/`        | Enter the Search Mode                               |
| `Ctrl + p` | Bring back the previous searched text               |
| `Ctrl + n` | Bring the next searched text                        |


#### Tabs Operations

| Key    | Action                                                  |
|:------:| ------------------------------------------------------- |
| `T`    | Create a new tab and stay in the plugin window          |
| `Y`    | Copy (yank) the current tab into a new one              |
| `0..9` | Jump to the n-th tab (0 is for the 10th one)            |
| `g`    | Jump to a next tab containing the selected buffer       |
| `G`    | Jump to a previous tab containing the selected buffer   |
| `-`    | Move the current tab to the left (decrease its number)  |
| `+`    | Move the current tab to the right (increase its number) |
| `=`    | Change the tab name                                     |
| `_`    | Remove a custom tab name                                |
| `[`    | Go to the previous (left) tab                           |
| `]`    | Go to the next (right) tab                              |
| `{`    | Move the selected buffer to to the previous (left) tab  |
| `}`    | Move the selected buffer to the next (right) tab        |
| `<`    | Copy the selected buffer to to the previous (left) tab  |
| `>`    | Copy the selected buffer to the next (right) tab        |


#### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back                                         |
| `q`            | Close the list                                  |
| `Ctrl + c`     | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   | 
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |


#### Moving

| Key        | Action                                                    |
|:----------:| --------------------------------------------------------- |
| `j`        | Move the selection bar down                               |
| `k`        | Move the selection bar up                                 |
| `J`        | Move the selection bar to the bottom of the list          |        
| `K`        | Move the selection bar to the top of the list             |
| `p`        | Move the selection bar to the previous buffer             |
| `P`        | Move the selection bar to the previous buffer and open it |
| `n`        | Move the selection bar to the next opened buffer          |
| `Ctrl + f` | Move the selection bar one screen down                    |
| `Ctrl + b` | Move the selection bar one screen up                      |
| `Ctrl + d` | Move the selection bar a half screen down                 |
| `Ctrl + u` | Move the selection bar a half screen up                   |


#### Closing

| Key  | Action                                                              |
|:----:| ------------------------------------------------------------------- |
| `d`  | Delete the selected buffer (close it)                               |
| `D`  | Close all empty noname buffers                                      |
| `f`  | Forget the current buffer (make it a unrelated to the current tab)  |
| `F`  | Delete (close) all forgotten buffers (unrelated to any tab)         |
| `c`  | Try to close selected buffer (delete if possible, forget otherwise) |
| `C`  | Close the current tab, then perform `F`, and then `D`               |


#### Disk Operations

| Key  | Action                                                            |
|:----:| ----------------------------------------------------------------- |
| `e`  | Edit a sibling of the selected buffer                             |
| `E`  | Explore a directory of the selected buffer                        |
| `R`  | Remove the selected buffer (file) entirely (from the disk too)    |
| `m`  | Move or rename the selected buffer (together with its file)       |
| `y`  | Copy selected file                                                |


#### Mode and List Changing

| Key  | Action                                                             |
|:----:| ------------------------------------------------------------------ |
| `a`  | Toggle between Single and All modes                                |
| `A`  | Enter the Search Mode combined with the All mode                   |
| `o`  | Toggle the File List (Open List)                                   |
| `O`  | Enter the Search Mode in the File List                             |
| `l`  | Toggle the Tab List view                                           |
| `w`  | Toggle the Workspace List view                                     |
| `b`  | Toggle the Bookmark List view                                      |


#### Workspace shortcuts

| Key  | Action                                                              |
|:----:| ------------------------------------------------------------------- |
| `S`  | Save the workspace immediately (or creates a new one if none)       |
| `L`  | Load the last active workspace (if present)                         |


### All Mode

| Unicode | ASCII |
|:-------:|:-----:|
| `∷`     | `ALL` |

This mode is almost identical to the Single Mode, except it shows you all
available buffers (from all tabs and unrelated ones too). Some of keys presented
in the Single Mode are not available here. The missing ones are `f`, `c`,
`{`, `}`, `<`, `>` - as they are connected with current tab.


### Preview Mode

| Unicode | ASCII |
|:-------:|:-----:|
| `⌕`     | `*`   |

This mode works in a conjunction with the Buffer List. You can invoke the
Preview Mode by hitting the `Tab` key. Hitting `Tab` does almost the same as
`Space` - it shows you the selected buffer, but unlike `Space`, that change of
the target window content is not permanent. When you quit the plugin window, the
old (previous) content of the target window is restored.

Also the jumps history remains unchanged and the selected buffer won't be added
to the tab buffer list. In that way, you can just preview a buffer before
actually opening it (with `Space`, `Return`, etc). 

Those previewed files are marked on the list with the star symbol and the
original content is marked with an empty star too:

| Indicator        | Unicode | ASCII |
| ---------------- |:-------:|:-----:|
| Previewed buffer | `★`     | `*`   |
| Original buffer  | `☆`     | `*`   |


## File List

| Unicode | ASCII  |
|:-------:|:------:|
| `◎`     | `OPEN` |

This list shows you all files in the project and allows you to open a new file
(as a buffer) in the current tab. Notice, only the project root directory
is considered here in order to prevent you from accidental loading root of i.e.
your home directory, as it would be really time consuming (file scanning) and
rather pointless. If you bookmark a directory - it is taken as a project
root too.

For the first time the file list is populated with data. Sometimes, for a very
large project this could be quite time consuming (I've noticed a lag for
a project with over 2200 files). Also, it depends on files stored for example in
the SCM directory. In the end, the content of the project root directory is
cached and available immediately. All time you can force plugin to refresh the
list with the `r` key.


### Opening

| Key       | Action                                               |
|:---------:| ---------------------------------------------------- |
| `Return`  | Open a selected file                                 |
| `Space`   | Open a selected file but stays in the plugin window  |
| `v`       | Open a selected file in a new vertical split         |
| `s`       | Open a selected file in a new horizontal split       |
| `t`       | Open a selected file in a new tab                    |


### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back to Buffer List                          |
| `o`            | Go back to Buffer List                          |
| `q`            | Close the list                                  |
| `Ctrl + c`     | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   |
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |


### Tabs Operations

| Key    | Action                                                  |
|:------:| ------------------------------------------------------- |
| `T`    | Create a new tab and stay in the plugin window          |
| `Y`    | Copy (yank) the current tab into a new one              |
| `0..9` | Jump to the n-th tab (0 is for 10th one)                |
| `g`    | Jump to a next tab containing the selected file         |
| `G`    | Jump to a previous tab containing the selected file     |
| `-`    | Move the current tab to the left (decrease its number)  |
| `+`    | Move the current tab to the right (increase its number) |
| `=`    | Change the tab name                                     |
| `_`    | Remove a custom tab name                                |
| `[`    | Go to the previous (left) tab                           |
| `]`    | Go to the next (right) tab                              |


### Searching

| Key        | Action                                              |
|:----------:| --------------------------------------------------- |
| `/`        | Enter the Search Mode                               |
| `O`        | Enter the Search Mode                               |
| `Ctrl + p` | Bring back the previous searched text               |
| `Ctrl + n` | Bring the next searched text                        |


### Moving

| Key        | Action                                              |
|:----------:| --------------------------------------------------- |
| `j`        | Move the selection bar down                         |
| `k`        | Move the selection bar up                           |
| `J`        | Move the selection bar to the bottom of the list    |
| `K`        | Move the selection bar to the top of the list       |
| `Ctrl + f` | Move the selection bar one screen down              |
| `Ctrl + b` | Move the selection bar one screen up                |
| `Ctrl + d` | Move the selection bar a half screen down           |
| `Ctrl + u` | Move the selection bar a half screen up             |


### Closing

| Key | Action                                                     |
|:---:| ---------------------------------------------------------- |
| `C` | Close the current tab (with forgotten buffers and nonames) |


### Disk Operations

| Key | Action                                       |
|:---:| -------------------------------------------- |
| `e` | Edit a sibling of the selected buffer        |
| `E` | Explore a directory of the selected buffer   |
| `r` | Refresh the file list (force reloading)      |
| `R` | Remove the selected file entirely            |
| `m` | Move or rename the selected file             |
| `y` | Copy the selected file                       |


### List Changing

| Key | Action                                       |
|:---:| -------------------------------------------- |
| `l` | Toggle the Tab List view                     |
| `w` | Toggle the Workspace List view               |
| `b` | Toggle the Bookmark List view                |


## Tab List

| Unicode | ASCII |
|:-------:|:-----:|
| `○●○`   | `-+-` |

Tabs in **Vim-CtrlSpace**, due to this plugin nature, are used more extensively
than their normal Vim usage. Vim author, Bram Moolenaar in his great talk [_7
Habits of Effective Text Editing_](http://www.youtube.com/watch?v=p6K4iIMlouI)
stated that if you needed more than 10 tabs then probably you were doing
something wrong. In **Vim-CtrlSpace** tab pages are great, labelled containers
for buffers, and therefore their usage increases. All it means that sometimes
the default tabline feature used in Vim to organize tab pages is not
sufficient. For example, you might have more tabs (and with wider labels)
which don't fit the tabline width, causing rendering problems.

In the Tab List view you can list all tabs. You can even turn off your tabline 
entirely (via Vim's `showtabline` option) and stick to the Tab List only.


### Opening and closing

| Key      | Action                                                     |
|:--------:| ---------------------------------------------------------- |
| `Return` | Open a selected tab and enter the Buffer List view         |
| `Tab`    | Open a selected tab and close the plugin window            |
| `Space`  | Open a selected tab but stay in the Tab List view          |
| `0..9`   | Jump to the n-th tab (0 is for the 10th one)               |
| `c`      | Close the selected tab, then forgotten buffers and nonames |


### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back                                         |
| `l`            | Go back                                         |
| `w`            | Go to the Workspace List view                   |
| `b`            | Toggle the Bookmark List view                   |
| `o`            | Go to the File List view                        |
| `O`            | Go to the File List view in the Search Mode     |
| `q`            | Close the list                                  |
| `Ctrl + c`     | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   |
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |


### Tabs Operations

| Key | Action                                              |
|:---:| --------------------------------------------------- |
| `-` | Move the current tab backward (decrease its number) |
| `+` | Move the selected tab forward (increase its number) |
| `{` | Same as `-`                                         |
| `}` | Same as `+`                                         |
| `=` | Change the selected tab name                        |
| `_` | Remove the selected tab name                        |
| `[` | Go to the previous tab                              |
| `]` | Go to the next tab                                  |
| `t` | Create a new tab nexto to the current one           |
| `y` | Make a copy of the current tab                      |


### Moving

| Key        | Action                                                          |
|:----------:| --------------------------------------------------------------- |
| `j`        | Move the selection bar down                                     |
| `k`        | Move the selection bar up                                       |
| `J`        | Move the selection bar to the bottom of the list                |
| `K`        | Move the selection bar to the top of the list                   |
| `p`        | Move the selection bar to the previously opened tab             |
| `P`        | Move the selection bar to the previously opened tab and open it |
| `n`        | Move the selection bar to the next opened tab                   |
| `Ctrl + f` | Move the selection bar one screen down                          |
| `Ctrl + b` | Move the selection bar one screen up                            |
| `Ctrl + d` | Move the selection bar a half screen down                       |
| `Ctrl + u` | Move the selection bar a half screen up                         |


## Workspace List

| Unicode | ASCII  | Mode      |
|:-------:|:------:| --------- |
| `⋮ → ∙` | `LOAD` | Load Mode |
| `∙ → ⋮` | `SAVE` | Save mode |

The plugin allows you to save and load so called _workspaces_. A workspace is
a set of opened windows, tabs, their names, and buffers. In fact, the word
_workspace_ can be considered as a synonym of a _session_.

The ability of having so many _sessions_ available at hand creates a lot of
interesting use cases! For example, you can have a workspace for each task or
feature you are working on. It's very easy to switch from one workspace to
another, thus this could be helpful with reviewing completed tasks and
continuing work on an item after some period of time. Moreover, you can have
special workspaces that are prepared to be appended to others. Consider, e.g.
a _Config_ workspace. Imagine, you have a separate workspace with the only one
tab named _Config_ and some config files opened there. You can easily append
that workspace to the current or next ones, depending on your needs. That way
you are able to group the common and repetative sets of files in just one place
and reuse that group in many contexts.

The Workspace List shows you available workspaces. By default this list is
displayed in the _Load Mode_. The second available mode is the _Save_ one.

Workspaces are saved in a file (`[.]cs_workspaces`) inside the project
directory. Its extact name and path is determined by defined and found project
root markers. By default, the project root marker is taken as the destination
directory.

If there are 2 or more split windows in a tab, they will be recreated as
horizontal or vertical splits while loading (depending on
`g:ctrlspace_use_horizontal_splits` settings).

It's also possible to automatically load the last active workspace on Vim
startup and save it active workspace on Vim exit. See
`g:ctrlspace_load_last_workspace_on_start` and
`g:ctrlspace_save_workspace_on_exit` for more details.


### Accepting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Return`       | Load (or save) the selected workspace           |


### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back to the Buffer List                      |
| `w`            | Go to the Buffer List                           |
| `o`            | Go to the File List                             |
| `O`            | Go to the File List in the Search Mode          | 
| `l`            | Go to the Tab List                              |
| `b`            | Go to the Bookmark List                         |
| `q`            | Close the list                                  |
| `Ctrl + c`     | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   |
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |


### Workspace Operations

| Key  | Action                                          |
|:----:| ----------------------------------------------- |
| `a`  | Append a selected workspace to the current one  |
| `s`  | Toggle the mode from Load or Save (or backward) |
| `S`  | Save the workspace immediately                  |
| `L`  | Load the last active workspace (if present)     |
| `n`  | Makes a new workspace (closes all buffers)      |
| `d`  | Delete the selected workspace                   |


### Moving

| Key        | Action                                              |
|:----------:| --------------------------------------------------- |
| `j`        | Move the selection bar down                         |
| `k`        | Move the selection bar up                           |
| `J`        | Move the selection bar to the bottom of the list    |
| `K`        | Move the selection bar to the top of the list       |
| `Ctrl + f` | Move the selection bar one screen down              |
| `Ctrl + b` | Move the selection bar one screen up                |
| `Ctrl + d` | Move the selection bar a half screen down           |
| `Ctrl + u` | Move the selection bar a half screen up             |


## Bookmark List

Bookmarks can be treated as a Project list populated with your favorite
projects. With bookmarks you can easily jump between different directory
locations in Vim. The plugin will follow those jumps with its all settings.

In that way inside different projects you will have different file lists,
different workspace lists, etc. Nothing prevents you to mix buffers between
various projects - you can for example, jump to previous project, open
a configuration file, and return to your current stuff with that file open.

It's also worth to mention, that you can still navigate to different places
manually, with the `:cd` command. The plugin will behave in the same way. In
fact, jumping with Bookmark List is just a shortcut for the `:cd` command. 


### Changing CWD location 

| Key      | Action                                                     |
|:--------:| ---------------------------------------------------------- |
| `Return` | Jump to selected bookmark an enter the Buffer List         |
| `Tab`    | Jump to selected bookmark and close the plugin window      |
| `Space`  | Jump to selected bookmark but stay in the Bookmark List    |


### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back                                         |
| `b`            | Go back                                         |
| `w`            | Go to the Workspace List view                   |
| `l`            | Go to the Tab List view                         |
| `o`            | Go to the File List view                        |
| `O`            | Go to the File List view in the Search Mode     |
| `q`            | Close the list                                  |
| `Ctrl + c`     | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   |
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |


### Bookmark Operations

| Key | Action                                              |
|:---:| --------------------------------------------------- |
| `a` | Add a new bookmark                                  |
| `d` | Delete selected bookmark                            |
| `=` | Change selected bookmark name                       |


### Moving

| Key        | Action                                                      |
|:----------:| ----------------------------------------------------------- |
| `j`        | Move selection bar down                                     |
| `k`        | Move selection bar up                                       |
| `J`        | Move selection bar to the bottom of the list                |
| `K`        | Move selection bar to the top of the list                   |
| `p`        | Move selection bar to the previously opened bookmark        |
| `P`        | Move selection bar to the previously opened tab and open it |
| `n`        | Move selection bar to the next opened bookmark              |
| `Ctrl + f` | Move selection bar one screen down                          |
| `Ctrl + b` | Move selection bar one screen up                            |
| `Ctrl + d` | Move selection bar a half screen down                       |
| `Ctrl + u` | Move selection bar a half screen up                         |


# Common Modes

Common modes are available in more than one list.


## Search Mode

| Unicode | ASCII  |
|:-------:|:------:|
| `›_‹`   | `[_]`  |

This mode is composed of two states or two phases. The first one is the
_entering phase_. Technically, this is the extact Search mode. In the entering
phase the following keys are available:

| Key              | Action                                                  |
|:----------------:| ------------------------------------------------------- |
| `Return`         | Close the entering phase and accept the entered content |
| `Backspace`      | Remove the previouse entered character                  |
| `/`              | Toggle the entering phase                               |
| `a..z A..Z 0..9` | The charactes allowed in the entering phase             |

Besides the entering phase there is also a second state possible. That is the
state of having a search query entered. The successfully entered query behaves
just like a kind of sorting. In fact, it is just a kind of sorting and filtering
function. So it doesn't impact on lists except it narrows the contents.

It's worth to mention that in that mode the `Backspace` key removes the search
query entirely.


## Nop Mode

Nop (Non-Operational) mode happens when i.e. there are no items to show (empty
list), or you are trying to type a Search query, and there are no results at
all. That means the Nop can happen during the _entering phase_ of the Search
Mode or in some other cases. Those cases can occur, for example, when you
have only unlisted buffers available in the tab (like e.g. help window and
some preview ones). As you will see, in such circumstances - outside the
entering phase - there is a great number of resque options available.


### Nop (Search entering phase)

| Key         | Action                                                  |
|:-----------:| ------------------------------------------------------- |
| `Backspace` | Remove the previouse entered character or close         |
| `Ctrl + c`  | Close the list                                  |
| `Esc`       | Close the list - depending on settings                  |


### Nop (outside the entering phase)

| Key            | Action                                               |
|:--------------:| ---------------------------------------------------- |
| `Backspace`    | Delete the search query                              |
| `q`            | Close the list                                       |
| `Ctrl + c`     | Close the list                                  |
| `Esc`          | Close the list - depending on settings               |
| `Ctrl + Space` | Close the list - depending on settings               |
| `Q`            | Quit Vim with a prompt if unsaved changes found      |
| `a`            | Toggle between Single and All modes                  |
| `o`            | Enter the File List (Open List)                      |
| `l`            | Toggle the Tab List view                             |
| `w`            | Toggle the Workspace List view                       |
| `Ctrl + p`     | Bring back the previous searched text                |
| `Ctrl + n`     | Bring the next searched text                         |


# Configuration

**Vim-CtrlSpace** has following configuration options. Almost all of them are
declared as global variables and should be defined in your `.vimrc` file in the
similar form:

    let g:ctrlspace_foo_bar = 123


## `g:ctrlspace_height`

Sets the minimal height of the plugin window. 

Default value: `1`


## `g:ctrlspace_max_height`

Sets the maximum height of the plugin window. If `0` provided it uses 1/3 of the
screen height. 

Default value: `0`


## `g:ctrlspace_set_default_mapping`

Turns on the default mapping. If you turn this option off (`0`) you will have to
provide your own mapping to the `CtrlSpace` yourself. 

Default value: `1`


## `g:ctrlspace_default_mapping_key`

By default, **Vim-CtrlSpace** maps itself to `Ctrl + Space`. If you want to
change the default mapping provide it here as a string with valid Vim keystroke
notation. 

Default value: `"<C-Space>"`


## `g:ctrlspace_use_ruby_bindings`

If set to `1`, the plugin will try to use your compiled in Ruby bindings to
increase the speed of the plugin (e.g. while fuzzy search, since regex
operations are much faster in Ruby than in VimScript).

> To see if you have Ruby bindings enabled you can use the command `:version`
> and see if there is a `+ruby` entry. Or just try the following one: `:ruby
> puts RUBY_VERSION` - you should get the Ruby version or just an error.

Default value: `1`


## `g:ctrlspace_glob_command`

If not empty, the provided command will be used to list all files instead of Vim
`globpath()` function. For example, if you have Ag installed that could be:

```VimL
if executable("ag") 
  let g:ctrlspace_glob_command = 'ag . -l --nocolor -g ""'
endif
```

Default value: `""`

## `g:ctrlspace_use_tabline`

Should **Vim-CtrlSpace** change your default tabline to its own? 

Default value: `1`


## `g:ctrlspace_use_mouse_and_arrows_in_term`

Should the plugin use mouse, arrows and `Home`, `End`, `PageUp`, `PageDown`
keys in a terminal Vim. Disables the `Esc` key if turned on. 

Default value: `0`


## `g:ctrlspace_save_workspace_on_exit`

Saves the active workspace (if present) on Vim quit. If this option is set, the
Vim quit (`Q`) action from the plugin modes does not check for workspace
changes. 

Default value: `0`


## `g:ctrlspace_load_last_workspace_on_start`

Loads the last active workspace (if found) on Vim startup. 

Default value: `0`


## `g:ctrlspace_cache_dir`

A directory for the **Vim-CtrlSpace** cache file (`.cs_cache`). By default your
`$HOME` directory will be used. 


## `g:ctrlspace_project_root_markers`

An array of directory names which presence indicates the project root. If no
marker is found, you will be asked to confirm the project root basing on the
current working directory. Make this array empty to disable this functionality.

These markes will be also used as a storage for `cs_workspaces` (workspaces of
the current project) and `cs_files` (cached files of the current project).

Default value: `[".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"]`


## `g:ctrlspace_unicode_font`

Set to `1` if you want to use Unicode symbols, or `0` otherwise. 

Default value: `1`


## `g:ctrlspace_symbols`

Enables you to provide your own symbols. It's useful if for example your font
doesn't contain enough symbols or the glyphs are poorly rendered. 

Default value:

```VimL
if g:ctrlspace_unicode_font
  let g:ctrlspace_symbols = {
        \ "cs"      : "⌗",
        \ "tab"     : "⊙",
        \ "all"     : "∷",
        \ "open"    : "◎",
        \ "tabs"    : "○",
        \ "c_tab"   : "●",
        \ "load"    : "⋮ → ∙",
        \ "save"    : "∙ → ⋮",
        \ "prv"     : "⌕",
        \ "s_left"  : "›",
        \ "s_right" : "‹",
        \ "bm"      : "♡"
        \ }
else
  let g:ctrlspace_symbols = {
        \ "cs"      : "#",
        \ "tab"     : "TAB",
        \ "all"     : "ALL",
        \ "open"    : "OPEN",
        \ "tabs"    : "-",
        \ "c_tab"   : "+",
        \ "load"    : "LOAD",
        \ "save"    : "SAVE",
        \ "prv"     : "*",
        \ "s_left"  : "[",
        \ "s_right" : "]",
        \ "bm"      : "BM"
        \ }
endif
```

## `g:ctrlspace_ignored_files`

The expression used to ignore some files during file collecting. It is used in
addition to the `wildignore` option in Vim (see `:help wildignore`). Notice, the
`wildignore` option won't work with a custom glob command
([`g:ctrlspace_glob_command`](#gctrlspace_glob_command)). And the glob command
may ignore some files itself (for example: `Ag` command obeys `.gitignore`
file).

Default value: `'\v(tmp|temp)[\/]'`


## `g:ctrlspace_statusline_function`

Allows to provide custom statusline function used by the CtrlSpace window. 

Default value: `"ctrlspace#statusline()"`


## `g:ctrlspace_max_files`

This value specifies how many files will be shown in the plugin window. By
default the limit is set to `500`. Usually there is no reason to show more,
since browsing such big list is rather unconvenient. However, if you want to
disable this feature, set this variable to `0`. 

Default value: `500`


## `g:ctrlspace_max_search_results`

Limits the search results. Usually, and especially in large projects, showing
all results is meaningless. It leads to higher time/memory consumption whereas
the far distant results are rather less relevant. By default the results list is
limited to `200` items. You can also limit results to the max plugin window
height by providing value `-1` or you can disable this feature completely by
setting it to `0`. 

Default value: `200`


## `g:ctrlspace_search_timing`

Allows you to adjust search smoothness. Contains an array of two integer values.
If the size of the list is lower than the first value, that value will be used
for search delay. Similarly, if the size of the list is greater than the second
value, then that value will be used for search delay. In all other cases the
delay will equal the list size. That way the plugin ensures smooth search
input behavior. 

Default value: `[50, 500]`


## `g:ctrlspace_search_resonators`

Allows you to set characters which will be used to increase search accurancy. If
such _resonator_ is found next to the searched sequence, it increases the search
score. For example, consider following files: `zzzabczzz.txt`, `zzzzzzabc.txt`,
and `zzzzz.abc.txt`. If you search for `abc` with default resonators, you will
get the last file as the top relevant item, because there are two resonators
(dots) next to the searched sequence. Next you would get the middle one (one dot
around `abc`), and then the first one (no resonators at all). You can disable
this behavior completely by providing an empty array. 

Default value: `['.', '/', '\', '_', '-']`


## Colors

The plugin allows you to define its colors entirely. By default it comes with
following highlight links:

```VimL
hi def link CtrlSpaceNormal   Normal
hi def link CtrlSpaceSelected Visual
hi def link CtrlSpaceSearch   IncSearch
hi def link CtrlSpaceStatus   StatusLine
```

You are supposed to tweak its colors (especially CtrlSpaceSearch) on your own,
(in the `.vimrc` file). This can be done as shown below:

```VimL
hi CtrlSpaceSelected term=reverse ctermfg=187   guifg=#d7d7af ctermbg=23    guibg=#005f5f cterm=bold gui=bold
hi CtrlSpaceNormal   term=NONE    ctermfg=244   guifg=#808080 ctermbg=232   guibg=#080808 cterm=NONE gui=NONE
hi CtrlSpaceSearch   ctermfg=220  guifg=#ffd700 ctermbg=NONE  guibg=NONE    cterm=bold    gui=bold
hi CtrlSpaceStatus   ctermfg=230  guifg=#ffffd7 ctermbg=234   guibg=#1c1c1c cterm=NONE    gui=NONE
```

The colors defined above can be seen in the demo movie. They fit well the
[Seoul256](https://github.com/junegunn/seoul256.vim) color scheme. If you use
a console Vim [that
chart](http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html) might be
helpful.


# API 


## Commands

At the moment Vim-CtrlSpace provides you 8 commands: `:CtrlSpace`,
`:CtrlSpaceGoNext`, `:CtrlSpaceGoPrevious`, `:CtrlSpaceTabLabel`,
`:CtrlSpaceClearTabLabel`, `:CtrlSpaceSaveWorkspace`, `:CtrlSpaceLoadWorkspace`,
`:CtrlSpaceNewWorkspace`.


### `:CtrlSpace [keys]`

Shows the plugin window. It is meant to be used in custom mappings or more
sophisticated plugin integration. You can pass keys that will be "pressed" in the
plugin window.


### `:CtrlSpaceGoNext`

Opens the next buffer from the current Single Mode buffer list (without opening
the plugin window).


### `:CtrlSpaceGoPrevious`

Opens the previous buffer from the current Single Mode buffer list (without opening
the plugin window).


### `:CtrlSpaceTabLabel`

Allows you to define a custom mapping (outside **Vim-CtrlSpace**) to change (or
add/remove) a custom tab name.


### `:CtrlSpaceClearTabLabel`

Removes a custom tab label.


### `:CtrlSpaceSaveWorkspace [my workspace]`

Saves the workspace with the given name. If no name is given then it saves the
active workspace (if present).


### `:CtrlSpaceLoadWorkspace [my workspace]`

Loads the workspace with the given name. It has also a banged version
(`:CtrlSpaceLoadWorkspace! my workspace`) which performs appending instead of
loading. If no name is give then it loads (or appends) the active workspace (if
present).


### `:CtrlSpaceNewWorkspace`

Closes all opened buffers and eventually opened workspace and leaves only one
tab and one buffer, as in a fresh Vim instance. This is useful if you want to
start creating a workspace from the very beginning.


## Functions

**Vim-CtrlSpace** provides you a couple of functions defined in the common
`ctrlspace` namespace. They can be used for custom status line integration,
tabline integration, or just for more advanced interactions with other plugins.


### `ctrlspace#bufferlist(tabnr)`

Returns a dictionary of buffer number and name pairs for given tab. This is the
content of the internal buffer list belonging to the specified tab.


### `ctrlspace#statusline_mode_segment(...)`

Returns the info about the mode of the plugin. It can take an optional
separator. It can be useful for a custom status line integration (i.e. in
plugins like [LightLine](https://github.com/itchyny/lightline.vim))


### `ctrlspace#statusline_tab_segment(...)`

Returns the info about the current tab (tab number, label, etc.). It is useful
if you don't use the custom tabline string (or perhaps you have set
`showtabline` to `0` (see `:help showtabline` for more info)).


### `ctrlspace#statusline()`

Provides the custom statusline string.


### `ctrlspace#tabline()`

Provides the custom tabline string.


### `ctrlspace#guitablabel()`

Provides the custom label for GVim's tabs.


### `ctrlspace#tab_buffers_number(tabnr)`

Returns formatted number of buffers belonging to given tab. Formats the output
as small Unicode characters (upper indexes), or with help of a colon (depending
on Vim-CtrlSpace unicode settings). It is helper function useful if you provide
your custom tabline function implementation.


### `ctrlspace#tab_title(tabnr, bufnr, bufname)`

A helper function returning a consistent title for given tab. If the tab does
not have a custom title, then the title based on passed buffer number
and buffer name is returned instead.


### `ctrlspace#tab_modified(tabnr)`

Returns `1` if given tab contains a modified buffer, `0` otherwise.


# Authors and License

Copyright &copy; 2013-2014 [Szymon Wrozynski and
Contributors](https://github.com/szw/vim-ctrlspace/commits/master). Licensed
under [MIT
License](https://github.com/szw/vim-ctrlspace/blob/master/plugin/ctrlspace.vim#L5-L26)
conditions. **Vim-CtrlSpace** is based on Robert Lillack plugin [VIM
bufferlist](https://github.com/roblillack/vim-bufferlist) &copy; 2005 Robert
Lillack. Moreover some concepts and inspiration has been taken from
[Vim-Tabber](https://github.com/fweep/vim-tabber) by Jim Steward and
[Tabline](https://github.com/mkitt/tabline.vim) by Matthew Kitt.
