" Light Vim Kit -- classic Vim 8.2+; a full Vim 9.x build is recommended.
" Install as ~/.vimrc (Unix) or ~/_vimrc (Windows).
" Personal changes belong in ~/.vimrc.local; installers preserve that file.
scriptencoding utf-8
set nocompatible

if !has('eval') || !has('syntax') || !has('packages')
  echoerr 'Light Vim Kit needs a full Vim build (+eval +syntax +packages).'
  finish
endif
if v:version < 802
  echoerr 'Light Vim Kit needs Vim 8.2 or newer.'
  finish
endif

let mapleader = ' '
let maplocalleader = ','
let s:vimdir = expand(has('win32') || has('win64') ? '~/vimfiles' : '~/.vim')
let s:vimdir = substitute(s:vimdir, '\\', '/', 'g')
let s:state = s:vimdir . '/lightvim-state'

" Editing: keep file encodings/line endings detected by Vim.
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,default,latin1
set fileformats=unix,dos,mac
set hidden
set autoread
set backspace=indent,eol,start
set autoindent
set expandtab shiftwidth=4 softtabstop=-1 tabstop=8
set nrformats=bin,hex
set noexrc nomodeline
let g:sleuth_modelines = 0

" Plain, quiet UI; no icon font is required.
set number norelativenumber
set cursorline
set nowrap
set scrolloff=5 sidescrolloff=8
set splitbelow splitright
set laststatus=2
set showmode showcmd
set noshowmatch
set shortmess+=I
set visualbell t_vb=
set mouse=
set timeout timeoutlen=700
set ttimeout ttimeoutlen=100
set updatetime=500
set foldmethod=manual foldlevelstart=99
set synmaxcol=240
set listchars=tab:>-,trail:.,extends:>,precedes:<
set nolist
set statusline=\ %f%m%r%h\ %=%y\ %{&fileencoding==#''?&encoding:&fileencoding}[%{&fileformat}]\ %l:%c\ %p%%\ 
if has('gui_running')
  set guioptions-=T
  set guioptions-=m
  set guioptions-=r
  set guioptions-=L
endif

" Search and completion use Vim itself; no background language process.
set ignorecase smartcase incsearch hlsearch
set wildmenu
set wildmode=longest:full,full
set wildignore+=*.o,*.obj,*.pyc,*.class,*/.git/*,*/node_modules/*,*/target/*,*/__pycache__/*
set complete=.,w,b,t
set completeopt=menuone,noselect,noinsert
set tags=./tags;,tags

" State stays outside source trees. A write-protected home remains usable.
set nobackup writebackup backupcopy=auto
try
  for s:subdir in ['undo', 'swap', 'backup']
    call mkdir(s:state . '/' . s:subdir, 'p', 0700)
  endfor
  let &directory = escape(s:state . '/swap//', ',')
  let &backupdir = escape(s:state . '/backup//', ',')
  if has('persistent_undo')
    let &undodir = escape(s:state . '/undo//', ',')
    set undofile
  endif
catch
  if has('persistent_undo')
    set noundofile
  endif
  echom 'Light Vim: state directory unavailable; persistent undo is disabled.'
endtry

" Netrw is Vim's bundled file explorer.
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
let g:netrw_browse_split = 4

" Set defaults before native packages load, so Sleuth/EditorConfig can win.
filetype plugin indent on
syntax enable

function! s:Indent(width, spaces) abort
  let &l:shiftwidth = a:width
  let &l:softtabstop = -1
  let &l:tabstop = 8
  let &l:expandtab = a:spaces
endfunction

function! s:MarkLargeFile(path) abort
  let l:limit = get(g:, 'lightvim_large_file_bytes', 2 * 1024 * 1024)
  let b:lightvim_large_file = l:limit > 0 && getfsize(a:path) > l:limit
  if b:lightvim_large_file
    let b:sleuth_automatic = 0
  endif
endfunction

function! s:FinishRead() abort
  if get(b:, 'lightvim_large_file', 0)
    setlocal syntax=OFF foldmethod=manual
  endif
  " Restore the last cursor location, but do not interfere with Git messages.
  if &filetype !~# '^\%(gitcommit\|gitrebase\)$' && line("'\"") > 1
        \ && line("'\"") <= line('$')
    execute "normal! g`\""
  endif
endfunction

augroup LightVim
  autocmd!
  autocmd FileType c,cpp,cs,rust,python call <SID>Indent(4, 1)
  autocmd FileType javascript,javascriptreact,typescript,typescriptreact,json,jsonc,html,css,scss,yaml call <SID>Indent(2, 1)
  autocmd FileType go call <SID>Indent(8, 0)
  autocmd FileType make setlocal noexpandtab tabstop=8 shiftwidth=8 softtabstop=0
  autocmd FileType * setlocal formatoptions-=o
  autocmd BufReadPre * call <SID>MarkLargeFile(expand('<afile>'))
  autocmd BufReadPost * call <SID>FinishRead()
  autocmd FocusGained,BufEnter * if mode() !~# '[cR!t]' | checktime | endif
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l* lwindow
augroup END

" The optional ripgrep executable is used only when :grep is requested.
if executable('rg')
  let &grepprg = 'rg --vimgrep --smart-case --glob "!node_modules" --glob "!target" --glob "!bin" --glob "!obj" --glob "!build" --glob "!dist" --'
  set grepformat=%f:%l:%c:%m
endif

" Common editing, buffers and windows. Ctrl-6 keeps Vim's default behavior.
nnoremap <Space> <Nop>
nnoremap <silent> <leader>w :update<CR>
nnoremap <silent> <leader>q :close<CR>
nnoremap <silent> <leader>e :Lexplore<CR>
nnoremap <leader>f :edit<Space>
nnoremap <leader>b :ls<CR>:buffer<Space>
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> <leader><leader> <C-^>
nnoremap <silent> <leader>d :bdelete<CR>
nnoremap <silent> <leader>h :nohlsearch<CR>
nnoremap <leader>/ :grep<Space>
nnoremap <silent> <leader>co :copen<CR>
nnoremap <silent> <leader>cc :cclose<CR>
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> <leader>gs :Git<CR>
nnoremap <silent> <leader>gd :Gdiffsplit<CR>
nnoremap <silent> <leader>rn :set relativenumber!<CR>
nnoremap <silent> <leader>tw :setlocal wrap!<CR>
nnoremap <silent> <leader>tl :setlocal list!<CR>
nnoremap <silent> <leader>v :vsplit<CR>
nnoremap <silent> <leader>s :split<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
xnoremap < <gv
xnoremap > >gv
if has('clipboard')
  nnoremap <leader>y "+y
  xnoremap <leader>y "+y
  nnoremap <leader>p "+p
endif

" True color is enabled only with an advertised capable terminal or GUI.
" Windows Terminal, modern Kitty/WezTerm/Ghostty and most local terminals work.
if has('termguicolors') && (has('gui_running')
      \ || $COLORTERM =~? 'truecolor\|24bit'
      \ || !empty($WT_SESSION)
      \ || $TERM =~? 'direct\|truecolor\|kitty')
  set termguicolors
endif
set background=light
let g:everforest_background = get(g:, 'everforest_background', 'soft')
let g:everforest_better_performance = 1
let g:everforest_enable_italic = 0
let g:everforest_disable_italic_comment = 1
let g:everforest_transparent_background = 0
let g:everforest_ui_contrast = 'high'

" Native packages are not all on runtimepath while vimrc is being sourced.
if !empty(globpath(&packpath, 'pack/*/start/everforest'))
      \ || !empty(globpath(&packpath, 'pack/*/opt/everforest'))
  packadd! everforest
endif
if !empty(globpath(&runtimepath, 'colors/everforest.vim'))
  colorscheme everforest
else
  " Warm light fallback, also usable after --no-plugins installation.
  colorscheme default
  highlight Normal guifg=#4b5652 guibg=#f3ead3 ctermfg=239 ctermbg=230
  highlight NonText guifg=#a6b0a0 guibg=#f3ead3 ctermfg=248 ctermbg=230
  highlight LineNr guifg=#8b9385 guibg=#ede5d0 ctermfg=245 ctermbg=230
  highlight CursorLine guibg=#e7dfc6 ctermbg=187 cterm=NONE
  highlight CursorLineNr guifg=#6b7753 guibg=#e7dfc6 ctermfg=65 ctermbg=187
  highlight StatusLine guifg=#4b5652 guibg=#ded7bf ctermfg=239 ctermbg=187 gui=NONE cterm=NONE
  highlight StatusLineNC guifg=#858b80 guibg=#ede5d0 ctermfg=245 ctermbg=230 gui=NONE cterm=NONE
  highlight Visual guibg=#dce0c3 ctermbg=187
  highlight Search guifg=#4b5652 guibg=#e9d8a6 ctermfg=239 ctermbg=223
  highlight Comment guifg=#7c8375 ctermfg=243 gui=NONE cterm=NONE
endif

function! s:Health() abort
  echo 'Light Vim Kit health'
  echo split(execute('version'), "\n")[0]
  echo 'Config: ' . $MYVIMRC
  echo 'Theme: ' . get(g:, 'colors_name', '(unset)') . ' / ' . &background
  echo 'True color: ' . (exists('+termguicolors') && &termguicolors ? 'on' : 'off')
  echo 'Persistent undo: ' . (has('persistent_undo') && &undofile ? 'on' : 'off')
  echo 'Clipboard: ' . (has('clipboard') ? 'available' : 'use terminal copy/paste')
  for l:tool in ['git', 'rg', 'ctags']
    echo l:tool . ': ' . (executable(l:tool) ? exepath(l:tool) : 'not installed (optional at runtime)')
  endfor
  for l:plugin in ['vim-commentary', 'vim-surround', 'vim-repeat', 'vim-fugitive', 'vim-sleuth', 'everforest']
    echo l:plugin . ': ' . (isdirectory(s:vimdir . '/pack/lightvim/start/' . l:plugin) ? 'installed' : 'not installed')
  endfor
  echo 'Filetype=' . &filetype . ' shiftwidth=' . shiftwidth() . ' expandtab=' . &expandtab
  echo 'Language support: syntax, indent, word completion and optional tags; no LSP configured.'
endfunction
command! LightVimHealth call <SID>Health()

" Keep personal settings separate from this replaceable, installer-managed file.
if filereadable(expand('~/.vimrc.local'))
  execute 'source ' . fnameescape(expand('~/.vimrc.local'))
endif
