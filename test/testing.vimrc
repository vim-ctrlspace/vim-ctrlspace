"- Testing Vim Plugin Setup -"

"""-- vim options ---
filetype off
let &runtimepath .= ','.expand('<sfile>:p:h:h')
filetype plugin indent on
syntax enable
set nomore
set noswapfile
set viminfo=
set rtp+=.

"""--- Load all Plugins using plug.vim ---
let b:bundle_path = './vim/bundle'
let b:autoloaddir = './vim/autoload'

"""--- Automatic plug.vim installation ---
if empty(glob(b:autoloaddir.'/plug.vim'))
  let auld = system("mkdir -p ".b:autoloaddir)
  let purl = system("curl -fLo ".b:autoloaddir."/plug.vim ".
        \ "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim")
  au VimEnter * PlugInstall
endif

call plug#begin(b:bundle_path)


"""---- Plug: Vader Test ---
  Plug 'junegunn/vader.vim',    {'for': ['vader']}


"""---- Plug: CtrlSpace ---
  Plug 'ctrlspace/vim-ctrlspace'


"""---- Plug: vim-airline (CtrlSpace interaction) ---
  Plug 'vim-airline/vim-airline'            " status line definition
  let g:airline_extensions = ['ctrlspace']


"""-- Add plugins to &runtimepath ---
call plug#end()

"""-- modeline ---
" vim:fdm=expr:fdl=1:fde=getline(v\:lnum)=~'^""'?'>'.(matchend(getline(v\:lnum),'""*')-2)\:'='
