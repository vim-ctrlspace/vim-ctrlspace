Vim-CtrlSpace
=============

TL;DR
-----

**Vim-CtrlSpace** is a great plugin that helps you to get more power from Vim while working with
buffers, tabs, windows, and so on. It is meant to organize your Vim screen space and your workspace
effectively. To accomplish that **Vim-CtrlSpace** introduces a concept of separated buffer lists per
tab and provides a lot of power around that (buffer and file management, multiple workspaces stored
on disk, fuzzy search, tab management, and more).

Its name follows the convention of naming similar plugins after their default mappings (like
*Command-T* or *CtrlP*). Obviously, the plugin mapping is by default `Ctrl + Space`. 

If you like the plugin please don't forget to add a star (:star:)! This will help me to estimate the
plugin popularity and that way I will proceed better its further development :).

### Demo

Here's a small demonstration. Viewing in HD advised!

[![Demo](https://raw.github.com/szw/vim-ctrlspace/master/screen_small.png)](https://www.youtube.com/watch?v=09l92uwKupI)

The Demo has been recorded with: 

- a console Vim 7.4 (Menslo font)
- a bit modified [Seoul256 color scheme](https://github.com/szw/seoul256.vim)
- following Vim-CtrlSpace settings in .vimrc:

        hi CtrlSpaceSelected term=reverse ctermfg=187  ctermbg=23  cterm=bold
        hi CtrlSpaceNormal   term=NONE    ctermfg=244  ctermbg=232 cterm=NONE
        hi CtrlSpaceFound    ctermfg=220  ctermbg=NONE cterm=bold

- music: [Professor Kliq - Curriculum
  Vitae](http://www.jamendo.com/pl/list/a109465/curriculum-vitae)

About
-----

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
[VIM bufferlist](https://github.com/roblillack/vim-bufferlist) by Rob Lillack. That was a neat and
tiny plugin (270 LOC), but a bit abandoned. Now, about 7 months later, **Vim-CtrlSpace** has about
2.5K LOC and still uses some code of that Rob's plugin :). 

Typical Vim usage, exhibited by many Vim power users, is to treat tabs as units of work on different
topics. If, for example, I work on a web application with User management, I can have a tab
containing a User model and test files, perhaps a User controller file, and some view files. If it
would be possible (actually in **Vim-CtrlSpace** it is!) I could name that tab _Users_. Then, if
I move to, let's say Posts I can have similar set of open files in the next tab. That way I can go
back and forward between these two concerns. In the third tab I could have e.g. config files, etc.

This approach works, and works very well. In fact, you can never touch the real buffer list down
there. You can even disable so called *hidden* buffers to make sure you manage only what you see in
tabs.

I've been working that way for a long time. However, there are some subtle issues behind the scene. The
first one is the screen size. With this approach you are limited to the screen size. At some point
the code in split windows doesn't fit those windows at all, even if you have a full HD screen with
Vim maximized. The second issue is a lot of distraction. Sometimes you might want just to focus on
a one particular file. To address that I have developed a tool called
[Vim-Maximizer](https://github.com/szw/vim-maximizer). *Vim-Maximizer* allows you to temporarily
maximize one split window, just by pressing `F3` (by default). This can be seen in the demo movie
above. That was cool, but still I needed something better, especially since I started working on
13-inch laptop...

And that was the moment when **Vim-CtrlSpace** came to play. 

### Vim-CtrlSpace Idea

First, I wanted a cool buffer list. Something neat and easy. MinibufExplorer and friends have some
issues with unnamed buffers. Also, I have troubles when I have too many buffers open. The list gets
longer and longer. A tool like CtrlP was helpful to some point (usually when I was looking for
a buffer), but it doesn't show you all buffers available. 

I started playing with Rob Lillack's *VIM bufferlist* and finally I've created a solution. I've
introduced a concept of many buffer lists tightly coupled with tabs. That means each tab holds its
own buffer list. Once a buffer is shown in the tab, the tab is storing it in its own buffer list.
No matter in which window. It's just like having many windows related to the same concern, but
without the need of split windows at all! Then you can forget the buffer (remove it from tab's
buffer list), or perform many other actions. Of course, it's possible to access the main buffer list
(the list of all open buffers) - in that way, you can easily add new friends to the current tab. It's
also perfectly valid to have a buffer shared among many tabs at the same time (it will be listed on
many lists). Similarly, you can have a buffer that is not connected to any particular tab. It's just
a hidden buffer (not displayed at the moment), visible only in the _all buffers_ list.

That was a breaking change. Next things are just consequences of that little invention. I've added
a lot of buffer operations (opening, closing, renaming, etc), the ability of opening files (together
with file operations too), fuzzy search through buffer lists and files, separate jump lists, search
history, easy tab access (with full tab management and custom tab names), and last but not least,
workspace management (saving to disk and loading). That means you can have plenty of named workspaces
per project.

All those improvements let me to start using **Vim-CtrlSpace** instead of *CtrlP* or even
*NERDTree*. But, of course, nothing stops you to combine all those plugins together, especially if
you used to work with them. There are no inteferences, just some functionality doubling.

Installation
------------

The plugin installation is really simple. You can use Vundle or Pathogen, or just clone the
repository to your `.vim` directory. In case of Vundle, add:

    Bundle "szw/vim-ctrlspace" 

to you `.vimrc`.

If you want to increase fuzzy search speed, make sure you have decent Ruby bindings enabled in
(compiled into) your Vim. The plugin will try to use your Ruby by default.

Usage
-----

### Status Line

**Vim-CtrlSpace** requires a status bar. If you are using a plugin customizing the status bar this
could be a bit tricky. For example [vim-airline](https://github.com/bling/vim-airline) plugin might
require you to set: `let g:airline_exclude_preview = 1` option and
[LightLine](https://github.com/itchyny/lightline.vim) will require to use custom status line
segments, provided by **Vim-CtrlSpace** API.  

#### Status Line Symbols

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

### Tabline

**Vim-CtrlSpace** can set a custom tabline. If the proper option is enabled
(`g:ctrlspace_use_tabline`), the plugin will set a custom tabline for you. The tabs in that tabline
are displayed in the following way:

<table>

<tr>
<th>Unicode</th>
<td><code>1</code></td>
<td><code>²</code></td>
<td><code>+</code></td>
<td><code>[</code></td>
<td><code>README.md</code></td>
<td><code>]</code></td>
</tr>

<tr>
<th>ASCII</th>
<td><code>1</code></td>
<td><code>:2</code></td>
<td><code>+</code></td>
<td><code>[</code></td>
<td><code>README.md</code></td>
<td><code>]</code></td>
</tr>

<tr>
<th>Description</th>
<td>Tab number</td>
<td>Buffers count</td>
<td>Modified indicator</td>
<td>Opening bracket<br/>(only for buffer names)</td>
<td>Buffer or tab name</td>
<td>Closing bracket<br/>(only for buffer names)</td>
</tr>

</table>

### Project Root

The plugin requires a project root to work properly. If you open the plugin window for the first
time it will try to find out the possible root directory. First, it starts in the Vim current
working directory and check if there are so called root markers. The root markers are characteristic
files or directories that are available in a typical project root directory, like e.g. `.git` or
`.hg` directories. You can define them yourself in the `g:ctrlspace_project_root_markers` variable.
If no markers found, the plugin will check if perhaps this directory is a known root. The known
roots are those ones you provided (accepted) yourself when no markers were found. If the current
directory cannot be proven as a project root, the algorithm will repeat the whole procedure in the
parent one. 

After checking all predecessors it will ask you to provide the root folder explicitly. After your
acceptance that root folder will be stored pemanently in the `.cs_cache` file.

### Main Modes

The plugin offers you a few modes. In a modal editor like Vim this should not fear you ;). I believe
its modes are very simple to recognize and understand.

Moreover, buffers and workspaces listed in the plugin window can have additional indicators
(following the item text):

<table>

<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
<th>Indicator</th>
</tr>

<tr>
<td><code>+</code></td>
<td><code>+</code></td>
<td>Item modified</td>
</tr>

<tr>
<td><code>★</code></td>
<td><code>&#42;</code></td>
<td>Item visible (or active)</td>
</tr>

</table>

#### Simplified Key Diagram

This is a simplified diagram of key groups used in **Vim-CtrlSpace** modes.

![Key Groups](https://raw.github.com/szw/vim-ctrlspace/master/cs_keys.png)

_This file is licensed under GNU FDL license. It is derived from
[Qwerty.svg](http://commons.wikimedia.org/wiki/File:Qwerty.svg) file by [Oona
Räisänen](http://en.wikipedia.org/wiki/User:Mysid) &copy; 2005._

#### Single Tab Mode

<table>
<thead>
<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>⊙</code></td>
<td><code>TAB</code></td>
</tr>
</tbody>
</table>

The first main mode is the Single Tab. In that mode, the plugin shows you only buffers related to the
current tab. It's almost like a normal mode in Vim ;). It's like a root from you can follow many paths.
Here's the full listing of full available keys:

##### Keys Reference

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggles info about available keys (depends on space left in the status bar)</td>
</tr>

<tr>
<td><code>Return</code></td>
<td>Opens a selected buffer</td>
</tr>

<tr>
<td><code>Space</code></td>
<td>Opens a selected buffer and stays in the <b>Vim-CtrlSpace</b> window</td>
</tr>

<tr>
<td><code>Tab</code></td>
<td>Enters the Preview mode for selected buffer</td>
</tr>

<tr>
<td><code>Backspace</code></td>
<td>Goes back (in this mode it will just close the plugin window)</td>
</tr>

<tr>
<td><code>/</code></td>
<td>Enters the Search mode</td>
</tr>

<tr>
<td><code>\</code></td>
<td>Enters the Search mode in the Add (files) mode immediately (a shortcut for <code>A/</code>)</td>
</tr>

<tr>
<td><code>v</code></td>
<td>Opens selected buffer in a new vertical split</td>
</tr>

<tr>
<td><code>s</code></td>
<td>Opens selected buffer in a new horizontal split</td>
</tr>

<tr>
<td><code>t</code></td>
<td>Opens selected buffer in a new tab</td>
</tr>

<tr>
<td><code>T</code></td>
<td>Creates a new tab and stays in the plugin window</td>
</tr>

<tr>
<td><code>0..9</code></td>
<td>Jumps to the n-th tab (0 is for the 10th one)</td>
</tr>

<tr>
<td><code>-</code></td>
<td>Moves the current tab to the left (decreases its number)</td>
</tr>

<tr>
<td><code>+</code></td>
<td>Moves the current tab to the right (increases its number)</td>
</tr>

<tr>
<td><code>=</code></td>
<td>Changes the tab name (leave it blank to remove the custom name)</td>
</tr>

<tr>
<td><code>&#95;</code></td>
<td>Removes a custom tab name (the same as <code>=</code> with a blank name)</td>
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
<td>Toggles the sorting order (chronological vs alphanumeric)</td>
</tr>

<tr>
<td><code>q</code> and <code>Ctrl + Space</code>&#42;</td>
<td>Closes the list <br/>&#42; - depends on plugin mappings</td>
</tr>

<tr>
<td><code>Q</code></td>
<td>Quits Vim (but with a prompt if unsaved workspaces or tab buffers were found)</td>
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
<td>Moves the selection bar to the previous opened buffer</td>
</tr>

<tr>
<td><code>P</code></td>
<td>Moves the selection bar to the <em>previous</em> opened buffer and opens it immediately</td>
</tr>

<tr>
<td><code>n</code></td>
<td>Moves the selection bar to the <em>next</em> opened buffer (just the reverse of <code>p</code>)</td>
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
<td>Deletes (closes) all forgotten buffers (unrelated to any tab)</td>
</tr>

<tr>
<td><code>c</code></td>
<td>Combines <code>c</code> and <code>d</code>. If the selected buffer is opened only in the current
tab - <code>c</code> will <em>close</em> (delete) it. Otherwise it will just forget it (detach from the
current tab)</td>
</tr>

<tr>
<td><code>C</code></td>
<td>Closes the current tab, then performs <code>F</code> (closes
forgotten buffers - probably these from that just closed tab) and <code>D</code> (closes empty
nonames)</td>
</tr>

<tr>
<td><code>e</code></td>
<td>Edits a sibling of the selected buffer (it will create a new one if necessary)</td>
</tr>

<tr>
<td><code>E</code></td>
<td>Explores a directory of the selected buffer</td>
</tr>

<tr>
<td><code>R</code></td>
<td>Removes the selected buffer (file) entirely (from the disk too)</td>
</tr>

<tr>
<td><code>m</code></td>
<td>Moves or renames the selected buffer (together with its file)</td>
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
<td>Brings the next searched text - just the opposite to <code>Ctrl + p</code></td>
</tr>

<tr>
<td><code>S</code></td>
<td>Saves the workspace immediately (or creates a new one if none)</td>
</tr>

<tr>
<td><code>w</code></td>
<td>Enters the Workspace mode</td>
</tr>

<tr>
<td><code>Ctrl + f</code></td>
<td>Moves the selection bar one screen down (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + b</code></td>
<td>Moves the selection bar one screen up (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + d</code></td>
<td>Moves the selection bar a half screen down (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + u</code></td>
<td>Moves the selection bar a half screen up (just like standard Vim behavior)</td>
</tr>

</tbody>

</table>

#### All Tabs Mode

<table>
<thead>
<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>∷</code></td>
<td><code>ALL</code></td>
</tr>
</tbody>
</table>

This mode is almost identical to the Single Tab mode, except it shows you all available buffers
(from all tabs and unrelated ones too). Some of keys presented in the Single Tab mode are not
available here. The missing ones are `f` and `c` - as they are tightly coupled with the current tab.

#### Add Mode

<table>
<thead>
<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>○</code></td>
<td><code>ADD</code></td>
</tr>
</tbody>
</table>

The _file_ mode, or the _file append_ mode. It allows you to _add_ a file (as a buffer) to the
current tab. In other words, it opens files from the project root directory. Notice, only the
project root directory is considered here. This will prevent you from accidental loading root of
i.e. your home directory, as it would be really time consuming and rather pointless.

For the first time (or after some disk operations) the file list is populated with data. Sometimes,
for a very large project this could be quite time consuming (I've noticed a lag for a project with
over 2200 files). After that, the content of the project root directory is cached and available
immediately. All the time you can force plugin to refresh the list with the `r` key.

##### Keys Reference

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggles info about available keys (depends on space left in the status bar)</td>
</tr>

<tr>
<td><code>Return</code></td>
<td>Opens a selected file</td>
</tr>

<tr>
<td><code>Space</code></td>
<td>Opens a selected file but stays in the <b>Vim-CtrlSpace</b> window</td>
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
<td>Opens a selected file in a new vertical split</td>
</tr>

<tr>
<td><code>s</code></td>
<td>Opens a selected file in a new horizontal split</td>
</tr>

<tr>
<td><code>t</code></td>
<td>Opens a selected file in a new tab</td>
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
<td>Moves the current tab to the left (decreases its number)</td>
</tr>

<tr>
<td><code>+</code></td>
<td>Moves the current tab to the right (increases its number)</td>
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
<td>Closes the list <br/>&#42; - depends on plugin mappings</td>
</tr>

<tr>
<td><code>Q</code></td>
<td>Quits Vim (but with a prompt if unsaved workspaces or tab buffers were found)</td>
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
<td>Edits a sibling of the selected buffer (it will create a new one if necessary)</td>
</tr>

<tr>
<td><code>E</code></td>
<td>Explores a directory of the selected buffer</td>
</tr>

<tr>
<td><code>r</code></td>
<td>Refreshes the file list (forces reloading)</td>
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
<td>Brings the next searched text - just the opposite to <code>Ctrl + p</code></td>
</tr>

<tr>
<td><code>w</code></td>
<td>Enters the Workspace mode</td>
</tr>

<tr>
<td><code>Ctrl + f</code></td>
<td>Moves the selection bar one screen down (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + b</code></td>
<td>Moves the selection bar one screen up (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + d</code></td>
<td>Moves the selection bar a half screen down (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + u</code></td>
<td>Moves the selection bar a half screen up (just like standard Vim behavior)</td>
</tr>

</tbody>

</table>

#### Workspace Mode

<table>
<thead>
<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>⋮ → ∙</code></td>
<td><code>LOAD</code></td>
</tr>
<tr>
<td><code>∙ → ⋮</code></td>
<td><code>SAVE</code></td>
</tr>
</tbody>
</table>

The plugin allows you to save and load so called _workspaces_. A workspace is a set of opened
windows, tabs, their names, and buffers. In fact, the word _workspace_ can be considered as
a synonym of a _session_ in **Vim-CtrlSpace**.

The ability of having so many _sessions_ available at hand creates a lot of interesting use cases!
For example, you can have a workspace for each task or feature you are working on. It's very easy to
switch from one workspace to another, thus this could be helpful with reviewing completed tasks and
continuing work on an item after some period of time. Moreover, you can have special workspaces
that are prepared to be appended to others. Consider, e.g. a _Config_ workspace. Imagine, you have
a separate workspace with the only one tab named _Config_ and some config files opened there. You
can easily append that workspace to you current or next ones, depending on your needs. That way
you are able to group the common and repetative sets of files in just one place and reuse that group
in many contexts.

In the Workspace mode **Vim-CtrlSpace** shows you available workspaces instead of buffers.
By default this mode is displayed in the _LOAD_ state. The second available state is _SAVE_.

Workspaces are saved in a file inside the project directory. Its name and path is determined by
proper plugin configuration options (`g:ctrlspace_workspace_file`). If there are 2 or more
split windows in a tab, they will be recreated as vertical splits while loading.

##### Keys Reference

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggles info about available keys (depends on space left in the status bar)</td>
</tr>

<tr>
<td><code>Return</code></td>
<td>Loads (or save) the selected workspace</td>
</tr>

<tr>
<td><code>Backspace</code>, <code>w</code></td>
<td>Goes back (here it will return to Single Tab or All Tabs mode)</td>
</tr>

<tr>
<td><code>q</code> / <code>Ctrl + Space</code>&#42;</td>
<td>Closes the list <br/>&#42; - depends on mappings</td>
</tr>

<tr>
<td><code>Q</code></td>
<td>Quits Vim (but with a prompt if unsaved workspaces or tab buffers were found)</td>
</tr>

<tr>
<td><code>a</code></td>
<td>Appends a selected workspace to the current one</td>
</tr>

<tr>
<td><code>s</code></td>
<td>Toggles the workspace state from load or save (or backward)</td>
</tr>

<tr>
<td><code>S</code></td>
<td>Saves the workspace immediately</td>
</tr>

<tr>
<td><code>d</code></td>
<td>Deletes the selected workspace</td>
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
<td><code>Ctrl + f</code></td>
<td>Moves the selection bar one screen down (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + b</code></td>
<td>Moves the selection bar one screen up (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + d</code></td>
<td>Moves the selection bar a half screen down (just like standard Vim behavior)</td>
</tr>

<tr>
<td><code>Ctrl + u</code></td>
<td>Moves the selection bar a half screen up (just like standard Vim behavior)</td>
</tr>

</tbody>

</table>

### Auxiliary Modes

These modes are just blended into the main ones. They can be considered as special cases or states
of the main ones.

#### Preview Mode

<table>
<thead>
<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>⌕</code></td>
<td><code>&#42;</code></td>
</tr>
</tbody>
</table>

This mode applies to buffer-related modes: Single Tab and All Tabs. You can invoke the Preview
mode by hitting the `Tab` key. Hitting `Tab` does almost the same as `Space` - it shows you the
selected buffer, but unlike `Space`, that change of the target window content is not permanent.
When you quit the plugin window, the old (previous) content of the target window is restored.

Also the jumps history remains unchanged and the selected buffer won't be added to the tab buffer
list. In that way, you can just preview a buffer before actually opening it (with `Space`, `Return`,
etc). 

Those previewed files are marked on the list with the star symbol and the original content is
marked with an empty star too:

<table>
<thead>
<tr>
<th>Indicator</th>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
</tr>
</thead>
<tbody>
<tr>
<td>Previewed buffer</td>
<td><code>★</code></td>
<td><code>&#42;</code></td>
</tr>
<tr>
<td>Original buffer</td>
<td><code>☆</code></td>
<td><code>&#42;</code></td>
</tr>
</tbody>
</table>

#### Search Mode

<table>
<thead>
<tr>
<th>Unicode Symbol</th>
<th>ASCII Symbol</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>›&#95;‹</code></td>
<td><code>[&#95;]</code></td>
</tr>
</tbody>
</table>

This mode is composed of two states or two phases. The first one is the _entering phase_. Technically,
this is the extact Search mode. In the entering phase the following keys are available:

##### Keys Reference (entering phase)

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggles info about available keys (depends on space left in the status bar)</td>
</tr>

<tr>
<td><code>Return</code></td>
<td>Closes the entering phase. Accepts the entered content.</td>
</tr>

<tr>
<td><code>Backspace</code></td>
<td>Removes the previouse entered character, or closes the entering phase if no character found.</td>
</tr>

<tr>
<td><code>/</code></td>
<td>Toggles the entering phase</td>
</tr>

<tr>
<td><code>\</code></td>
<td>Toggles the entering phase (only in the Add mode)</td>
</tr>

<tr>
<td><code>a..z A..Z 0..9</code></td>
<td>The charactes allowed in the entering phase</td>
</tr>

</tbody>

</table>

Besides the entering phase there is also a second state possible. That is the state of having
a search query entered. The successfully entered query behaves just like a kind of sorting. In fact,
it is just a kind of sorting and filtering function. So it doesn't impact on other modes except it
narrows the result set. 

It's worth to mention that in that mode the `Backspace` key removes the search query entirely.

#### Nop Mode

Nop (Non-Operational) mode happens when i.e. there are no items to show (empty list), or you are
trying to type a Search query, and there are no results at all. That means the Nop can happen during
the _entering phase_ of the Search mode or in some other cases. Those other cases can occur, for
example, when you have only not listed buffers available in the tab (like e.g. help window and some
preview ones). As you will see, in such circumstances - that is outside the entering phase - there
is a greater number of resque options available.

##### Nop (Search entering phase)

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggles info about available keys (depends on space left in the status bar)</td>
</tr>

<tr>
<td><code>Backspace</code></td>
<td>Removes the previouse entered character, or closes the entering phase if no character found.</td>
</tr>

</tbody>

</table>

##### Nop (outside the entering phase)

<table>

<thead><tr><th>Key</th><th>Action</th></tr></thead>

<tbody>

<tr>
<td><code>?</code></td>
<td>Toggles info about available keys (depends on space left in the status bar)</td>
</tr>

<tr>
<td><code>Backspace</code></td>
<td>Deletes the search query</td>
</tr>

<tr>
<td><code>q</code> / <code>Ctrl + Space</code>&#42;</td>
<td>Closes the list <br/>&#42; - depends on mappings</td>
</tr>

<tr>
<td><code>Q</code></td>
<td>Quits Vim (but with a prompt if unsaved workspaces or tab buffers were found)</td>
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
<td>Brings the next searched text - just the opposite to <code>Ctrl + p</code></td>
</tr>

</tbody>

</table>

Configuration
-------------

Vim-CtrlSpace has following configuration options. Almost all of them are declared as global
variables and should be defined in your `.vimrc` file in the similar form:

    let g:ctrlspace_foo_bar = 123

### `g:ctrlspace_height`

Sets the minimal height of the plugin window. Default value: `1`.

### `g:ctrlspace_max_height`

Sets the maximum height of the plugin window. If `0` provided it uses 1/3 of the screen height.
Default value: `0`.

### `g:ctrlspace_show_unnamed`

Adjusts the displaying of unnamed buffers. If you set `g:ctrlspace_show_unnamed = 1` then unnamed
buffers will be shown on the list all the time. However, if you set this value to `2`, unnamed
buffers will be displayed only if they are modified or just visible on the screen. Of course you can
hide unnamed buffers permanently by setting `g:ctrlspace_show_unnamed = 0`. Default value: `2`.

### `g:ctrlspace_set_default_mapping`

Turns on the default mapping. If you turn this option off (`0`) you will have to provide your own
mapping to the `CtrlSpace` yourself. Default value: `1`.

### `g:ctrlspace_default_mapping_key`

By default, **Vim-CtrlSpace** maps itself to `Ctrl + Space`. If you want to change the default mapping
provide it here as a string with valid Vim keystroke notation. Default value: `"<C-Space>"`.

### `g:ctrlspace_cyclic_list`

Determines if the list should be cyclic or not. The cyclic list means you will jump to the last item
if you continue to move up beyond the first one and vice-versa. You will jump to the first one if
you continue to move down after you reach the bottom of the list. Default value: `1`.

### `g:ctrlspace_max_jumps`

The size of jumps history. Each tab has its own jumps list (plus there is an extra one for all
buffers). Those lists are accessible via `p` and `n` keys. Their size will not exceed a number given
in that option. That means, the entries older than _n_ last jumps will be removed. Default
value: `100`.

### `g:ctrlspace_max_searches`

The size of search history. Each tab has its own search history available through `Ctrl + p` and
`Ctrl + n`. The search list size will not exceed the number given here. That means, the entries
older than _n_ last searches will be removed. Default value: `100`.

### `g:ctrlspace_default_sort_order`

The default sort order. `0` turns off sorting, `1` - the default sorting is chronological,
`2` - alphanumeric. Default value: `2`.

### `g:ctrlspace_use_ruby_bindings`

If set to `1`, the plugin will try to use your compiled in Ruby bindings to increase the speed of
fuzzy search algorithm. Regex operations are much faster in Ruby than in VimScript. Default value:
`1`.

### `g:ctrlspace_use_tabline`

Should **Vim-CtrlSpace** change your default tabline to its own? Default value: `1`.

### `g:ctrlspace_workspace_file`

This entry provides an array of strings with default names of workspaces file. If a name is preceded
with a directory, and that directory is found in the project root, that entry will be used.
Otherwise that would be the last one. In that way you can hide the workspaces file, for example, in
the repository directory. Default value: 

    [".git/cs_workspaces", ".svn/cs_workspaces", ".hg/cs_workspaces", 
    \ ".bzr/cs_workspaces", "CVS/cs_workspaces", ".cs_workspaces"]

### `g:ctrlspace_cache_dir`

A directory for the **Vim-CtrlSpace** cache file (`.cs_cache`). By default your `$HOME` directory
will be used. 

### `g:ctrlspace_project_root_markers`

An array of directory names which presence indicates the project root. If no marker is found, you
will be asked to confirm the project root basing on the current working directory. Make this
array empty to disable this functionality. Default value: `[".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"]`.

### `g:ctrlspace_unicode_font`

Set to `1` if you want to use Unicode symbols, or `0` otherwise. Default value: `1`.

### `g:ctrlspace_symbols`

Enables you to provide your own symbols. It's useful if for example your font doesn't contain
enough symbols or the glyphs are poorly rendered. Default value:

    if g:ctrlspace_unicode_font
      let g:ctrlspace_symbols = {
            \ "cs"      : "▢",
            \ "tab"     : "⊙",
            \ "all"     : "∷",
            \ "add"     : "○",
            \ "load"    : "⋮ → ∙",
            \ "save"    : "∙ → ⋮",
            \ "ord"     : "₁²₃",
            \ "abc"     : "авс",
            \ "prv"     : "⌕",
            \ "s_left"  : "›",
            \ "s_right" : "‹"
            \ }
    else
      let g:ctrlspace_symbols = {
            \ "cs"      : "CS",
            \ "tab"     : "TAB",
            \ "all"     : "ALL",
            \ "add"     : "ADD",
            \ "load"    : "LOAD",
            \ "save"    : "SAVE",
            \ "ord"     : "123",
            \ "abc"     : "ABC",
            \ "prv"     : "*",
            \ "s_left"  : "[",
            \ "s_right" : "]"
            \ }
    endif

Of course, you don't have to mind the `g:ctrlspace_unicode_font` settings anymore. Just provide one
array here.

### `g:ctrlspace_ignored_files`

The expression used to ignore some files during file collecting. It is used in addition to the
`wildignore` option in Vim (see `:help wildignore`). Default value: `'\v(tmp|temp)[\/]'`

### `g:ctrlspace_show_key_info`

Should the _key info help_ (toggled by `?`) be visible (`1`) by default or not (`0`).
Default value: `0`.

### `g:ctrlspace_search_timing`

Allows you to adjust search smoothness. Contains an array of two integer values. If the size of
the list is lower than the first value, that value will be used for search delay. Similarly, if
the size of the list is greater than the second value, then that value will be used for search
delay. In all other cases the delay will equal the list size. That way the plugin ensures smooth
search input behavior. Default value: `[50, 500]`

### Colors

The plugin allows you to define its colors entirely. By default it comes with pure black and white
color set. You are supposed to tweak its colors on your own (in the `.vimrc` file). This can be done
as shown below:

    hi CtrlSpaceSelected term=reverse ctermfg=187  ctermbg=23  cterm=bold
    hi CtrlSpaceNormal   term=NONE    ctermfg=244  ctermbg=232 cterm=NONE
    hi CtrlSpaceFound    ctermfg=220  ctermbg=NONE cterm=bold

The colors defined above can be seen in the demo movie. They fit well the
[Seoul256](https://github.com/junegunn/seoul256.vim) color scheme. Another useful example can be
found here:

    hi CtrlSpaceSelected term=reverse ctermfg=white ctermbg=black cterm=bold
    hi CtrlSpaceNormal   term=NONE    ctermfg=black ctermbg=228   cterm=NONE
    hi CtrlSpaceFound    ctermfg=125  ctermbg=NONE  cterm=bold

If you use a console Vim [that chart](http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html)
might be helpful.

API 
---

### Commands

At the moment **Vim-CtrlSpace** provides you 4 commands: `:CtrlSpace` and `:CtrlSpaceTabLabel`,
`:CtrlSpaceSaveWorkspace`, and `:CtrlSpaceLoadWorkspace`.

#### `:CtrlSpace`

Shows the plugin window. It is meant to be used in custom mappings or more sophisticated plugin
integration.

#### `:CtrlSpaceTabLabel`

Allows you to define a custom mapping (outside **Vim-CtrlSpace**) to change (or add/remove) a custom
tab name.

#### `:CtrlSpaceSaveWorkspace my workspace`

Saves the workspace with the given name.

#### `:CtrlSpaceLoadWorkspace my workspace`

Loads the workspace with the given name. It has also a banged version (`:CtrlSpaceLoadWorkspace! my
workspace`) which performs appending instead of loading.

### Functions

**Vim-CtrlSpace** provides you a couple of functions defined in the common `ctrlspace` namespace.
They can be used for custom status line integration, tabline integration, or just for more advanced
interactions with other plugins.

#### `ctrlspace#bufferlist(tabnr)`

Returns a directory of buffer number and name pairs for given tab. This is the content of the
internal buffer list belonging to the specified tab.

#### `ctrlspace#statusline_key_info_segment(...)`

Returns the info about available keys for the current plugin mode (toggled by `?`). It can take an
optional separator. It can be useful for a custom status line integration (i.e. in plugins like
[LightLine](https://github.com/itchyny/lightline.vim))

#### `ctrlspace#statusline_info_segment(...)`

Returns the info about the mode of the plugin. It can take an optional separator. It can be useful
for a custom status line integration (i.e. in plugins like
[LightLine](https://github.com/itchyny/lightline.vim))

#### `ctrlspace#tabline()`

Provides the custom tabline string.

Authors and License
-------------------

Copyright &copy; 2013 [Szymon Wrozynski and
Contributors](https://github.com/szw/vim-ctrlspace/commits/master). Licensed under [MIT
License](https://github.com/szw/vim-ctrlspace/blob/master/plugin/ctrlspace.vim#L5-L26) conditions.
**Vim-CtrlSpace** is based on Robert Lillack plugin [VIM
bufferlist](https://github.com/roblillack/vim-bufferlist) &copy; 2005 Robert Lillack. Moreover some
concepts of and inspiration has been taken from [Vim-Tabber](https://github.com/fweep/vim-tabber) by
Jim Steward and [Tabline](https://github.com/mkitt/tabline.vim) by Matthew Kitt.
