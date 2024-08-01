nnoremap <silent> <Space>mp     :<C-u>FzfPreviewFromResources project_mru git<CR>
nnoremap <silent> <Space>mgs    :<C-u>FzfPreviewGitStatus<CR>
nnoremap <silent> <Space>mga    :<C-u>FzfPreviewGitActions<CR>
nnoremap <silent> <Space>mb     :<C-u>FzfPreviewBuffers<CR>
nnoremap <silent> <Space>mB     :<C-u>FzfPreviewAllBuffers<CR>
nnoremap <silent> <Space>mo     :<C-u>FzfPreviewFromResources buffer project_mru<CR>
nnoremap <silent> <Space>m<C-o> :<C-u>FzfPreviewJumps<CR>
nnoremap <silent> <Space>mg;    :<C-u>FzfPreviewChanges<CR>
nnoremap <silent> <Space>m/     :<C-u>FzfPreviewLines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'"<CR>
nnoremap <silent> <Space>m*     :<C-u>FzfPreviewLines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'<C-r>=expand('<cword>')<CR>"<CR>
nnoremap          <Space>mgr    :<C-u>FzfPreviewProjectGrep<Space>
xnoremap          <Space>mgr    "sy:FzfPreviewProjectGrep<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"
nnoremap <silent> <Space>mt     :<C-u>FzfPreviewBufferTags<CR>
nnoremap <silent> <Space>mq     :<C-u>FzfPreviewQuickFix<CR>
nnoremap <silent> <Space>ml     :<C-u>FzfPreviewLocationList<CR>

"
" nnoremap <silent> <Space>mp     :<C-u>CocCommand fzf-preview.FromResources project_mru git<CR>
" nnoremap <silent> <Space>mgs    :<C-u>CocCommand fzf-preview.GitStatus<CR>
" nnoremap <silent> <Space>mga    :<C-u>CocCommand fzf-preview.GitActions<CR>
" nnoremap <silent> <Space>mb     :<C-u>CocCommand fzf-preview.Buffers<CR>
" nnoremap <silent> <Space>mB     :<C-u>CocCommand fzf-preview.AllBuffers<CR>
" nnoremap <silent> <Space>mo     :<C-u>CocCommand fzf-preview.FromResources buffer project_mru<CR>
" nnoremap <silent> <Space>m<C-o> :<C-u>CocCommand fzf-preview.Jumps<CR>
" nnoremap <silent> <Space>mg;    :<C-u>CocCommand fzf-preview.Changes<CR>
" nnoremap <silent> <Space>m/     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'"<CR>
" nnoremap <silent> <Space>m*     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'<C-r>=expand('<cword>')<CR>"<CR>
" nnoremap          <Space>mgr    :<C-u>CocCommand fzf-preview.ProjectGrep<Space>
" xnoremap          <Space>mgr    "sy:CocCommand   fzf-preview.ProjectGrep<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"
" nnoremap <silent> <Space>mt     :<C-u>CocCommand fzf-preview.BufferTags<CR>
" nnoremap <silent> <Space>mq     :<C-u>CocCommand fzf-preview.QuickFix<CR>
" nnoremap <silent> <Space>ml     :<C-u>CocCommand fzf-preview.LocationList<CR>
"
