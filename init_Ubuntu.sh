mkdir ~/.config

mkdir ~/.config/zsh
cp ~/dotfiles/zsh_config/.zshrc ~/.zshrc
ln -snf ~/dotfiles/zsh_config/.zshrc_main ~/.config/zsh/.zshrc_main
ln -snf ~/dotfiles/zsh_config/.zshrc_alias ~/.config/zsh/.zshrc_alias
ln -snf ~/dotfiles/zsh_config/.zshrc_prompt ~/.config/zsh/.zshrc_prompt
ln -snf ~/dotfiles/zsh_config/.zshrc_env_Ubuntu ~/.config/zsh/.zshrc_env

mkdir ~/.vim
ln -snf ~/dotfiles/vim_config/.vimrc ~/.vimrc
ln -snf ~/dotfiles/vim_config/environment_Ubuntu.vim ~/.vim/environment.vim
ln -snf ~/dotfiles/vim_config/config ~/.vim/config

mkdir ~/.config/nvim
ln -snf ~/dotfiles/neovim_config/init.lua ~/.config/nvim/init.lua
ln -snf ~/dotfiles/neovim_config/lua ~/.config/nvim/lua

# ln -snf ./other_config/latexmk ~/.latexmk
ln -snf ~/dotfiles/other_config/.latexmkrc ~/.latexmk
ln -snf ~/dotfiles/other_config/.tmux_conf ~/.tmux_conf

ln -snf ~/dotfiles/scripts_mac ~/scripts
