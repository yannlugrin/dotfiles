set nocompatible

"" Leader
let mapleader = ","

"" Backup
set nobackup
set nowritebackup
set swapfile
set directory=~/.vim/swap                     " where to put swap files.

"" Load plugins bundle
if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

"" Basic styles
syntax enable                                 " syntax highlighting on
set number                                    " show line number
set numberwidth=5
set ruler                                     " show the cursor position all the time
set showcmd                                   " display incomplete commands
set cursorline                                " highlight cursor line

"" Status line
set laststatus=2                              " always show the status bar
set statusline=%f\ %m\ %r                     " filename / modified flag / readonly fla
set statusline+=\ Line:%l/%L[%p%%]            " line number
set statusline+=\ Col:%v                      " column number

"" Whitespace
set nowrap                                    " don't wrap lines
set tabstop=2                                 " a tab is two spaces
set shiftwidth=2                              " an autoindent (with <<) is two spaces
set shiftround                                " Round indent to multiple of shiftwidth
set expandtab                                 " use spaces, not tabs
set list                                      " Show invisible characters
set backspace=indent,eol,start                " backspace through everything in insert mode
set list listchars=tab:»·,trail:·             " Reset tje listchars

"" Color scheme
set background=dark
let g:solarized_termcolors=256
colorscheme solarized

"" Match filetype
filetype plugin indent on

