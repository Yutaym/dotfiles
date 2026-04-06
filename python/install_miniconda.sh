MINICONDA_DIR= "~/miniconda3"
if [ -d "$MINICONDA_DIR" ]; then
    echo "Skip install miniconda: already exists"
else
    echo "Install the miniconda latest version on $USERPROFILE_REAL"

    # 一時ディレクトリにダウンロード
    TEMP_INSTALLER="/tmp/miniconda_installer.sh"

    # Linuxアーキテクチャに応じてダウンロード
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    elif [ "$ARCH" = "aarch64" ]; then
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

    curl -L "$MINICONDA_URL" -o "$TEMP_INSTALLER"

    # 実際のユーザーとして実行
    sudo bash "$TEMP_INSTALLER" -b -p "$MINICONDA_DIR"
    rm "$TEMP_INSTALLER"

    # conda初期化
    sudo bash "$MINICONDA_DIR/bin/conda" init bash

    echo "Finish installing miniconda"
fi
