FROM --platform=linux/amd64 fedora:40
RUN dnf install -y dnf-plugins-core && dnf copr enable -y wslutilities/wslu && sed -i '9d' /etc/dnf/dnf.conf && cat <<EOF | tee -a /etc/yum.repos.d/google-cloud-sdk.repo
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
RUN dnf install -y pinentry bat xclip cmake dbus-x11 direnv eza gcc git google-cloud-sdk iproute iputils langpacks-zh_TW langpacks-en make man man-db neovim podman sudo systemd tealdeer tmux trash-cli unzip wget wslu xdg-utils zoxide zsh zip gpg btop powerline-fonts fontawesome-fonts-all gdouros-symbola-fonts google-noto-sans-mono-cjk-vf-fonts subscription-manager-plugin-container net-tools picom material-icons-fonts python310 && dnf clean all -y
RUN python3 -m ensurepip --default-pip && python3 -m pip install podman-compose
# 設定podman
RUN setcap cap_setuid+ep /usr/bin/newuidmap && setcap cap_setgid+ep /usr/bin/newgidmap && systemctl unmask systemd-logind
# 設定 wsl.conf
ARG USER="wsl"
ARG PASSWD="wsl"
RUN cat <<EOF > /etc/wsl.conf
[boot]
systemd = true
command="sudo mount -o remount,shared /"
[network]
hostname = FedoraWSL
[user]
default = $USER
[interop]
appendWindowsPath = false
EOF
# 設定 sudo 不用密碼
RUN echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" | tee -a /etc/sudoers
# 新增使用者
RUN useradd -m -s /usr/bin/zsh -G wheel $USER && echo $PASSWD | passwd --stdin $USER
RUN echo "# Everything not work in HERE!!" | tee -a /etc/environment
# 設定profile
RUN cat <<EOF | tee -a /etc/profile
# WSL似乎不會載入/etc/environment
export PODMAN_IGNORE_CGROUPSV1_WARNING=1
export LANG=en_US.UTF-8
export TZ=Asia/Taipei
export PULSE_SERVER=/mnt/wslg/PulseServer
EOF
# 設定alias
RUN cat <<EOF | tee -a /etc/profile.d/00-aliases.sh | sudo tee -a /etc/zshenv
alias eza="eza --icons always --group-directories-first --time-style '+%Y-%m-%d %H:%M' --smart-group"
alias vi=nvim
alias vim=nvim
alias rm=trash
alias powershell='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
alias winStart='powershell -c start'
alias ip='ip -c=always'
alias eza='eza --icons always --group-directories-first --time-style '\''+%Y-%m-%d %H:%M'\'' --smart-group'
alias podman='sudo podman'
EOF
# 切換使用者
USER $USER
WORKDIR /home/$USER
# 設定zsh
RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" && \
    sed -i 's/robbyrussell/nord-extended\/nord/' ~/.zshrc && \
    sed -i '73 s/git/gcloud tmux tldr git podman mvn node sudo eza direnv dnf nvm sdk vi-mode zoxide/' ~/.zshrc
RUN git clone https://github.com/fxbrit/nord-extended ~/.oh-my-zsh/themes/nord-extended

RUN curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
# 安裝sdkman & nvm
RUN curl -sS "https://get.sdkman.io?rcupdate=false" | bash
RUN curl -sS "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh" | bash
RUN cat <<EOF | tee -a ~/.zshrc | tee -a ~/.bashrc
export SDKMAN_DIR="\$HOME/.sdkman"
[ -s "\$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "\$SDKMAN_DIR/bin/sdkman-init.sh"
EOF

# 設定TMUX
COPY --chown=$USER:$USER tmux.conf /home/$USER/.config/tmux/tmux.conf
RUN git clone https://github.com/nordtheme/tmux.git ~/.tmux/themes/nord-tmux && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
RUN ~/.tmux/plugins/tpm/scripts/install_plugins.sh

# 設定git
RUN git config --global core.editor nvim && git config --global init.defaultBranch main

# 安裝 LazyVim
RUN mkdir -p ~/.config
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim && \
    rm -rf ~/.config/nvim/.git && cat <<EOF | tee -a ~/.config/nvim/lua/config/options.lua
local opt = vim.opt
opt.wrap = true
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
EOF
RUN cat <<EOF | tee -a ~/.config/nvim/lua/plugins/disabled.lua
return {
    { "nvimdev/dashboard-nvim", enabled = false },
    { "rcarriga/nvim-notify", enabled = false },
}
EOF
