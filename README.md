<div align="center">
<img alt="Vim-CtrlSpace" 
src="https://raw.github.com/szw/vim-ctrlspace/version_5/gfx/logo5.png" />
<br><br>
</div>

Welcome to **Vim-CtrlSpace**, a comprehensive solution for your Vim editor
providing:

* tabs / buffers / files management
* fast fuzzy searching **powered by Go**
* workspaces (sessions)
* bookmarks for your favorite projects

The plugin name follows the convention of naming fuzzy search plugins
after their default mappings (like _Command-T_ or _CtrlP_), hence the
plugin mapping is by default `Ctrl` + `Space`.

If you like the plugin please don't forget to leave a :star: for this
project! This will help me to estimate the plugin popularity and plan
further development :).

If you have already starred this repo, thank you! Thanks to you it's my
pet project now :). If you have a question, a feature request, or a new
idea, don't hesitate to post new issues or pull requests. Collaboration is
the most awesome thing in the open source community!


#### Version 5

Vim-CtrlSpace started over 2 years ago as a fork of [another
plugin](https://github.com/roblillack/vim-bufferlist) and the Version
**5** is the result of the experience gained during that period and
cooperation with the community.

Version 5 is the biggest upgrade in the plugin history. All plugin code
has been rewritten from scratch taking user feedback as a great resource
of ideas and challenges into account. Thanks to users the plugin has
configurable key mappings and allows you to handle projects with **100
000** files!

In case you're curious, Vim-CtrlSpace 5 took me 5 months of spare evenings
to complete :).

The most exciting **Vim-CtrlSpace 5** features are:

* better, modular, and extensible code base
* simplified, well thought-out, and clear design
* new fuzzy search engine for files (written in Go)
* more effective and responsive behavior
* fine-grained configuration


##### Upgrading from Version 4

Version 5 is not backward compatible. But main issues are
related to restoring your workspaces and there is a simple workaround for it.

After upgrading please open `cs_workspaces` file for given project (it's
usually stored at e.g. `.git/cs_workspaces`) and rename proper variable
names:

    :e .git/cs_workspaces
    :%s/t:ctrlspace_label/t:CtrlSpaceLabel/g
    :%s/t:ctrlspace_autotab/t:CtrlSpaceAutotab/g
    :wq


## Idea by Analogy

Vim-CtrlSpace interface is a window you can invoke by pressing
`<C-Space>`. The window displays a list of items. You can select those
items with `<h>`, `<j>`, and `<CR>` keys.

Generally speaking Vim-CtrlSpace can display 5 types of lists: 

* Buffer List
* File List
* Tab List
* Workspace List
* Bookmark List

Lists can be explained with a simple analogy. Let's imagine Vim is
a writing desk. Your projects are like drawers. The **Bookmark List**
simply displays your favorite projects.

To get documents from a drawer you would need a **File List**. It allows
you to easily look up contents of a given project. Once you locate and
pick up a file it becomes a **buffer**.

A buffer is like a sheet of paper lying on the desk. Sometimes you can
have a blank piece of paper – that's a new unsaved buffer. It would become
eventually a file on the disk once saved (put into a drawer). To manage
all buffers on the desk you would need a **Buffer List**.

So far our analogy is fairly simple. This workflow is straightforward but
inefficient in the long run with a large amount of files. How could we
optimize it?

The answer are **tabs** – a secret weapon of **Vim-CtrlSpace**. Each tab
holds a **separate** list of buffers. And this is something very different
when compared to plain Vim. Tabs powered by the plugin can be seen as
piles of documents on the desk.

With tabs you can, for example: 

* group related buffers
* extract to other tabs
* name them accordingly
* move or copy them

Tabs usage in **Vim-CtrlSpace** is quite more extensive than in Vim. This
is because they serve mainly as independent buffer lists, so you are
likely to have plenty of them. Tabs can be accessed and managed within
**Tab List**.

All your buffers, tabs, and tab layouts can be persisted as a workspace.
It's like taking a picture of your desk with an instant camera. You can
save multiple workspaces per project with **Workspace List**.


## Getting Started

### Installation

If you use Vundle add:

    Plugin 'szw/vim-ctrlspace' 

to your `.vimrc`.

You can also clone the repository to your `.vim` directory:

    cd ~/.vim
    git clone https://github.com/szw/vim-ctrlspace.git .


### Basic Settings

First please make sure that you set `nocompatible` and `hidden` options
(required by the plugin) in your `.vimrc`:

    set nocompatible
    set hidden

If you feel brave enough **turn off** tabline:

    set showtabline=0

Tabline in Vim has very limited capabilities and as Vim-CtrlSpace makes
use of tabs intensively, tabline would just get in your way. **Tab List**
(`<l>`) makes tabline obsolete ;).


#### Go Engine

The plugin provides engine compiled for several architectures:

* `file_engine_darwin_386`
* `file_engine_darwin_amd64`
* `file_engine_freebsd_386`
* `file_engine_freebsd_amd64`
* `file_engine_freebsd_arm`
* `file_engine_linux_386`
* `file_engine_linux_amd64` 
* `file_engine_linux_arm`
* `file_engine_netbsd_386`
* `file_engine_netbsd_amd64`
* `file_engine_netbsd_arm`
* `file_engine_openbsd_386`
* `file_engine_openbsd_amd64`
* `file_engine_plan9_386`
* `file_engine_windows_386.exe`
* `file_engine_windows_amd64.exe`

To enable **Go file engine** please pick the one matching your machine and add
it (this is an example for Mac OS X):

    let g:CtrlSpaceFileEngine = "file_engine_darwin_amd64"

to `.vimrc`.


#### Symbols

You can improve your UTF8 characters if necessary. Some graphic
glyphs might not fit well to one another. If you feel plugin symbols look
awful, don't hesitate to adjust symbols or their spacing. For example,
I use MacVim and Inconsolata font, therefore I use the following adjustment:

    let g:CtrlSpaceSymbols = { "NTM": " ⁺" }

You can find more about this option in the plugin help: 

    :help g:CtrlSpaceSymbols


#### Glob Command

Another important setting is the *Glob* command. This command is used to
collect all files in your project directory. Specifically, I recommend
that you install and use `ag`, as it respects `.gitignore` rules and is
really fast. Once it's installed you can add this line to your `.vimrc`:

    let g:CtrlSpaceGlobCommand = 'ag -l --nocolor -g ""'


#### Colors

Finally, you can tweak up some plugin colors. By default plugin uses
the following setup:

    hi link CtrlSpaceNormal   PMenu
    hi link CtrlSpaceSelected PMenuSel
    hi link CtrlSpaceSearch   Search
    hi link CtrlSpaceStatus   StatusLine

It provides overall good results. However some color schemes show search
results with the same colors as PMenu groups. If that's your case try to
link CtrlSpaceSearch highlight group to IncSearch instead:

    hi link CtrlSpaceSearch IncSearch

Of course nothing prevents you from providing your own highlighting, for example:

    hi CtrlSpaceSearch guifg=#cb4b16 guibg=NONE gui=bold ctermfg=9 ctermbg=NONE term=bold cterm=bold


### First Steps

Alright! You've hopefully installed, configured Vim-CtrlSpace, and
restarted Vim (otherwise do it!). Now you're wondering how to start using
this thing.

First, you need to select a project. Vim operates in a directory,
described as `CWD` (_Current Working Directory_). If you've just started
a MacVim it's probably pointing to your home directory (issue `:pwd` to
check it).

I advise you to add a project to the Bookmark List by opening the plugin
window (`<C-Space>`) and pressing `<b>`. The plugin will ask for a project
directory.

Make sure that the path **is not home directory**. Otherwise the plugin
will start indexing all your files which will be pointless and resource
exhaustive. Be concrete and provide a real path to a project. Once your
bookmark is created, you can go there with `<CR>`.

Now open some files with `<o>`. Finally save a workspace with `<w>` by
providing your first workspace name.

More guides you can find in the [project wiki](#todo-link). For key
reference press `<?>` inside the plugin window.


## Authors and License

Copyright &copy; 2013-2015 [Szymon Wrozynski and
Contributors](https://github.com/szw/vim-ctrlspace/commits/master).
Licensed under [MIT
License](https://github.com/szw/vim-ctrlspace/blob/master/plugin/ctrlspace.vim#L5-L26)
conditions. 

**Vim-CtrlSpace** is inspired by Robert Lillack plugin [VIM
bufferlist](https://github.com/roblillack/vim-bufferlist) &copy; 2005
Robert Lillack. Moreover some concepts and inspiration has been taken from
[Vim-Tabber](https://github.com/fweep/vim-tabber) by Jim Steward and
[Tabline](https://github.com/mkitt/tabline.vim) by Matthew Kitt.

Special thanks to [Wojtek Ryrych](https://github.com/ryrych) for help and
patience ;) and all
[Contributors](https://github.com/szw/vim-ctrlspace/commits/master).
