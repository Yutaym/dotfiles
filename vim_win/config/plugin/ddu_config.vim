let mapleader = " "

"===================================
" Ddu
"===================================

let win_border = 'rounded'
let win_height = '&lines - 3'
let win_width = '&columns / 2 - 3'
let win_col = 1
let win_row = 0
let preview_row = 3
let preview_col = '&columns / 2'

call ddu#custom#patch_global({
\	'ui': 'ff',
\	'uiParams': {
\		'ff': {
\			'ignoreEmpty': v:true,
\			'split': 'floating',
\			'startAutoAction': v:true,
\			'autoAction': { 'name': 'preview', 'delay': 0, },
\			'prompt': '> ',
\			'startFilter': v:true,
\			'filterSplitDirection': 'floating',
\			'filterFloatingPosition': 'top',
\			'floatingBorder': win_border,
\			'winHeight': win_height,
\			'winWidth': win_width,
\			'winRow': win_row,
\			'winCol': win_col,
\			'previewFloating': v:true,
\			'previewFloatingBorder': win_border,
\			'previewHeight': win_height,
\			'previewWidth': win_width,
\			'previewRow': preview_row,
\			'previewCol': preview_col,
\		},
\		'filer': {
\			'split': 'floating',
\			'floatingBorder': win_border,
\			'winHeight': win_height,
\			'winWidth': win_width,
\			'winRow': win_row,
\			'winCol': win_col,
\			'previewFloating': v:true,
\			'previewFloatingBorder': win_border,
\			'previewHeight': win_height,
\			'previewWidth': win_width,
\			'previewRow': preview_row,
\			'previewCol': preview_col,
\		},
\	},
\	'sourceOptions': {
\		'_': {
\			'matchers': ['matcher_fzf'],
\			'sorters': ['sorter_fzf'],
\			'ignoreCase': v:true,
\		},
\		'file': {
\			'columns': ['icon_filename'],
\		},
\		'line': {
\			'sorters': [],
\		},
\	},
\	'filterParams': {
\		'matcher_fzf': {
\			'highlightMatched': 'Search',
\		},
\	},
\	'kindOptions': {
\		'file': {
\			'defaultAction': 'open',
\		},
\		'word': {
\			'defaultAction': 'append',
\		},
\	},
\	'actionOptions': {
\		'narrow': {
\			'quit': v:true,
\		},
\	},
\})

call ddu#custom#patch_local('file_rec', {
\	'sources': [{
\		'name':'file_rec',
\		'params': {
\			'ignoredDirectories': ['.git', 'var', 'node_modules', ]
\		},
\	}],
\})

call ddu#custom#patch_local('filer', {
\	'ui': 'filer',
\	'sources': [
\		{'name': 'file', 'params': {}},
\	],
\	'resume': v:true,
\ })

call ddu#custom#patch_local('grep', {
\	'sourceParams' : {
\		'rg' : {
\			'args': ['--column', '--no-heading', '--color', 'never', '-i'],
\		},
\	 },
\	'uiParams': {
\		'ff': {
\			'startFilter': v:false,
\		 }
\	 },
\	'resume': v:true,
\ })

nnoremap <Space>ub <Cmd>Ddu buffer -ui-param-ff-startFilter=v:false<CR>
nnoremap <Space>uo <Cmd>Ddu line<CR>
nnoremap <Space>ur <Cmd>Ddu register -ui-param-ff-startFilter=v:false<CR>
nnoremap <Space>uf <Cmd>Ddu -name=file_rec<CR>
nnoremap <Space>ue <Cmd>Ddu -name=filer<CR>

nnoremap <Space>ug <Cmd>Ddu rg -name=grep -source-param-rg-input='`'Pattern: '->input('<cword>'->expand())`'<CR>
nnoremap <C-g> <Cmd>Ddu -name=grep<CR>
nnoremap <C-n> <Cmd>call ddu#ui#multi_actions(['cursorNext', 'itemAction'], 'grep')<CR>
nnoremap <C-p> <Cmd>call ddu#ui#multi_actions(['cursorPrevious', 'itemAction'], 'grep')<CR>

"--------------------
" FF
"--------------------
autocmd FileType ddu-ff call s:ddu_ff_settings()
function! s:ddu_ff_settings() abort
	nnoremap <buffer><silent> <CR> <Cmd>call ddu#ui#do_action('itemAction')<CR>
	nnoremap <buffer><silent> s <Cmd>call ddu#ui#do_action('toggleSelectItem')<CR>
	nnoremap <buffer><silent> i <Cmd>call ddu#ui#do_action('openFilterWindow')<CR>
	nnoremap <buffer><silent> q <Cmd>call ddu#ui#do_action('quit')<CR>
	nnoremap <buffer><silent> <C-g> <Cmd>call ddu#ui#do_action('quit')<CR>
endfunction
autocmd FileType ddu-ff-filter call s:ddu_filter_my_settings()
function! s:ddu_filter_my_settings() abort
	inoremap <buffer> <C-n> <Nop>
	inoremap <buffer> <C-p> <Nop>
	nnoremap <buffer> <CR> :q<CR>
	nnoremap <buffer> q :q<CR>
	inoremap <buffer> <CR> <ESC>:q<CR>
	inoremap <buffer> jj <ESC>:q<CR>
	inoremap <buffer> jk <ESC>:q<CR>
	inoremap <buffer> kj <ESC>:q<CR>
	inoremap <buffer> kk <ESC>:q<CR>
endfunction

"--------------------
" Filer
"--------------------
autocmd FileType ddu-filer call s:ddu_filer_my_settings()
function! s:ddu_filer_my_settings() abort
	nnoremap <buffer><silent><expr> <CR>
	\	ddu#ui#get_item()->get('isTree', v:false) ?
	\		"<Cmd>call ddu#ui#filer#do_action('expandItem', {'mode': 'toggle'})<CR>" :
	\		"<Cmd>call ddu#ui#filer#do_action('itemAction')<CR>"
	nnoremap <buffer><silent><expr> h
	\	ddu#ui#get_item()->get('isTree', v:false) ?
	\		"<Cmd>call ddu#ui#filer#do_action('collapseItem')<CR>" :
	\		"<Cmd>call ddu#ui#filer#do_action('preview')<CR>"
	nnoremap <buffer><silent><expr> l
	\	ddu#ui#get_item()->get('isTree', v:false) ?
	\		"<Cmd>call ddu#ui#filer#do_action('expandItem')<CR>" :
	\		"<Cmd>call ddu#ui#filer#do_action('preview')<CR>"
	nnoremap <buffer><silent> j j<Cmd>call ddu#ui#do_action('preview')<CR>
	nnoremap <buffer><silent> k k<Cmd>cal ddu#ui#do_action('preview')<CR>
	nnoremap <buffer><silent> <C-d> <C-d><Cmd>cal ddu#ui#do_action('preview')<CR>
	nnoremap <buffer><silent> <C-u> <C-u><Cmd>cal ddu#ui#do_action('preview')<CR>
	nnoremap <buffer><silent> q <Cmd>call ddu#ui#do_action('quit')<CR>
	nnoremap <buffer><silent> cp <Cmd>call ddu#ui#do_action('itemAction', {'name': 'copy'})<CR>
	nnoremap <buffer><silent> p <Cmd>call ddu#ui#do_action('itemAction', {'name': 'paste'})<CR>
	nnoremap <buffer><silent> rm <Cmd>call ddu#ui#do_action('itemAction', {'name': 'delete'})<CR>
	nnoremap <buffer><silent> mv <Cmd>call ddu#ui#do_action('itemAction', {'name': 'rename'})<CR>
	nnoremap <buffer><silent> cu <Cmd>call ddu#ui#do_action('itemAction', {'name': 'move'})<CR>
	nnoremap <buffer><silent> to <Cmd>call ddu#ui#do_action('itemAction', {'name': 'newFile'})<CR>
	nnoremap <buffer><silent> mk <Cmd>call ddu#ui#do_action('itemAction', {'name': 'newDirectory'})<CR>
	nnoremap <buffer><silent> yy <Cmd>call ddu#ui#do_action('itemAction', {'name': 'yank'})<CR>
endfunction