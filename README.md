<h1 align="center">
<img alt="Vim-CtrlSpace" 
src="https://raw.github.com/szw/vim-ctrlspace/master/gfx/logo.png" />
</h1>

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Overview](#overview)
  * [Demo](#demo)
  * [Changes in version 4.0](#changes-in-version-40)
* [The Story](#the-story)
  * [Origins](#origins)
  * [The Idea](#the-idea)
  * [Workflow Tips](#workflow-tips)
* [Installation and Initial Setup](#installation-and-initial-setup)
  * [Colors](#colors)
  * [Status Line](#status-line)
  * [Tabline](#tabline)
  * [Project Root](#project-root)
* [User Interface](#user-interface)
  * [Tab Management](#tab-management)
* [Lists](#lists)
  * [Buffer List](#buffer-list)
    * [Single Mode](#single-mode)
    * [All Mode](#all-mode)
    * [Preview Mode](#preview-mode)
  * [File List](#file-list)
  * [Tab List](#tab-list)
  * [Workspace List](#workspace-list)
* [Common Modes](#common-modes)
  * [Search Mode](#search-mode)
  * [Nop Mode](#nop-mode)
* [Configuration](#configuration)
  * [Colors](#colors)
* [API ](#api)
  * [Commands](#commands)
  * [Functions](#functions)
* [Authors and License](#authors-and-license)

## Overview

**Vim-CtrlSpace** is a great plugin meant to organize your Vim screen space and
your workspace effectively. It helps you to increase usage of core Vim features 
like multiple buffers, tabs, and windows. It also introduces some new ideas,
i.e. workspaces or named tabs containing separate buffer lists. 

Actually, key plugin features are lists. The whole plugin looks like a small
window opened on demand, capable of displaying various lists: buffer list, file
list, tab list, or workspace list. Sounds simple, but around that there are some
additional details making this simple concept a unique approach. 

<p align="center">
<img alt="Vim-CtrlSpace" 
src="https://raw.github.com/szw/vim-ctrlspace/master/gfx/plugin_window.png" /><br />
<em>Sample Plugin Window</em>
</p>

First, the buffer list is limited to buffers related to the current tab. That's
it, the plugin by default groups buffers by tabs they are used in. In that way
you get separate sets of buffers per each tab. And that's really useful. Of
course, the _all buffers_ mode is still available. 

Another cool feature is that, you can name your tabs and you can save the whole
set of tabs and buffers as a workspace in your project directory and reopen it
later. And naturally, you can list and open any files available in your project,
having your fuzzy search at hand. It's also worth to mention, the plugin tries
to employ Ruby when possible to speed up things. Oh, and you can also perform
a lot of operations on list contents. You can move, copy, rename, delete
buffers, tabs, files, workspaces (sic, nothing stops you to have plenty
workspaces per project). Some of those operations seems trivial (like tab
moving), but some of them are not (buffer renaming). The plugin makes all of
them pretty easy hiding the guts.

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

### Demo

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
        hi CtrlSpaceSearch    ctermfg=220  ctermbg=NONE cterm=bold
        hi CtrlSpaceStatus   ctermfg=230  ctermbg=234  cterm=NONE

- music licensed under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/)
  1. Kate Orange - [Oops](http://www.jamendo.com/pl/track/474843/oops)
  2. Alex F - [Rain](http://www.jamendo.com/pl/track/975564/rain)

### Changes in version 4.0

* Uses alphabetical ordering only (no more order change option)
* Displays unnamed buffers only if changed or currently displayed
* Simplifies status line
* Allows custom statusline functions
* Changes `A` binding to `o` (as of _Open_). 
* Introduces File List (aka _Open List_) instead of _Append a File_ mode
* Changes `\` binding to `O` (but limits its usage)
* Removes cyclic list option - all lists are cyclic from now
* Removes available keys info in status bar
* Provides new symbols and a new Tab List dynamic indicator
* Change CtrlSpace logotype and symbol from `▢` to `⌗` - _VIEWDATA SQUARE
  (U+2317)_ - to better visualize _controlled space_, where all things have
  their own place ;)
* Allows to rename unsaved/unnamed buffers
* Allows to copy unsave/unnamed buffers
* Allows to move/copy buffers between tabs
* Provides more API functions for custom tablines
* Adds `g` and `G` for quick going to next/previous tab with selected file/buffer
* Adds `:CtrlSpaceGoNext` and `:CtrlSpaceGoPrevious` commands for quick jumping
  to next/previous buffers without opening the plugin window

## The Story

### Origins

There are many ways of working with Vim. It's no so straight forward like in
other editors. People often find their own methods of working with Vim and
increasing their productivity. However, some settings and scenarios seem to be
preffered rather than others. And that means also some common issues.

The main attitude is to combine buffers, split windows, and tabs effectively. 
Vim, unlike in other editors, tabs are not tabs really. They are just containers
for split windows, sometimes referred as *viewports*. The tab list - considered
as a list of open files - buffers, is called a *buffer list*. Usually, it's
not immediately visible but you can issue a command `:ls` to see it yourself.

Of course, there are many plugins allowing you to see, change, and manage
buffers. In fact, **Vim-CtrlSpace** has been started as a set of improvements of
a such existing plugin. It was named [VIM
bufferlist](https://github.com/roblillack/vim-bufferlist) by Rob Lillack. That
was a neat and tiny plugin (270 LOC), but a bit abandoned. Now, about a year
later, **Vim-CtrlSpace** has over 3K LOC and still uses some code of that
Rob's plugin :). 

Characteristic Vim usage, exhibited by many Vim power users, is to treat tabs as
units of work on different topics. If, for example, I work with a project of
a web application with User management, I can have a tab containing a User model
and test files, perhaps a User controller file, and some view files. If it would
be possible (actually in **Vim-CtrlSpace** it is!) I could name that tab
_Users_. Then, if I move to, let's say Posts I can have similar set of open
files in the next tab. That way I can go back and forward between these two
separate application parts. In the third tab I could have e.g. config files,
etc.

This approach works indeed very well. In fact, you can never touch the real
buffer list down there. You can even disable so called *hidden* buffers to make
sure you manage only what you see in tabs, which seems to be a default setting
in Vim nowadays, perphaps because it is (or I believe it **was** thanks to
**Vim-CtrlSpace** ;)) a bit tricky to manage raw buffers.

Anyway, I've been working that way for a long time. However, there are some
subtle issues behind the scene. The first one is the screen size. With this
approach you are limited to the screen size. At some point the code in split
windows doesn't fit those windows at all, even if you have a full HD screen with
Vim maximized. The second issue is a lot of distraction. Sometimes you might
want just to focus on a one particular file. To address that I have developed
a tool called [Vim-Maximizer](https://github.com/szw/vim-maximizer).
*Vim-Maximizer* allows you to temporarily maximize one split window, just by
pressing `F3` (by default). This can be seen in the demo movie above. That was
cool, but still I needed something better, especially since I started working on
13-inch laptop...

And that was the moment when **Vim-CtrlSpace** came to play. 

### The Idea

First, I wanted a cool buffer list to address problems with screen size and
allow me to use Vim like in a distraction free mode. Something neat and easy
which let me to hide unnecessary windows and just shift buffers when needed.
MinibufExplorer and friends have some issues with unnamed buffers. Also, I have
troubles when I have too many buffers open. The list gets longer and longer.
A tool like CtrlP was helpful to some point (usually when I was looking for
a concrete buffer with a name I remembered), but it didn't list all available
buffers. 

I started playing with Rob Lillack's *VIM bufferlist* and finally I've created
a solution. I've introduced a concept of many buffer lists tightly coupled with
tabs. That means each tab holds its own buffer list. Once a buffer is shown in
the tab, the tab is storing it in its own buffer list. No matter in which
window. It's just like having many windows related to the same concern, but
without the need of split windows at all! Then you can forget the buffer (remove
it from tab's buffer list), or perform many other actions. Of course, it's
possible to access the main buffer list (the list of all open buffers) - in that
way, you can easily add new friends to the current tab. It's also perfectly
valid to have a buffer shared among many tabs at the same time (it will be
listed on many lists). Similarly, you can have a buffer that is not connected to
any particular tab. It's just a plain old hidden buffer (not displayed at the
moment), listed only in the _all buffers_ list.

That was a breaking change. Next things are just consequences of that little
invention. I've added a lot of buffer operations (opening, closing, renaming,
and more), the ability of opening files (together with file operations too),
fuzzy search through buffer lists and files, separate and wise jump lists,
search history, easy tab access (with full tab management and custom tab names),
and last but not least, workspace management (saving to disk and loading). That
means you can have plenty of named workspaces per project - very useful if you
for example utilize [Github workflow](https://guides.github.com/overviews/flow/). 
You can have e.g. a one workspace per feature branch.

All those improvements let me to start using **Vim-CtrlSpace** instead of
*CtrlP* or even *NERDTree*. But, of course, nothing stops you to combine all
those plugins together, especially if you used to work with them. There are no
inteferences, just some functionality doubling.

### Workflow Tips

Chances are Vim-CtrlSpace would become your basic Vim plugin that help you
open and manage files. Here, I'd like to share with you some tips I found
useful during daily usage with the plugin.

As Vim is my main programming editor, usually I open one instance per project.
Also, I used to create one workspace per feature branch. In some projects,
I created also a workspace with some common tabs (like _configuration_, _test
setup_, _migrations_) named _Config_. Then I was able to append that _Config_ to
other workspaces (`a`). However it is not necessary, because you can save
a new workspace basing on the previous one (it works like the classic _Save As_
feature).

When I work with files I usually create a lot of tabs, each containg at most
a few buffers. I would suggest verbose and meaningful names for that like
_refactoring after xxx_, _rebasing with master_, etc.

If I start to work on something new and not related with the current tab,
usually I create a new handy tab with buffers related to the new topic. If
I had started to opening files those ones can be easily moved to the new more
specyfic tab (`{`, `}`). Sometimes, I even copy the entire tab (`l`, `y` or just
`Y`), rename it (`=`), and remove superfluous files in both: source and target
ones (`c`).

If, besides the normal navigation through tabs and buffers (`l`, `j`, `j`,
`Return`), I need to jump to a particular file in a particular tab, I usually
press `O` to open the File List in Search Mode (or `a` to see all files). Then
I type the filename letters, accept the text, select the file, and press `g` on
that file. That takes me to the right tab. Next I can press `l` and `p` to jump
back to the previous tab. Of course, if I need to jump more often between two
files belonging to two seperate tabs, I would either open one file inside one of
those tabs, or create a handy new one containing just those two files. 

It's very easy to create such _helper_ tabs (`l`, `t`, or `T`). It's also easy
to copy (`<`, `>`) or move (`{`, `}`) buffers between them so I use them very
often. Inside the helper tab I can switch between files easily with `p`, `n`,
and `P`. Of course, in case of strict simultaneous working on a couple of files,
I can open them as split windows (`s` or `v`). After the task is done the helper
tab can be closed (`l`, `c`, or just `C`). 

## Installation and Initial Setup

The plugin installation is really simple. You can use Vundle or Pathogen, or
just clone the repository to your `.vim` directory. In case of Vundle, add:

    Plugin 'szw/vim-ctrlspace' 

to your `.vimrc`.

To improve your overall experience please enable the `hidden` option too:

    set hidden

If you want to increase plugin speed (e.g. fuzzy search), make sure you have 
decent Ruby bindings enabled in (compiled into) your Vim. The plugin will try 
to use your Ruby by default.

### Colors

You should also improve default plugin colors to work well with your
colorscheme. For example, I used to work in the terminal Vim with slightly
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

Notice, it's worth to spent some time to adjust settings to someting
eye-pleasant, because chances are, you will use (a thus see) the plugin a lot ;). 

If you use a popular colorscheme and you would like to share your
settings, I'd love to add them here! Please post a pull request, an issue or
just an [email](mailto:szymon@wrozynski.com).

### Status Line

**Vim-CtrlSpace** requires a status bar. If you are using a plugin customizing
the status bar this might be a bit tricky. For example
[vim-airline](https://github.com/bling/vim-airline) plugin might require you to
set: `let g:airline_exclude_preview = 1` option and
[LightLine](https://github.com/itchyny/lightline.vim) will require to use custom
status line segments, provided by **Vim-CtrlSpace** API.

### Tabline

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
`.vimrc` and check plugin Tab List instead (press `l` in the plugin window).

### Project Root

The plugin requires a project root to work properly. If you open the plugin
window for the first time it will try to find out the possible root directory.
First, it starts in the Vim's current working directory and check if there are
so called _root markers_. The root markers are characteristic files or
directories that are available in an exemplary project root directory, like e.g.
`.git` or `.hg` directories. You can define them yourself in the
`g:ctrlspace_project_root_markers` variable. If no markers were found the plugin
will check if perhaps this directory is a known root. The known roots are those
ones you provided (accepted) yourself when no markers were found. If the current
directory cannot be proven as a project root, the algorithm will repeat the
whole procedure in the parent one. 

After checking all predecessors it will ask you to provide the root folder
explicitly. After your acceptance that root folder will be stored pemanently in
the `.cs_cache` file as serve as a known root later.

#### Autochdir Issues

It's worth to mention that **Vim-CtrlSpace** makes assumptions about the current
working directory and it does not work well when `autochdir` option is set. The
possible workaround is to use the following snippet instead (thnx dxc!):

    autocmd BufEnter, BufNewFile * silent! lcd %:p:h

If it doesn't work for you, or you need `autochdir` decisively please let me
know (perhaps via Github issues), and I'll investigate that issue thoroughly.

## User Interface

**Vim-CtrlSpace** contains 4 different lists: _Buffer List_, _File List_,  _Tab
List_, and _Workspace List_. Some of those have additional modes. However, in
a modal editor like Vim this should not fear you ;). 

You can jump between lists easily by pressing one of the following keys:

| Key      | Action                                                 |
|:--------:| ------------------------------------------------------ |
| `o`      | Jump to File List (aka Open List)                      |
| `O`      | Jump to File List (aka Open List) in Search Mode       | 
| `l`      | Jump to Tab List                                       |
| `w`      | Jump to Workspace List                                 |

Since the _Buffer List_ is the default one, in order to jump to it press
one of those keys again (except `O`) or just hit `Backspace`.

User interface of the plugin is a list window. Its status line contains 
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

Items listed in the plugin window can have additional indicators (following the
item text):

| Unicode | ASCII | Indicator                |
|:-------:|:-----:| ------------------------ |
| `+`     | `+`   | Item modified            |
| `★`     | `*`   | Item visible (or active) |

### Tab Management

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

## Lists

### Buffer List

This is the basic list of the plugin. Depending of its mode it can collect
buffers from the current tab or buffers from all tabs. 

Here is a simplified diagram of key groups used in **Vim-CtrlSpace** Buffer
List.

<p align="center">
<img alt="Key Groups" 
src="https://raw.github.com/szw/vim-ctrlspace/master/gfx/cs_keys.png" />
</p>

*This file is licensed under GNU FDL license. It is derived from
[Qwerty.svg](http://commons.wikimedia.org/wiki/File:Qwerty.svg) file by [Oona
Räisänen](http://en.wikipedia.org/wiki/User:Mysid) &copy; 2005. The source of
the generated graphics you can find
[here](https://raw.github.com/szw/vim-ctrlspace/master/gfx/cs_keys.svg).*

#### Single Mode

| Unicode | ASCII |
|:-------:|:-----:|
| `⊙`     | `TAB` |

The first mode of Buffer List is the Single one. In that mode, the plugin
shows you only buffers related to the current tab. Here's the full listing of
all available keys:

##### Opening

| Key      | Action                                               |
|:--------:| ---------------------------------------------------- |
| `Return` | Open a selected buffer                               |
| `Space`  | Open a selected buffer and stay in the plugin window |
| `Tab`    | Enter the Preview Mode for selected buffer           |
| `v`      | Open a selected buffer in a new vertical split       |
| `s`      | Open a selected buffer in a new horizontal split     |
| `t`      | Open a selected buffer in a new tab                  |

##### Searching & Sorting

| Key        | Action                                              |
|:----------:| --------------------------------------------------- |
| `/`        | Enter the Search Mode                               |
| `Ctrl + p` | Bring back the previous searched text               |
| `Ctrl + n` | Bring the next searched text                        |

##### Tabs Operations

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

##### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back                                         |
| `q`            | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   | 
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |

##### Moving

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


##### Closing

| Key  | Action                                                              |
|:----:| ------------------------------------------------------------------- |
| `d`  | Delete the selected buffer (close it)                               |
| `D`  | Close all empty noname buffers                                      |
| `f`  | Forget the current buffer (make it a unrelated to the current tab)  |
| `F`  | Delete (close) all forgotten buffers (unrelated to any tab)         |
| `c`  | Try to close selected buffer (delete if possible, forget otherwise) |
| `C`  | Close the current tab, then perform `F`, and then `D`               |

##### Disk Operations

| Key  | Action                                                            |
|:----:| ----------------------------------------------------------------- |
| `e`  | Edit a sibling of the selected buffer                             |
| `E`  | Explore a directory of the selected buffer                        |
| `R`  | Remove the selected buffer (file) entirely (from the disk too)    |
| `m`  | Move or rename the selected buffer (together with its file)       |
| `y`  | Copy selected file                                                |

##### Mode and List Changing

| Key  | Action                                                             |
|:----:| ------------------------------------------------------------------ |
| `a`  | Toggle between Single and All modes                                |
| `o`  | Toggle the File List (Open List)                                   |
| `O`  | Enter the Search Mode in the File List                             |
| `l`  | Toggle the Tab List view                                           |
| `w`  | Toggle the Workspace List view                                     |

##### Workspace shortcuts

| Key  | Action                                                              |
|:----:| ------------------------------------------------------------------- |
| `S`  | Save the workspace immediately (or creates a new one if none)       |
| `L`  | Load the last active workspace (if present)                         |

#### All Mode

| Unicode | ASCII |
|:-------:|:-----:|
| `∷`     | `ALL` |

This mode is almost identical to the Single Mode, except it shows you all
available buffers (from all tabs and unrelated ones too). Some of keys presented
in the Single Mode are not available here. The missing ones are `f`, `c`,
`{`, `}`, `<`, `>` - as they are connected with current tab.

#### Preview Mode

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


### File List

| Unicode | ASCII  |
|:-------:|:------:|
| `◎`     | `OPEN` |

This list shows you all files in the project and allows you to open a new file
(as a buffer) in the current tab. Notice, only the project root directory
is considered here in order to prevent you from accidental loading root of i.e.
your home directory, as it would be really time consuming (file scanning) and
rather pointless.

For the first time the file list is populated with data. Sometimes, for a very
large project this could be quite time consuming (I've noticed a lag for
a project with over 2200 files). Also, it depends on files stored for example in
the SCM directory. In the end, the content of the project root directory is
cached and available immediately. All time you can force plugin to refresh the
list with the `r` key.

#### Opening

| Key       | Action                                               |
|:---------:| ---------------------------------------------------- |
| `Return`  | Open a selected file                                 |
| `Space`   | Open a selected file but stays in the plugin window  |
| `v`       | Open a selected file in a new vertical split         |
| `s`       | Open a selected file in a new horizontal split       |
| `t`       | Open a selected file in a new tab                    |

#### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back to Buffer List                          |
| `o`            | Go back to Buffer List                          |
| `q`            | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   |
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |

#### Tabs Operations

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


#### Searching

| Key        | Action                                              |
|:----------:| --------------------------------------------------- |
| `/`        | Enter the Search Mode                               |
| `O`        | Enter the Search Mode                               |
| `Ctrl + p` | Bring back the previous searched text               |
| `Ctrl + n` | Bring the next searched text                        |

#### Moving

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

#### Closing

| Key | Action                                                     |
|:---:| ---------------------------------------------------------- |
| `C` | Close the current tab (with forgotten buffers and nonames) |

#### Disk Operations

| Key | Action                                       |
|:---:| -------------------------------------------- |
| `e` | Edit a sibling of the selected buffer        |
| `E` | Explore a directory of the selected buffer   |
| `r` | Refresh the file list (force reloading)      |
| `R` | Remove the selected file entirely            |
| `m` | Move or rename the selected file             |
| `y` | Copy the selected file                       |


#### List Changing

| Key | Action                                       |
|:---:| -------------------------------------------- |
| `l` | Toggle the Tab List view                     |
| `w` | Toggle the Workspace List view               |

### Tab List

| Unicode | ASCII  |
|:-------:|:------:|
| `○●○`   | `TABS` |

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
entirely and stick to that list only via Vim's `showtabline` option.

#### Opening and closing

| Key      | Action                                                     |
|:--------:| ---------------------------------------------------------- |
| `Return` | Open a selected tab and enter the Buffer List view         |
| `Tab`    | Open a selected tab and close the plugin window            |
| `Space`  | Open a selected tab but stay in the Tab List view          |
| `0..9`   | Jump to the n-th tab (0 is for the 10th one)               |
| `c`      | Close the selected tab, then forgotten buffers and nonames |

#### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back                                         |
| `l`            | Go back                                         |
| `w`            | Go to the Workspace List view                   |
| `o`            | Go to the File List view                        |
| `O`            | Go to the File List view in the Search Mode     |
| `q`            | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   |
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |

#### Tabs Operations

| Key | Action                                              |
|:---:| --------------------------------------------------- |
| `-` | Move the current tab backward (decrease its number) |
| `+` | Move the selected tab forward (increase its number) |
| `=` | Change the selected tab name                        |
| `_` | Remove the selected tab name                        |
| `[` | Go to the previous tab                              |
| `]` | Go to the next tab                                  |
| `t` | Create a new tab nexto to the current one           |
| `y` | Make a copy of the current tab                      |

#### Moving

| Key        | Action                                                        |
|:----------:| ------------------------------------------------------------- |
| `j`        | Move the selection bar down                                   |
| `k`        | Move the selection bar up                                     |
| `J`        | Move the selection bar to the bottom of the list              |
| `K`        | Move the selection bar to the top of the list                 |
| `p`        | Move the selection bar to the previous opened tab             |
| `P`        | Move the selection bar to the previous opened tab and open it |
| `n`        | Move the selection bar to the next opened tab                 |
| `Ctrl + f` | Move the selection bar one screen down                        |
| `Ctrl + b` | Move the selection bar one screen up                          |
| `Ctrl + d` | Move the selection bar a half screen down                     |
| `Ctrl + u` | Move the selection bar a half screen up                       |

### Workspace List

| Unicode | ASCII  | Mode      |
|:-------:|:------:| --------- |
| `⋮ → ∙` | `LOAD` | Load Mode |
| `∙ → ⋮` | `SAVE` | Save mode |

The plugin allows you to save and load so called _workspaces_. A workspace is
a set of opened windows, tabs, their names, and buffers. In fact, the word
_workspace_ can be considered as a synonym of a _session_ in **Vim-CtrlSpace**.

The ability of having so many _sessions_ available at hand creates a lot of
interesting use cases! For example, you can have a workspace for each task or
feature you are working on. It's very easy to switch from one workspace to
another, thus this could be helpful with reviewing completed tasks and
continuing work on an item after some period of time. Moreover, you can have
special workspaces that are prepared to be appended to others. Consider, e.g.
a _Config_ workspace. Imagine, you have a separate workspace with the only one
tab named _Config_ and some config files opened there. You can easily append
that workspace to you current or next ones, depending on your needs. That way
you are able to group the common and repetative sets of files in just one place
and reuse that group in many contexts.

In the Workspace List **Vim-CtrlSpace** shows you available workspaces. 
By default this list is displayed in the Load Mode. The second
available mode is the Save one.

Workspaces are saved in a file inside the project directory. Its name and path
is determined by proper plugin configuration options
(`g:ctrlspace_workspace_file`). If there are 2 or more split windows in a tab,
they will be recreated as horizontal or vertical splits while loading (depending
on `g:ctrlspace_use_horizontal_splits` settings).

It's also possible to automatically load the last active workspace on Vim
startup and save it active workspace on Vim exit. See
`g:ctrlspace_load_last_workspace_on_start` and
`g:ctrlspace_save_workspace_on_exit` for more details.

#### Accepting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Return`       | Load (or save) the selected workspace           |

#### Exiting

| Key            | Action                                          |
|:--------------:| ----------------------------------------------- |
| `Backspace`    | Go back to the Buffer List                      |
| `w`            | Go to the Buffer List                           |
| `o`            | Go to the File List                             |
| `O`            | Go to the File List in the Search Mode          | 
| `l`            | Go to the Tab List                              |
| `q`            | Close the list                                  |
| `Esc`          | Close the list - depending on plugin settings   |
| `Ctrl + Space` | Close the list - depending on plugin settings   |
| `Q`            | Quit Vim with a prompt if unsaved changes found |

#### Workspace Operations

| Key  | Action                                          |
|:----:| ----------------------------------------------- |
| `a`  | Append a selected workspace to the current one  |
| `s`  | Toggle the mode from Load or Save (or backward) |
| `S`  | Save the workspace immediately                  |
| `L`  | Load the last active workspace (if present)     |
| `d`  | Delete the selected workspace                   |

#### Moving

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

## Common Modes

Common modes are available in more than one list.

### Search Mode

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

### Nop Mode

Nop (Non-Operational) mode happens when i.e. there are no items to show (empty
list), or you are trying to type a Search query, and there are no results at
all. That means the Nop can happen during the _entering phase_ of the Search
Mode or in some other cases. Those cases can occur, for example, when you
have only unlisted buffers available in the tab (like e.g. help window and
some preview ones). As you will see, in such circumstances - outside the
entering phase - there is a great number of resque options available.

#### Nop (Search entering phase)

| Key         | Action                                                  |
|:-----------:| ------------------------------------------------------- |
| `Backspace` | Remove the previouse entered character or close         |
| `Esc`       | Close the list - depending on settings                  |

#### Nop (outside the entering phase)

| Key            | Action                                               |
|:--------------:| ---------------------------------------------------- |
| `Backspace`    | Delete the search query                              |
| `q`            | Close the list                                       |
| `Esc`          | Close the list - depending on settings               |
| `Ctrl + Space` | Close the list - depending on settings               |
| `Q`            | Quit Vim with a prompt if unsaved changes found      |
| `a`            | Toggle between Single and All modes                  |
| `o`            | Enter the File List (Open List)                      |
| `l`            | Toggle the Tab List view                             |
| `w`            | Toggle the Workspace List view                       |
| `Ctrl + p`     | Bring back the previous searched text                |
| `Ctrl + n`     | Bring the next searched text                         |

## Configuration

**Vim-CtrlSpace** has following configuration options. Almost all of them are
declared as global variables and should be defined in your `.vimrc` file in the
similar form:

    let g:ctrlspace_foo_bar = 123

### `g:ctrlspace_height`

Sets the minimal height of the plugin window. Default value: `1`.

### `g:ctrlspace_max_height`

Sets the maximum height of the plugin window. If `0` provided it uses 1/3 of the
screen height. Default value: `0`.

### `g:ctrlspace_set_default_mapping`

Turns on the default mapping. If you turn this option off (`0`) you will have to
provide your own mapping to the `CtrlSpace` yourself. Default value: `1`.

### `g:ctrlspace_default_mapping_key`

By default, **Vim-CtrlSpace** maps itself to `Ctrl + Space`. If you want to
change the default mapping provide it here as a string with valid Vim keystroke
notation. Default value: `"<C-Space>"`.

### `g:ctrlspace_use_ruby_bindings`

If set to `1`, the plugin will try to use your compiled in Ruby bindings to
increase the speed of the plugin (e.g. while fuzzy search, since regex
operations are much faster in Ruby than in VimScript). Default value: `1`. 

> To see if you have Ruby bindings enabled you can use the command `:version`
> and see if there is a `+ruby` entry. Or just try the following one: `:ruby
> puts RUBY_VERSION` - you should get the Ruby version or just an error.

### `g:ctrlspace_use_tabline`

Should **Vim-CtrlSpace** change your default tabline to its own? Default value:
`1`.

### `g:ctrlspace_use_mouse_and_arrows`

Should the plugin use mouse, arrows and `Home`, `End`, `PageUp`, `PageDown`
keys. Disables the `Esc` key if turned on. Default value: `0`.

### `g:ctrlspace_use_horizontal_splits`

Determines whether the plugin use vertical (`0`) or horizontal (`1`) splits if
necessary while loading a workspace. Default value: `0`.

### `g:ctrlspace_workspace_file`

This entry provides an array of strings with default names of workspaces file.
If a name is preceded with a directory, and that directory is found in the
project root, that entry will be used. Otherwise that would be the last one. In
that way you can hide the workspaces file, for example, in the repository
directory. Default value: 

    [".git/cs_workspaces", ".svn/cs_workspaces", ".hg/cs_workspaces", 
    \ ".bzr/cs_workspaces", "CVS/cs_workspaces", ".cs_workspaces"]

### `g:ctrlspace_save_workspace_on_exit`

Saves the active workspace (if present) on Vim quit. If this option is set, the
Vim quit (`Q`) action from the plugin modes does not check for workspace
changes. Default value: `0`.

### `g:ctrlspace_load_last_workspace_on_start`

Loads the last active workspace (if found) on Vim startup. Default value: `0`.

### `g:ctrlspace_cache_dir`

A directory for the **Vim-CtrlSpace** cache file (`.cs_cache`). By default your
`$HOME` directory will be used. 

### `g:ctrlspace_project_root_markers`

An array of directory names which presence indicates the project root. If no
marker is found, you will be asked to confirm the project root basing on the
current working directory. Make this array empty to disable this functionality.
Default value: `[".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"]`.

### `g:ctrlspace_unicode_font`

Set to `1` if you want to use Unicode symbols, or `0` otherwise. Default value: `1`.

### `g:ctrlspace_symbols`

Enables you to provide your own symbols. It's useful if for example your font
doesn't contain enough symbols or the glyphs are poorly rendered. Default value:

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
            \ "s_right" : "‹"
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
            \ "s_right" : "]"
            \ }
    endif

Of course, you don't have to mind the `g:ctrlspace_unicode_font` settings
anymore. Just provide one array here.

### `g:ctrlspace_ignored_files`

The expression used to ignore some files during file collecting. It is used in
addition to the `wildignore` option in Vim (see `:help wildignore`). Default
value: `'\v(tmp|temp)[\/]'`

### `g:ctrlspace_statusline_function`

Allows to provide custom statusline function used by the CtrlSpace window. 
Default value: `"ctrlspace#statusline()"`

### `g:ctrlspace_search_timing`

Allows you to adjust search smoothness. Contains an array of two integer values.
If the size of the list is lower than the first value, that value will be used
for search delay. Similarly, if the size of the list is greater than the second
value, then that value will be used for search delay. In all other cases the
delay will equal the list size. That way the plugin ensures smooth search
input behavior. Default value: `[50, 500]`

### `g:ctrlspace_search_resonators`

Allows you to set characters which will be used to increase search accurancy. If
such _resonator_ is found next to the searched sequence, it increases the search
score. For example, consider following files: `zzzabczzz.txt`, `zzzzzzabc.txt`,
and `zzzzz.abc.txt`. If you search for `abc` with default resonators, you will
get the last file as the top relevant item, because there are two resonators
(dots) next to the searched sequence. Next you would get the middle one (one dot
around `abc`), and then the first one (no resonators at all). You can disable
this behavior completely by providing an empty array. Default value: `['.', '/',
'\', '_', '-']`

### Colors

The plugin allows you to define its colors entirely. By default it comes with
following highlight links:

```VimL
hi def link CtrlSpaceNormal Normal
hi def link CtrlSpaceSelected Visual
hi def link CtrlSpaceSearch IncSearch
hi def link CtrlSpaceStatus StatusLine
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

## API 

### Commands

At the moment **Vim-CtrlSpace** provides you 5 commands: `:CtrlSpace`,
`:CtrlSpaceTabLabel`, `:CtrlSpaceClearTabLabel`, `:CtrlSpaceSaveWorkspace`, and
`:CtrlSpaceLoadWorkspace`.

#### `:CtrlSpace`

Shows the plugin window. It is meant to be used in custom mappings or more
sophisticated plugin integration.

#### `:CtrlSpaceGoNext`

Opens the next buffer from the current Single Mode buffer list (without opening
the plugin window).

#### `:CtrlSpaceGoPrevious`

Opens the previous buffer from the current Single Mode buffer list (without opening
the plugin window).

#### `:CtrlSpaceTabLabel`

Allows you to define a custom mapping (outside **Vim-CtrlSpace**) to change (or
add/remove) a custom tab name.

#### `:CtrlSpaceClearTabLabel`

Removes a custom tab label.

#### `:CtrlSpaceSaveWorkspace [my workspace]`

Saves the workspace with the given name. If no name is given then it saves the
active workspace (if present).

#### `:CtrlSpaceLoadWorkspace [my workspace]`

Loads the workspace with the given name. It has also a banged version
(`:CtrlSpaceLoadWorkspace! my workspace`) which performs appending instead of
loading. If no name is give then it loads (or appends) the active workspace (if
present).

### Functions

**Vim-CtrlSpace** provides you a couple of functions defined in the common
`ctrlspace` namespace. They can be used for custom status line integration,
tabline integration, or just for more advanced interactions with other plugins.

#### `ctrlspace#bufferlist(tabnr)`

Returns a dictionary of buffer number and name pairs for given tab. This is the
content of the internal buffer list belonging to the specified tab.

#### `ctrlspace#statusline_mode_segment(...)`

Returns the info about the mode of the plugin. It can take an optional
separator. It can be useful for a custom status line integration (i.e. in
plugins like [LightLine](https://github.com/itchyny/lightline.vim))

#### `ctrlspace#statusline_tab_segment(...)`

Returns the info about the current tab (tab number, label, etc.). It is useful
if you don't use the custom tabline string (or perhaps you have set
`showtabline` to `0` (see `:help showtabline` for more info)).

#### `ctrlspace#statusline()`

Provides the custom statusline string.

#### `ctrlspace#tabline()`

Provides the custom tabline string.

#### `ctrlspace#guitablabel()`

Provides the custom label for GVim's tabs.

#### `ctrlspace#tab_buffers_number(tabnr)`

Returns formatted number of buffers belonging to given tab. Formats the output
as small Unicode characters (upper indexes), or with help of a colon (depending
on Vim-CtrlSpace unicode settings). It is helper function useful if you provide
your custom tabline function implementation.

#### `ctrlspace#tab_title(tabnr, bufnr, bufname)`

A helper function returning a consistent title for given tab. If the tab does
not have a custom title, then the title based on passed buffer number
and buffer name is returned instead.

#### `ctrlspace#tab_modified(tabnr)`

Returns `1` if given tab contains a modified buffer, `0` otherwise.

## Authors and License

Copyright &copy; 2013-2014 [Szymon Wrozynski and
Contributors](https://github.com/szw/vim-ctrlspace/commits/master). Licensed
under [MIT
License](https://github.com/szw/vim-ctrlspace/blob/master/plugin/ctrlspace.vim#L5-L26)
conditions. **Vim-CtrlSpace** is based on Robert Lillack plugin [VIM
bufferlist](https://github.com/roblillack/vim-bufferlist) &copy; 2005 Robert
Lillack. Moreover some concepts and inspiration has been taken from
[Vim-Tabber](https://github.com/fweep/vim-tabber) by Jim Steward and
[Tabline](https://github.com/mkitt/tabline.vim) by Matthew Kitt.
