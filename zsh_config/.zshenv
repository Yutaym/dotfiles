# Ubuntu/Debianの/etc/zsh/zshrcは、~/.zshrcより先に無条件でcompinitを呼んで
# セキュリティ監査(compaudit)を行う。~/.zshrc側(zshrc_ohmyzsh.sh)でZSH_DISABLE_COMPFIXを
# 設定しても、この時点で既に監査済みのため効果がない。
# ~/.zshenvは~/.zshrcより早く読み込まれるため、ここで無効化しておく。
# (macOSなど/etc/zsh/zshrcにこの仕組みが無い環境では単に無視される)
skip_global_compinit=1
