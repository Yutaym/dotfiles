function! g:VimProcExecmd(cmd)
        let l:proc = vimproc#popen2(a:cmd)
        let l:response = ''
        while !l:proc.stdout.eof
                let l:response .= l:proc.stdout.read()
        endwhile
        return l:response
endfunction

function! g:VimProcExecmdShow(cmd)
        let l:proc = vimproc#popen2(a:cmd)
        let l:response = ''
        while !l:proc.stdout.eof
                let l:response .= l:proc.stdout.read()
        endwhile
        silent pedit Cmd\ Result
        wincmd P
        %delete
        setlocal buftype=nofile noswapfile modifiable
        let l:replaced = substitute(l:response,"\n","\r","g")
        silent call append(0,l:replaced)
        %s///g
        silent wincmd p
        return l:response
endfunction

command! -nargs=? -complete=file ExecuteCmd call g:vimprocexecmdshow(<f-args>)


