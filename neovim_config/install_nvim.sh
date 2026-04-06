mkdir -p ~/.local
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C ./nvim -xzf nvim-linux-x86_64.tar.gz
cp -r nvim-linux-x86_64/* ~/.local
