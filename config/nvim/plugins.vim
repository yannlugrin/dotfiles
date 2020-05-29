" check whether vim-plug is installed and install it if necessary
let plugpath = expand('~/.config/nvim'). '/autoload/plug.vim'
if !filereadable(plugpath)
    if executable('curl')
        let plugurl = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        call system('curl -fLo ' . shellescape(plugpath) . ' --create-dirs ' . plugurl)
        if v:shell_error
            echom "Error downloading vim-plug.Please install it manually.\n"
            exit
        endif
    else
        echom "vim-plug not installed. Please install it manually or install curl.\n"
        exit
    endif
endif

call plug#begin('~/.config/nvim/plugged')

"" Plugins

" Denite - Fuzzy finding, buffer management
Plug 'Shougo/denite.nvim'

" Colorscheme
Plug 'lifepillar/vim-solarized8'

" Auto Completion (Lauguage Server Protocol)
" Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': { -> coc#util#install() }}

" To autocomplate quote, brackets and more
Plug 'Raimondi/delimitMate'

" PHPActor
Plug 'phpactor/phpactor', {'for': 'php', 'do': 'composer install'}

" Have multiple cursors in edit mode
Plug 'kris89/vim-multiple-cursors'

" Easy toggle comments
Plug 'tpope/vim-commentary'

" Provides mappings to easily delete, change and add such surroundings in pairs
Plug 'tpope/vim-surround'

" Tmux and Vim integration
Plug 'christoomey/vim-tmux-navigator'

" Syntax
Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'
let g:polyglot_disabled = ['js', 'jsx']
Plug 'sheerun/vim-polyglot'
Plug 'prettier/vim-prettier', {'do': 'yarn install'}
Plug 'matthewbdaly/vim-filetype-settings'

" Editor Config
Plug 'editorconfig/editorconfig-vim'

" Initialize plugin system
call plug#end()
