vim.o.clipboard = vim.o.clipboard .. "unnamed"

vim.o.number=true
vim.o.relativenumber=true
vim.o.fenc='utf-8'

vim.o.autoread=true
vim.o.hidden=true
vim.o.writebackup=false
vim.o.backup=false
vim.o.ambiwidth='double'
vim.o.widmenu=true
vim.o.widmode='longest:full,full'
vim.o.visualbell=true
vim.o.virtualedit='onemore'


vim.o.ignorecase=true
vim.o.smartcase=true
vim.o.wrapscan=true
vim.o.incsearch=true
vim.o.hlsearch=true
--vim.o.backspase={"indent","eol","start"}

vim.o.errorbells = false
vim.o.shellslash = true
vim.o.showmatch = true
vim.o.matchtime = 1
vim.o.cinoptions = vim.o.cinoptions .. ":0"
vim.o.cmdheight = 1
vim.o.laststatus = 2
vim.o.showcmd = true
vim.o.display = "lastline"
vim.o.cursorline = true
vim.o.list = true
vim.o.listchars = "tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%"
vim.o.history = 100

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
