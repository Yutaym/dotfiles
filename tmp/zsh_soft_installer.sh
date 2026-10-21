# eza install
curl -Lo eza.tar.gz \                                                                          [2026/04/06 15:50:57]
  https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
sudo tar xf eza.tar.gz --strip-components=1 -C /usr/local/bin
rm eza.tar.gz

# direnv install
curl -sfL https://direnv.net/install.sh | bash

# nvm install
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source .zshrc
nvm install --lts
nvm alias default "lts/*"

# ollama install
curl -fsSL https://ollama.com/install.sh | sh

##Windows
#$pubkey = Get-Content "$env:HOMEPATH\.ssh\id_ed25519.pub"
# ssh ユーザー名@サーバーのIPアドレス "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pubkey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
# ssh ユーザー名@サーバーのIPアドレス "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$(Get-Content $env:HOMEPATH\.ssh\id_ed25519.pub)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

## Unix-like system
ssh-copy-id -i ~/.ssh/id_ed25519.pub ユーザー名@サーバーのIPアドレス
cat ~/.ssh/id_ed25519.pub | ssh ユーザー名@ホスト名 \
  'mkdir -p ~/.ssh; chmod 700 ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys'

# docker install
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# code-server install
curl -fsSL https://code-server.dev/install.sh | sh
code-server --bind-addr 0.0.0.0:18080
sudo systemctl enable --now code-server@$USER
sudo systemctl restart code-server@$USER
