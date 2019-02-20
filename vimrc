set encoding=utf-8
set nocompatible

"" Leader
let mapleader = ","

"" Backup
set nobackup
set nowritebackup
set swapfile
set directory^=~/.vim/swap//                  " where to put swap files.

"" Load plugins bundle
if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

"" Match filetype
filetype plugin indent on

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

autocmd BufWritePre * :%s/\s\+$//e            " remove trailling space

"" Select lines after ident
vnoremap > >gv
vnoremap < <gv

"" Searching
set hlsearch                                  " highlight matches
set incsearch                                 " incremental searching
set ignorecase                                " searches are case insensitive...
set smartcase                                 " ... unless they contain at least one capital letter
nnoremap <CR> :nohlsearch<CR>                 " clear the search buffer when hitting return

"" Past
set pastetoggle=<F2>

"" Color scheme
set background=dark
let g:solarized_termcolors=256
colorscheme solarized

"" Command-T
let g:CommandTAcceptSelectionSplitMap = ['<C-c>']
let g:CommandTCancelMap = ['<C-x>']
let g:CommandTWildIgnore=&wildignore
let g:CommandTWildIgnore.=',*/.git'
let g:CommandTWildIgnore.=',*/bower_components'
let g:CommandTWildIgnore.=',*/node_modules'
let g:CommandTWildIgnore.=',*/vendor'
let g:CommandTWildIgnore.=',*/tmp'
let g:CommandTWildIgnore.=',*/web/core'
let g:CommandTScanDotDirectories = 1
let g:CommandTAlwaysShowDotFiles = 1

nnoremap <silent> <Leader>m :CommandT web/modules/custom<CR>

"" vim-commenting
autocmd FileType php setlocal commentstring=//\ %s

"" Vimux
let g:VimuxRunnerType     = 'pane'
let g:VimuxUseNearest     = 1
let g:VimuxOrientation    = 'v'
let g:VimuxHeight         = '20'

"" UltiSnips
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-e>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

"" PHPActor
" Include use statement
nmap <Leader>u :call phpactor#UseAdd()<CR>
" Invoke the context menu
nmap <Leader>mm :call phpactor#ContextMenu()<CR>

"" ToggleMovement, to toggle 2 mapping
function! ToggleMovement(firstOp, thenOp)
  let pos = getpos('.')
  execute "normal! " . a:firstOp
  if pos == getpos('.')
    execute "normal! " . a:thenOp
  endif
endfunction

" The original carat 0 swap
nnoremap <silent> 0 :call ToggleMovement('^', '0')<CR>

" How about ; and ,
nnoremap <silent> ; :call ToggleMovement(';', ',')<CR>
nnoremap <silent> , :call ToggleMovement(',', ';')<CR>

" How about H and L
nnoremap <silent> H :call ToggleMovement('H', 'L')<CR>
nnoremap <silent> L :call ToggleMovement('L', 'H')<CR>

" How about G and gg
nnoremap <silent> G :call ToggleMovement('G', 'gg')<CR>
nnoremap <silent> gg :call ToggleMovement('gg', 'G')<CR>

"" read custom project config
let b:projectDir=expand("%:p:h")
let b:homeDir=expand('<sfile>:p:h')

while 1
  if filereadable(b:projectDir.'/.vimrc')
    execute "source ".b:projectDir.'/.vimrc'
    break
  endif

  let b:projectDir=fnamemodify(b:projectDir, ':h')
  if b:projectDir==b:homeDir
    break
  endif
endwhile
