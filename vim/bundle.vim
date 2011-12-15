filetype on                                   " required by OSX before disable it
filetype off                                  " required by Vundle plumbing
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'

Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-rails'
Bundle 'vim-ruby/vim-ruby'
Bundle 'cakebaker/scss-syntax.vim'
Bundle 'tpope/vim-markdown'
Bundle 'pangloss/vim-javascript'
Bundle 'wincent/Command-T'
Bundle 'scrooloose/nerdtree'
Bundle 'tpope/vim-commentary'
Bundle 'altercation/vim-colors-solarized'
Bundle 'tpope/vim-repeat'
Bundle 'tpope/vim-endwise'

filetype plugin indent on                     " automatically detect file types -  shoulb be overided in vimrc
