filetype on                                   " required by OSX before disable it
filetype off                                  " required by Vundle plumbing
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'

Bundle 'vim-ruby/vim-ruby'
Bundle 'tpope/vim-rails'
Bundle 'tpope/vim-rake'
Bundle 'tpope/vim-bundler'

Bundle 'cakebaker/scss-syntax.vim'
Bundle 'pangloss/vim-javascript'

Bundle 'mattn/zencoding-vim'

Bundle 'tpope/vim-markdown'

Bundle 'tpope/vim-git'
Bundle 'tpope/vim-fugitive'

Bundle 'edsono/vim-matchit'
Bundle 'kana/vim-textobj-user'
Bundle 'nelstrom/vim-textobj-rubyblock'

Bundle 'mileszs/ack.vim'

Bundle 'wincent/Command-T'
Bundle 'scrooloose/nerdtree'
Bundle 'tpope/vim-commentary'
Bundle 'tpope/vim-repeat'
Bundle 'tpope/vim-endwise'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-unimpaired'
Bundle 'Raimondi/delimitMate'
Bundle 'ervandew/supertab'
Bundle 'vim-scripts/YankRing.vim'

Bundle 'MarcWeber/vim-addon-mw-utils'
Bundle 'tomtom/tlib_vim'
Bundle 'garbas/vim-snipmate'

Bundle 'altercation/vim-colors-solarized'

filetype plugin indent on                     " automatically detect file types -  shoulb be overided in vimrc
