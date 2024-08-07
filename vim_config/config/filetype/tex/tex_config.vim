inoremap $ $$<Left>
inoremap { {}<Left>
inoremap ( ()<Left>
inoremap [ []<Left>
setlocal conceallevel=0
" let g:tex_conceal = ''


let g:tex_flavor='latex'

let maplocalleader = "\<Space>"

let g:vimtex_latexmk_options = '-pdfdvi'
let g:tex_conceal = ''
let g:vimtex_imaps_enabled = 0
" viewer
let g:vimtex_view_general_viewer
\ = '/Applications/Skim.app/Contents/SharedSupport/displayline'
let g:vimtex_view_general_options = '@line @pdf @tex'

let g:vimtex_compiler_latexmk = {
      \ 'options' : [
      \   '-verbose',
      \   '-file-line-error',
      \   '-synctex=1',
      \   '-interaction=nonstopmode',
      \ ]}

if has('mac')
    let g:vimtex_view_method = 'skim'
endif

let g:vimtex_compiler_progname = 'nvr'
let g:vimtex_latexmk_options = '-pdfdvi'
let g:tex_conceal = ''
let g:vimtex_imaps_enabled = 0
" viewer
let g:vimtex_view_general_viewer
\ = '/Applications/Skim.app/Contents/SharedSupport/displayline'
let g:vimtex_view_general_options = '@line @pdf @tex'

let g:vimtex_compiler_latexmk = {
      \ 'options' : [
      \   '-verbose',
      \   '-file-line-error',
      \   '-synctex=1',
      \   '-interaction=nonstopmode',
      \ ]}

let g:vimtex_compiler_progname = 'nvr'

call deoplete#custom#source('omni', 'input_patterns',{'tex':'\\cite{\s*[0-9A-Za-z_:]*|\\ref{\s*[0-9A-Za-z_:]'})

