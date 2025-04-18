ARG PLATFORM="linux/amd64"
FROM --platform=$PLATFORM fedora:40
RUN dnf install -y dnf-plugins-core && dnf copr enable -y wslutilities/wslu && dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && sed -i '9d' /etc/dnf/dnf.conf && tee -a /etc/yum.repos.d/google-cloud-sdk.repo <<EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
RUN dnf install -y wqy-zenhei-fonts fcitx5 fcitx5-chewing bat xclip cmake direnv eza gcc git google-cloud-sdk iproute iputils langpacks-zh_TW langpacks-en make man man-db neovim sudo systemd tealdeer tmux trash-cli unzip wget wslu xdg-utils zoxide zsh zip gpg btop subscription-manager-plugin-container net-tools nmap-ncat docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    dnf remove -y qemu-user-static && \
    dnf clean all -y
RUN systemctl enable docker docker.socket
RUN python3 -m ensurepip --upgrade && pip3 install chromaterm
# 設定 wsl.conf
ARG USER="wsl"
RUN tee -a /etc/wsl.conf <<EOF
[boot]
systemd = true
command="sudo mount -o remount,shared /"
[network]
hostname = FedoraWSL
generateHosts = false
[user]
default = $USER
[interop]
appendWindowsPath = false
EOF
# 自動連接X11 Socket
ADD wslg-x11-symlink.service /etc/systemd/system/wslg-x11-symlink.service
RUN systemctl enable wslg-x11-symlink.service
# 設定 sudo 不用密碼
RUN echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" | tee -a /etc/sudoers
# 新增使用者
RUN useradd -m -s /usr/bin/zsh -G wheel,docker $USER
# WSL似乎不會載入/etc/environment
RUN echo "# Everything not work in HERE!!" | tee -a /etc/environment
# 設定profile
RUN tee -a /etc/profile <<EOF
export LANG=en_US.UTF-8
export TZ=Asia/Taipei
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
EOF
# 設定alias
RUN tee -a /etc/profile.d/00-aliases.sh <<EOF
alias vi=nvim
alias vim=nvim
alias rm=trash
alias powershell='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
alias winStart='powershell -c start'
alias ip='ip -c=always'
alias eza='eza --icons always --group-directories-first --time-style '\''+%Y-%m-%d %H:%M'\'' --smart-group'
alias cat='bat --plain'
EOF
# 切換使用者
USER $USER
WORKDIR /home/$USER
# 設定zsh
RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" && \
    sed -i 's/robbyrussell/nord-extended\/nord/' ~/.zshrc && \
    sed -i '73 s/git/gcloud tmux tldr git podman mvn node sudo eza direnv dnf nvm sdk vi-mode zoxide/' ~/.zshrc
RUN git clone https://github.com/fxbrit/nord-extended ~/.oh-my-zsh/themes/nord-extended

# 安裝sdkman & nvm
RUN curl -sS "https://get.sdkman.io?rcupdate=false" | bash
RUN curl -sS "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh" | bash
RUN tee -a ~/.zshrc <<EOF
export SDKMAN_DIR="\$HOME/.sdkman"
[ -s "\$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "\$SDKMAN_DIR/bin/sdkman-init.sh"
EOF
ADD sdkconfig /home/$USER/.sdkman/etc/config

# 設定TMUX
COPY --chown=$USER:$USER tmux.conf /home/$USER/.config/tmux/tmux.conf
RUN git clone https://github.com/nordtheme/tmux.git ~/.tmux/themes/nord-tmux && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
RUN ~/.tmux/plugins/tpm/scripts/install_plugins.sh

# 安裝atuin, 目前只有beta版 不會有刷屏
RUN mkdir -p /home/$USER/.local/bin
RUN curl --proto '=https' --tlsv1.2 -LsSf https://github.com/atuinsh/atuin/releases/download/v18.4.0-beta.1/atuin-installer.sh | sh && echo 'eval "$(atuin init zsh)"' | tee -a /home/$USER/.zshrc

# 安裝 LazyVim
RUN mkdir -p ~/.config
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git
RUN tee -a ~/.config/nvim/lua/config/clipboard.lua <<EOF
vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = {
  name = "winclip",
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = "win32yank.exe -i --crlf",
  },
  paste = {
    ["+"] = "win32yank.exe -o --lf",
    ["*"] = "win32yank.exe -o --lf",
  },
  cache_enabled = 0,
}
EOF
RUN tee -a /home/$USER/.config/nvim/init.lua <<EOF
require("config.clipboard")
local opt = vim.opt
opt.wrap = true
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.cmd([[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
]])
-- 設定 Neovim 的 statusline
vim.o.statusline = table.concat({
    "%4*", -- 高亮顯示
    "%<%m", -- 修改標記（+ = 修改，- = 修改但未儲存）
    "%<[%f%r%h%w]", -- 檔案名稱、唯讀、隱藏、加密標誌
    "[%{&ff},%{&fileencoding},%Y]", -- 檔案格式、編碼、檔案類型
    "%=", -- 左右對齊分隔符
    "[Unicode=%b/Hex=0x%B]", -- Unicode 和 Hex 表示的字節位置
    "[Position=%l,%v,%p%%]", -- 游標行、列位置，百分比位置
}, " ")
EOF
RUN tee -a /home/$USER/.config/nvim/lua/plugins/disable.lua <<EOF
return {
    { "nvim-lualine/lualine.nvim", enabled = false },
    { "rcarriga/nvim-notify", enabled = false },
    { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },
}
EOF
 
# SSH AGENT
RUN mkdir -p /home/$USER/.config/systemd/user
COPY ssh-agent.service /home/$USER/.config/systemd/user/
RUN systemctl --user enable ssh-agent.service && \
    echo "export SSH_AUTH_SOCK=/run/user/$(id -u)/ssh-agent.socket" | tee -a /home/$USER/.zshrc

ADD --chown=$USER:$USER --chmod=555 bin/ /home/$USER/.local/bin
RUN echo 'export PATH=$HOME/.local/bin:$PATH' | tee -a /home/$USER/.zshrc

# 設定git
RUN git config --global core.editor nvim && git config --global init.defaultBranch main

RUN sed -i '1i [ -z \"$TMUX\" ] && [ -z \"$TERM_PROGRAM\" ] && ct tmux new-session -A -s HOME' /home/$USER/.zshrc

ADD --chown=$USER:$USER eclipse-202203-tr_linux.tgz /opt
