set encoding=utf-8
source ~/.config/nvim/plugins.vim

" ============================================================================ "
" ===                           BASIC SETUP                                === "
" ============================================================================ "
syntax enable                                   " syntax highlighting on
set relativenumber                              " show relative numbers
set numberwidth=5                               " width of number display column
set ruler                                       " show the cursor position all the time
set cursorline                                  " highlight cursor line
set clipboard^=unnamed,unnamedplus              " Use system clipboard
set timeoutlen=500

" Status line
set laststatus=2                                " always show the status bar
set statusline=%f\ %m\ %r                       " filename / modified flag / readonly fla
set statusline+=\ Line:%l/%L                    " line number
set statusline+=\ Col:%v                        " column number

" Whitespace
set nowrap                                    " don't wrap lines
set tabstop=2                                 " a tab is two spaces
set shiftwidth=2                              " an autoindent (with <<) is two spaces
set expandtab                                 " use spaces, not tabs
set list                                      " Show invisible characters
set list listchars=tab:»·,trail:·             " Reset tje listchars
autocmd BufWritePre * :%s/\s\+$//e            " remove trailling space

" Select lines after ident
vnoremap > >gv
vnoremap < <gv

" Searching
set hlsearch                                  " highlight matches
set incsearch                                 " incremental searching
set ignorecase                                " searches are case insensitive...
set smartcase                                 " ... unless they contain at least one capital letter
nnoremap <CR> :nohlsearch<CR>                 " clear the search buffer when hitting return

" Mapping
let g:mapleader=','                             " Remap leader key to ,

nnoremap <C-j> <Down>                           " Remap <C-j> to move cursor down
nnoremap <C-k> <Up>                             " Remap <C-k> to move cusor up

" ============================================================================ "
" ===                           PLUGIN SETUP                               === "
" ============================================================================ "
" Can be wrapped in try/catch to avoid errors on initial install before
" plugin is available

" === Solarized color scheme === "
try

" Black backrounf and standard solarized contrast
set background=dark
colorscheme solarized8

catch
  echo 'Solarized not installed. It should work after running :PlugInstall'
endtry

" === Denite setup ==="
try
" Use ripgrep for searching current directory for files
" By default, ripgrep will respect rules in .gitignore
"   --files: Print each file that would be searched (but don't search)
"   --glob:  Include or exclues files for searching that match the given glob
"            (aka ignore .git files)
"
call denite#custom#var('file/rec', 'command', ['rg', '--hidden', '--files', '--glob', '!.git'])

" Use ripgrep in place of "grep"
call denite#custom#var('grep', 'command', ['rg'])

" Custom options for ripgrep
"   --vimgrep:  Show results with every match on it's own line
"   --hidden:   Search hidden directories and files
"   --heading:  Show the file name above clusters of matches from each file
"   --S:        Search case insensitively if the pattern is all lowercase
call denite#custom#var('grep', 'default_opts', ['--hidden', '--vimgrep', '--heading', '-S'])

" Recommended defaults for ripgrep via Denite docs
call denite#custom#var('grep', 'recursive_opts', [])
call denite#custom#var('grep', 'pattern_opt', ['--regexp'])
call denite#custom#var('grep', 'separator', ['--'])
call denite#custom#var('grep', 'final_opts', [])

" Remove date from buffer list
call denite#custom#var('buffer', 'date_format', '')

" Open file commands
call denite#custom#map('insert,normal', "<C-t>", '<denite:do_action:tabopen>')
call denite#custom#map('insert,normal', "<C-v>", '<denite:do_action:vsplit>')
call denite#custom#map('insert,normal', "<C-h>", '<denite:do_action:split>')

" Custom options for Denite
"   auto_resize             - Auto resize the Denite window height automatically.
"   prompt                  - Customize denite prompt
"   direction               - Specify Denite window direction as directly below current pane
"   winminheight            - Specify min height for Denite window
"   highlight_mode_insert   - Specify h1-CursorLine in insert mode
"   prompt_highlight        - Specify color of prompt
"   highlight_matched_char  - Matched characters highlight
"   highlight_matched_range - matched range highlight
let s:denite_options = {'default' : {
\ 'split': 'horizontal',
\ 'start_filter': 1,
\ 'auto_resize': 1,
\ 'source_names': 'short',
\ 'prompt': 'λ:',
\ 'statusline': 0,
\ 'highlight_mode_insert': 'Visual',
\ 'highlight_mode_normal': 'Visual',
\ 'highlight_matched_char': 'Function',
\ 'highlight_matched_range': 'Normal',
\ 'winrow': 1,
\ 'vertical_preview': 1
\ }}

" Loop through denite options and enable them
function! s:profile(opts) abort
  for l:fname in keys(a:opts)
    for l:dopt in keys(a:opts[l:fname])
      call denite#custom#option(l:fname, l:dopt, a:opts[l:fname][l:dopt])
    endfor
  endfor
endfunction

call s:profile(s:denite_options)

" Denite shorcuts
"   ;         - Browser currently open buffers
"   <leader>t - Browse list of files in current directory
"   <leader>g - Search current directory for occurences of given term and close window if no results
"   <leader>j - Search current directory for occurences of word under cursor
nmap ; :Denite buffer<CR>
nmap <leader>t :DeniteProjectDir file/rec<CR>
nnoremap <leader>g :<C-u>Denite grep:. -no-empty<CR>
nnoremap <leader>j :<C-u>DeniteCursorWord grep:.<CR>

" Define mappings while in 'filter' mode
"   <C-o>           - Switch to normal mode inside of search results
"   <C-j> or <Down> - Select next file in list
"   <C-k> or <Up>   - Select previous file in list
"   <C-x> or <Esc>  - Exit denite window in any mode
"   <CR>            - Open currently selected file
"   <C-v>           - Opens currently selected file in vertical split
"   <C-h>           - Opens currently selected file in horizontal split
autocmd FileType denite-filter call s:denite_filter_my_settings()
function! s:denite_filter_my_settings() abort
  imap <silent><buffer> <C-o>
  \ <Plug>(denite_filter_quit)
  inoremap <silent><buffer><expr> <Esc>
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> <Esc>
  \ denite#do_map('quit')
  inoremap <silent><buffer><expr> <C-x>
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> <C-x>
  \ denite#do_map('quit')
  inoremap <silent><buffer><expr> <CR>
  \ denite#do_map('do_action')
  inoremap <silent><buffer><expr> <C-v>
  \ denite#do_map('do_action', 'vsplit')
  inoremap <silent><buffer><expr> <C-h>
  \ denite#do_map('do_action', 'split')
  inoremap <silent><buffer> <Down>
  \ <Esc><C-w>p:call cursor(line('.')+1,0)<CR><C-w>pA
  inoremap <silent><buffer> <C-j>
  \ <Esc><C-w>p:call cursor(line('.')+1,0)<CR><C-w>pA
  inoremap <silent><buffer> <Up>
  \ <Esc><C-w>p:call cursor(line('.')-1,0)<CR><C-w>pA
  inoremap <silent><buffer> <C-k>
  \ <Esc><C-w>p:call cursor(line('.')-1,0)<CR><C-w>pA
endfunction

" Define mappings while in denite window
"   <CR>        - Opens currently selected file
"   v           - Opens currently selected file in vertical split
"   h           - Opens currently selected file in horizontal split
"   x or <Esc>  - Quit Denite window
"   d           - Delete currenly selected file
"   p           - Preview currently selected file
"   <C-o> or i  - Switch to insert mode inside of filter prompt
autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
  nnoremap <silent><buffer><expr> <CR>
  \ denite#do_map('do_action')
  nnoremap <silent><buffer><expr> v
  \ denite#do_map('do_action', 'vsplit')
  nnoremap <silent><buffer><expr> h
  \ denite#do_map('do_action', 'split')
  nnoremap <silent><buffer><expr> x
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> <C-x>
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> <Esc>
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> d
  \ denite#do_map('do_action', 'delete')
  nnoremap <silent><buffer><expr> p
  \ denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> i
  \ denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <C-o>
  \ denite#do_map('open_filter_buffer')
endfunction
catch
  echo 'Denite not installed. It should work after running :PlugInstall'
endtry

" === Coc.nvim === "
" use <tab> for trigger completion and navigate to next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

"Close preview window when completion is done.
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" === PHPActor === "
" Include use statement
" Invoke the context menu
" Invoke the navigation menu
" Goto definition of class or class member under the cursor
nmap <Leader>u :call phpactor#UseAdd()<CR>
nmap <Leader>mm :call phpactor#ContextMenu()<CR>
nmap <Leader>nn :call phpactor#Navigate()<CR>
nmap <Leader>o :call phpactor#GotoDefinition()<CR>
