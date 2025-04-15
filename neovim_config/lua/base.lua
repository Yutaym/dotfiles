if vim.fn.has("wsl") == 1 then
    if vim.fn.executable("wl-copy") == 0 then
        print("wl-clipboard not found, clipboard integration won't work")
    else
        vim.g.clipboard = {
            name = "wl-clipboard (wsl)",
            copy = {
                ["+"] = 'wl-copy --foreground --type text/plain',
                ["*"] = 'wl-copy --foreground --primary --type text/plain'
            },
            paste = {
                ["+"] = (function()
                    return vim.fn.systemlist('wl-paste --no-newline|sed -e "s/\r$//"', {''}, 1) -- '1' keeps empty lines
                end),
                ["*"] = (function()
                    return vim.fn.systemlist('wl-paste --primary --no-newline|sed -e "s/\r$//"', {''}, 1)
                end)
            },
            cache_enabled = true
        }
    end
else
    vim.o.clipboard = vim.o.clipboard .. "unnamed"
end

vim.o.number = true
vim.o.relativenumber = true
vim.o.fenc = 'utf-8'

vim.o.autoread = true
vim.o.hidden = true
vim.o.writebackup = false
vim.o.backup = false
vim.o.ambiwidth = 'double'
vim.o.visualbell = true
vim.o.virtualedit = 'onemore'

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.wrapscan = true
vim.o.incsearch = true
vim.o.hlsearch = true
-- vim.o.backspase={"indent","eol","start"}

vim.o.errorbells = false
vim.o.showmatch = true
vim.o.matchtime = 1
vim.o.cinoptions = vim.o.cinoptions .. ":0"
vim.o.cmdheight = 1
vim.o.laststatus = 2
vim.o.showcmd = true
vim.o.display = "lastline"

vim.o.cursorline = true
vim.api.nvim_create_autocmd({"InsertEnter"}, {
    callback = function()
        vim.opt.cursorline = false
    end
})
vim.api.nvim_create_autocmd({"InsertLeave"}, {
    callback = function()
        vim.opt.cursorline = true
    end

})
vim.opt.scrolloff = 3
vim.opt.lazyredraw = true
vim.opt.foldmethod = "manual"

vim.o.list = true
vim.o.listchars = "tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%"
vim.o.history = 100
vim.o.wildmenu = true
vim.o.wildmode = "list:longest,full"

vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4
vim.o.smartindent = true
vim.o.autoindent = true

vim.o.showmatch = true
vim.o.swapfile = false
vim.o.foldenable = false
vim.o.title = true
vim.o.number = true

vim.o.whichwrap = vim.o.whichwrap .. "b,s,h,l,<,>,[,],~"
vim.o.mouse = "a"

vim.o.wrap = true
vim.o.conceallevel = 0

vim.o.foldmethod = "marker"
vim.o.updatetime = 300

function try_catch(what)
    local status, result = pcall(what.try)
    if not status then
        what.catch(result)
    end
    return result
end

try_catch {
    try = function()
        vim.o.widmenu = true
        vim.o.widmode = 'longest:full,full'
        vim.o.shellslash = true
    end,
    catch = function()
    end
}
