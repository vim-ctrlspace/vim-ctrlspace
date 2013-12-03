Vim-CtrlSpace
=============

Vim Workspace Controller

About
-----

### TL;DR

**Vim-CtrlSpace** is a great plugin that helps you to get more power from Vim while working with
buffers, tabs, windows, and so on. It is meant to organize your Vim screen space and your workspace 
effectively. To accomplish that **Vim-CtrlSpace** introduces a concept of separated buffer
lists per tab and provides a lot of power around that (buffer and file management, multiple
workspaces stored on disk, fuzzy search, tab management, and more).

Its name follows the convention of naming similar plugins after their default mappings (like
*Command-T* or *CtrlP*). Obviously, the plugin mapping is by default `Ctrl + Space`. 

### Demo

Here's a small demonstration. Viewing in HD advised!

<iframe width="640" height="360" src="http://www.youtube.com/embed/09l92uwKupI?rel=0" 
frameborder="0" allowfullscreen></iframe>

The Demo has been recorded with: 

- a console Vim 7.4 (Menslo font)
- a bit modified [Seoul 256 colorscheme](https://github.com/szw/seoul256.vim)
- following Vim-CtrlSpace settings in .vimrc:

        hi CtrlSpaceSelected term=reverse ctermfg=187  ctermbg=23  cterm=bold
        hi CtrlSpaceNormal   term=NONE    ctermfg=244  ctermbg=232 cterm=NONE
        hi CtrlSpaceFound    ctermfg=220  ctermbg=NONE cterm=bold

- Music: [Professor Kliq - Curriculum
  Vitae](http://www.jamendo.com/pl/list/a109465/curriculum-vitae)

### The Story

There are many ways of working with Vim. It's no so straight forward like in other editors. People
often find their own methods of working with Vim and increasing their productivity. However, some
settings and scenarios seem to be preffered rather than others. And that means also some common
issues.

The main attitude is to combine buffers, split windows, and tabs effectively. In Vim, unlike in
other editors, tabs are not tabs really. They are just containers for split windows, sometimes
referred as *viewports*. The tab list - considered as a list of open files - buffers, is called
a *buffer list*. Usually, it's not immediately visible but you can issue a command `:ls` to see it
yourself.

Of course, there are many plugins allowing you to see, change, and manage buffers. In fact,
**Vim-CtrlSpace** has been started as a set of improvements of a such existing plugin. It was named
[VIM bufferlist](https://github.com/roblillack/vim-bufferlist) by Rob Lillack. It was a neat and
tiny plugin (270 LOC), but a bit abandoned. Now, about 7 months later, **Vim-CtrlSpace** has about
2.5K LOC and still uses some code of that Rob's plugin :). 

Typical Vim usage, exhibited by many Vim power users, is to treat tabs as units of work on different
topics. If, for example, I'm working on a web application with User management, I can have a tab
containing a User model and test files, perhaps a User controller file, and some view files. If it
would be possible (actually in **Vim-CtrlSpace** it is!) I could name that tab "Users". Then, if
I move to, let's say Posts I can have similar set of open files in the next tab. That way I can move
back and forward between these two concerns. In the third one I could have e.g. config files, etc. 

This approach works, and works very well. In fact, you can even never touch the real buffer list down
there. You can disable so called *hidden* buffers to make sure you manage only what you see in tabs.

I was working that way a long time. But there are some subtle issues behind the scene ;). The first
one is the screen size. With this approach you are limited to the screen size. At some point the
code in split windows doesn't fit the windows at all, even if you have a full HD screen with Vim
maximized. The second one is a lot of distraction. Sometimes you might want just to focus on a one
particular file. To address that I have developed a tool called
[Vim-Maximizer](https://github.com/szw/vim-maximizer). Vim Maximizer allows you to temporarily
maximize one split window, just by pressing `F3` (by default). It is even shown in the demo movie
above. That was cool, but still I needed something better, especially since I started working on
13-inch laptop.

And that was the moment when **Vim-CtrlSpace** came to play. 

### Vim-CtrlSpace Idea

First, I wanted a cool buffer list. Something neat and easy. MinibufExplorer and friends have some
issues with hidden buffers. Also, I have troubles when I have too many buffers open. The list gets
longer and longer. A tool like CtrlP was helpful to some point (especially when I was looking for
a buffer), but it doesn't show you all buffers available. 

I started playing with Rob Lillack's *VIM bufferlist* and finally I created a solution. I've
introduced a concept of many buffer lists tightly coupled with tabs. That means each tab holds its
own buffer list. Once the buffer is shown in the tab, the tab is storing it in its own buffer list.
No matter in which window. It's just like having many windows related to the same concern, but
without the need of split windows at all! Then you can forget the buffer (remove it from tab's
buffer list), or perform many other actions. Of course, it's possible to access the main buffer list
(the list of all open buffers). In that way, you can easily add new friends to the current tab. It's
also perfectly valid to have a buffer shared among many tabs at the same time (it can be listed on
many lists). Similarly, you can have a buffer that is not connected to any particular tab. It's just
a hidden buffer (not displayed at the moment), visible in the "all buffers" list.

That was a breaking change. Next things are just consequences of that little invention. I've added
a lot of buffer operations (opening, closing, renaming, etc), the ability of opening files (together
with file operations too), fuzzy search through buffer lists and files, full list jumps and search
history, easy access to tabs (with full tab management and custom tab names), and finally workspace
management (saving to disk and loading). That means you can have many named workspaces per project.

All those improvements let me to start using **Vim-CtrlSpace** instead of *CtrlP* or even
*NERDTree*. But, of course, nothing stops you to combine all those plugins together, especially if
you used to work with other ones. There are no inteferences, just some functionality doubling.

Installation
------------

The plugin installation is really simple. You can use Vundle or Pathogen, or just clone the
repository to your `.vim` directory. In case of Vundle, add:

    Bundle "szw/vim-ctrlspace" 

to you `.vimrc`.

If you want to increase fuzzy search speed, make sure you have decent Ruby bindings in your Vim
enabled (compiled in). The plugin will try to use your Ruby in available by default.

Usage
-----

### Status Bar

After pressing `<C-Space>` (default) **Vim-CtrlSpace** invites you with a window at the bottom of the
screen (a bit similar to *CtrlP*). Notice, **Vim-CtrlSpace** requires a status bar. If you are using
a plugin customizing the status bar this could be a bit tricky. In the Troubleshoting section I will
provide you with guides how to enable **Vim-Vim-CtrlSpace** status bar with different status bar
plugins (*Airline*, *LightLine*, *Vim-Powerline*, etc).

#### Status Bar Symbols

<table>
<thead>
<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>▢</code></td>
<td><code>CS</code></td>
<td>Vim-CtrlSpace symbol</td>
</tr>
<tr>
<td><code>⊙</code></td>
<td><code>TAB</code></td>
<td>Single Tab mode indicator</td>
</tr>
<tr>
<td><code>∷</code></td>
<td><code>ALL</code></td>
<td>All Tabs mode indicator</td>
</tr>
<tr>
<td><code>○</code></td>
<td><code>ADD</code></td>
<td>Add mode indicator</td>
</tr>
<tr>
<td><code>⌕</code></td>
<td><code>&#42;</code></td>
<td>Preview mode indicator</td>
</tr>
<tr>
<td><code>⋮ → ∙</code></td>
<td><code>LOAD</code></td>
<td>Workspace mode (load)</td>
</tr>
<tr>
<td><code>∙ → ⋮</code></td>
<td><code>SAVE</code></td>
<td>Workspace mode (save)</td>
</tr>
<tr>
<td><code>›&#95;‹</code></td>
<td><code>[&#95;]</code></td>
<td>Search mode or search order</td>
</tr>
<tr>
<td><code>₁²₃</code></td>
<td><code>123</code></td>
<td>Order buffers by numbers (in Single Tab and All Tabs modes)</td>
</tr>
<tr>
<td><code>авс</code></td>
<td><code>ABC</code></td>
<td>Order buffers alphabetically (in Single Tab and All Tabs modes)</td>
</tr>
</tbody>
</table>

### Single Tab Mode

The plugin has many modes available. In a modal editor like Vim this should not fear you ;). I believe
its modes are very simple to recognize and understand. The main one is the Single Tab mode. In that
mode, the plugin shows you buffers related to the current tab only. It's almost like a normal mode
in Vim ;). From that point you can follow many paths. Here's the full available keys listing:

#### Keys Reference

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggle available keys info (depends on space available in the status bar)</td>
</tr>

<tr>
<td><code>Return</code>
</td><td>Opens the selected buffer</td>
</tr>

<tr>
<td><code>Space</code></td>
<td>Opens the selected buffer but stays in the <b>Vim-CtrlSpace</b> window</td>
</tr>

<tr>
<td><code>Tab</code></td>
<td>Enters the Preview mode with the selected buffer</td>
</tr>

<tr>
<td><code>Backspace</code></td>
<td>Goes back (here it will just close the plugin window)</td>
</tr>

<tr>
<td><code>/</code></td>
<td>Enters the Search mode</td>
</tr>

<tr>
<td><code>\</code></td>
<td>Enters the Search mode in the Add (files) mode immediately</td>
</tr>

<tr>
<td><code>v</code></td>
<td>Opens the selected buffer in a new vertical split</td>
</tr>

<tr>
<td><code>s</code></td>
<td>Opens the selected buffer in a new horizontal split</td>
</tr>

<tr>
<td><code>t</code></td>
<td>Opens the selected buffer in a new tab</td>
</tr>

<tr>
<td><code>T</code></td>
<td>Creates a new tab and stays in the plugin window</td>
</tr>

<tr>
<td><code>0..9</code></td>
<td>Jumps to the n-th tab (0 is for 10th one)</td>
</tr>

<tr>
<td><code>-</code></td>
<td>Move the current tab to the left (decreases its number)</td>
</tr>

<tr>
<td><code>+</code></td>
<td>Move the current tab to the right (increases its number)</td>
</tr>

<tr>
<td><code>=</code></td>
<td>Changes the tab name (leave it blank to remove the custom name)</td>
</tr>

<tr>
<td><code>&#95;</code></td>
<td>Removes a custom tab name</td>
</tr>

<tr>
<td><code>[</code></td>
<td>Goes to the previous (left) tab</td>
</tr>

<tr>
<td><code>]</code></td>
<td>Goes to the next (right) tab</td>
</tr>

<tr>
<td><code>o</code></td>
<td>Toggles between sorting modes (chronological vs alphanumeric)</td>
</tr>

<tr>
<td><code>q</code> / <code>Ctrl + Space</code>&#42;</td>
<td>Closes the list <br/>&#42; - depends on settings</td>
</tr>

<tr>
<td><code>j</code></td>
<td>Moves the selection bar down</td>
</tr>

<tr>
<td><code>J</code></td>
<td>Moves the selection bar to the bottom of the list</td>
</tr>

<tr>
<td><code>k</code></td>
<td>Moves the selection bar up</td>
</tr>

<tr>
<td><code>K</code></td>
<td>Moves the selection bar to the top of the list</td>
</tr>

<tr>
<td><code>p</code></td>
<td>Jumps to the previous opened buffer</td>
</tr>

<tr>
<td><code>P</code></td>
<td>Jumps to the previous opened buffer and opens it immediately</td>
</tr>

<tr>
<td><code>n</code></td>
<td>Jumps to the next opened buffer</td>
</tr>

<tr>
<td><code>d</code></td>
<td>Deletes the selected buffer (closes it)</td>
</tr>

<tr>
<td><code>D</code></td>
<td>Closes all empty noname buffers</td>
</tr>

<tr>
<td><code>f</code></td>
<td>Forgets the current buffer (make it a <em>foreign</em> (unrelated) to the current tab)</td>
</tr>

<tr>
<td><code>F</code></td>
<td>Deletes (closes) all forgotten buffers (unrelated with any tab)</td>
</tr>

<tr>
<td><code>c</code></td>
<td>Combines <code>c</code> and <code>d</code>. If the selected buffer is opened only in the current
tab - <code>c</code> will close (delete) it. Otherwise it will just forget it (detach from the
current tab)</td>
</tr>

<tr>
<td><code>C</code></td>
<td>Closes the current tab, then performs <code>F</code> (closes
forgotten buffers - probably those ones from just closed tab) and <code>D</code> (closes empty
nonames)</td>
</tr>

<tr>
<td><code>e</code></td>
<td>Create a new named buffer being a sibling to the selected one</td>
</tr>

<tr>
<td><code>E</code></td>
<td>Open a directory of the selected buffer</td>
</tr>

<tr>
<td><code>R</code></td>
<td>Removes the selected buffer (file) entirely (from the disk too)</td>
</tr>

<tr>
<td><code>m</code></td>
<td>Moves or renames the selected buffer (file)</td>
</tr>

<tr>
<td><code>a</code></td>
<td>Toggles between Single Tab and All Tabs modes</td>
</tr>

<tr>
<td><code>A</code></td>
<td>Enters the Add (file) mode</td>
</tr>

<tr>
<td><code>Ctrl + p</code></td>
<td>Brings back the previous searched text</td>
</tr>

<tr>
<td><code>Ctrl + n</code></td>
<td>Jumps to the next searched text</td>
</tr>

<tr>
<td><code>S</code></td>
<td>Save the workspace immediately (or create a new one if none)</td>
</tr>

<tr>
<td><code>w</code></td>
<td>Enters the Workspace mode</td>
</tr>

</tbody>

</table>

### All Tabs Mode

This mode is almost identical like the Single Tab mode, except it shows you all available buffers.
Some of keys presented in the Single Tab mode are not available here. The missing ones are `f` and
`c` - since they are coupled tightly with the current tab.

### Add Mode

The _file_ mode, or the _append file_ mode. It allow you to add a file (as a buffer) to the current
tab. In other words, it opens files from the current project directory. Always, the current working
directory is considered here. The plugin tries to estimate if the contents of the current directory
can be considered as a valid project. It looks for so called _project root markers_. The markers are
usually repository directories or files like `.git`. In there is no presence of such root makers,
the plugin will ask you if the current directory should be permanently considered as a project root.
This is to prevent you from accidental loading root of i.e. you home directory, as it would be
really time consuming and rather pointless.

For the first time (or after some file/directory changing actions) the file list is populated with
data. Sometimes, for very large project this could be time consuming (I've noticed a lag for
a project with over 2200 files). After that, the content of the current working directory is cached
and available immediately. 

#### Keys Reference

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggle available keys info (depends on space available in the status bar)</td>
</tr>

<tr>
<td><code>Return</code>
</td><td>Opens the selected file</td>
</tr>

<tr>
<td><code>Space</code></td>
<td>Opens the selected file but stays in the <b>Vim-CtrlSpace</b> window</td>
</tr>

<tr>
<td><code>Backspace</code>, <code>a</code>, and <code>A</code></td>
<td>Goes back (here it will return to Single Tab or All Tabs mode)</td>
</tr>

<tr>
<td><code>/</code> and <code>\</code></td>
<td>Enters the Search mode</td>
</tr>

<tr>
<td><code>v</code></td>
<td>Opens the selected file in a new vertical split</td>
</tr>

<tr>
<td><code>s</code></td>
<td>Opens the selected file in a new horizontal split</td>
</tr>

<tr>
<td><code>t</code></td>
<td>Opens the selected file in a new tab</td>
</tr>

<tr>
<td><code>T</code></td>
<td>Creates a new tab and stays in the plugin window</td>
</tr>

<tr>
<td><code>0..9</code></td>
<td>Jumps to the n-th tab (0 is for 10th one)</td>
</tr>

<tr>
<td><code>-</code></td>
<td>Move the current tab to the left (decreases its number)</td>
</tr>

<tr>
<td><code>+</code></td>
<td>Move the current tab to the right (increases its number)</td>
</tr>

<tr>
<td><code>=</code></td>
<td>Changes the tab name (leave it blank to remove the custom name)</td>
</tr>

<tr>
<td><code>&#95;</code></td>
<td>Removes a custom tab name</td>
</tr>

<tr>
<td><code>[</code></td>
<td>Goes to the previous (left) tab</td>
</tr>

<tr>
<td><code>]</code></td>
<td>Goes to the next (right) tab</td>
</tr>

<tr>
<td><code>q</code> / <code>Ctrl + Space</code>&#42;</td>
<td>Closes the list <br/>&#42; - depends on settings</td>
</tr>

<tr>
<td><code>j</code></td>
<td>Moves the selection bar down</td>
</tr>

<tr>
<td><code>J</code></td>
<td>Moves the selection bar to the bottom of the list</td>
</tr>

<tr>
<td><code>k</code></td>
<td>Moves the selection bar up</td>
</tr>

<tr>
<td><code>K</code></td>
<td>Moves the selection bar to the top of the list</td>
</tr>

<tr>
<td><code>C</code></td>
<td>Closes the current tab, then performs <code>F</code> (closes
forgotten buffers - probably those ones from just closed tab) and <code>D</code> (closes empty
nonames)</td>
</tr>

<tr>
<td><code>e</code></td>
<td>Create a new named buffer being a sibling to the selected one</td>
</tr>

<tr>
<td><code>E</code></td>
<td>Open a directory of the selected buffer</td>
</tr>

<tr>
<td><code>r</code></td>
<td>Refreshes the file list (force reloading)</td>
</tr>

<tr>
<td><code>R</code></td>
<td>Removes the selected file entirely</td>
</tr>

<tr>
<td><code>m</code></td>
<td>Moves or renames the selected file</td>
</tr>

<tr>
<td><code>Ctrl + p</code></td>
<td>Brings back the previous searched text</td>
</tr>

<tr>
<td><code>Ctrl + n</code></td>
<td>Jumps to the next searched text</td>
</tr>

<tr>
<td><code>w</code></td>
<td>Enters the Workspace mode</td>
</tr>

</tbody>

</table>

#### Preview Mode

#### Search Mode

#### Nop Mode

#### Workspace Mode

Configuration
-------------

API 
---
