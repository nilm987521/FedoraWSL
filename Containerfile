FROM fedora:40
RUN dnf install -y dnf-plugins-core && tee -a /etc/yum.repos.d/google-cloud-sdk.repo <<EOF && dnf copr enable -y wslutilities/wslu && dnf copr enable -y errornointernet/jetbrains && dnf copr enable atim/bottom -y && sed -i '9d' /etc/dnf/dnf.conf
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
RUN dnf install -y qutebrowser pinentry rxvt-unicode bat xclip cmake dbus-x11 direnv eza feh fcitx5 fcitx5-chewing gcc git google-cloud-sdk i3 iproute iputils langpacks-zh_TW langpacks-en make man man-db neovim openssh-server podman polybar rcm rofi sudo systemd tealdeer tmux trash-cli unzip wget wslu xdg-utils zoxide zsh zip pass gpg btop powerline-fonts fontawesome-fonts-all gdouros-symbola-fonts google-noto-sans-mono-cjk-vf-fonts subscription-manager-plugin-container net-tools picom material-icons-fonts && dnf clean all -y
# 設定podman
RUN setcap cap_setuid+ep /usr/bin/newuidmap && setcap cap_setgid+ep /usr/bin/newgidmap && systemctl unmask systemd-logind
# 設定sshd
RUN sed -i 's/\^#?Port.*/Port 2332/' /etc/ssh/sshd_config && systemctl enable sshd
# 自動重連X0(wslg X11 socket)
COPY --chmod=0400 x0.service /etc/systemd/system/x0.service
RUN systemctl enable x0.service
RUN systemctl enable podman.socket
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
# grep文件
_oogrep() {
	[[ \$# == 1 ]] && location="./" || location=\$2
	[[ \$(realpath \$2) == /mnt/c/* ]] && powershell -c oogrep \$1 \$location || ~/.local/bin/oogrep \$1 \$location
}
oogrep() {
	[[ \$# = 0 ]] && while true;do echo -e "================\ninput: ";read str; _oogrep \$str;done || \
	_oogrep \$1 \$2
}
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
EOF
# 切換使用者
USER $USER
ADD --chown=$USER:$USER i3 /home/$USER/.config/i3
ADD --chown=$USER:$USER polybar /home/$USER/.config/polybar
ADD --chown=$USER:$USER direnvrc /home/$USER/.config/direnv/direnvrc
ADD --chown=$USER:$USER Xdefaults /home/$USER/.Xdefaults
ADD --chown=$USER:$USER urxvt /home/$USER/.urxvt
RUN mkdir -p /home/$USER/.local/share/fonts
ADD --chown=$USER:$USER https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/SourceCodePro.zip /home/$USER/.local/share/fonts/SourceCodePro.zip
ADD --chown=$USER:$USER https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Iosevka.zip /home/$USER/.local/share/fonts/Iosevka.zip
ADD --chown=$USER:$USER rxvt-unicode-256.desktop /home/$USER/.local/share/applications/rxvt-unicode-256.desktop
RUN cd /home/$USER/.local/share/fonts && find ./ -name '*.zip' -exec unzip {} \; && find ./ -not -name '*.ttf' -type f -exec rm {} \;
RUN xdg-settings set default-web-browser wslview.desktop
WORKDIR /home/$USER
# 設定zsh
RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" && \
    sed -i 's/robbyrussell/nord-extended\/nord/' ~/.zshrc && \
    sed -i '73 s/git/gcloud tmux tldr git podman mvn node sudo eza direnv dnf nvm sdk ripgrep vi-mode zoxide/' ~/.zshrc && \
    cat <<EOF | tee -a ~/.zshrc
[ "\$DISPLAY" != ":0" ] && unset WAYLAND_DISPLAY
[[ \$TERM == *rxvt* && -z "\$TMUX" ]] && exec tmux new-session -e SHELL=/usr/bin/zsh -e GPG_TTY="\$(tty)" -A -s linux # 只有用urxvt的時候啟動 Tmux
EOF
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
COPY --chown=$USER:$USR wsl-launch /home/$USER/.local/bin/wsl-launch
RUN git clone https://github.com/nordtheme/tmux.git ~/.tmux/themes/nord-tmux && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
RUN ~/.tmux/plugins/tpm/scripts/install_plugins.sh

# 安裝oogrep
RUN mkdir -p /home/$USER/.local/bin
RUN wget -c https://github.com/takumayokoo/oogrep/releases/download/v1.2/linux_386.tgz -O - | tar xz -C /home/$USER/.local/bin

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
