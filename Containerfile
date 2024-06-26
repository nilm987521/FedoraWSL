FROM fedora:40
RUN dnf install -y dnf-plugins-core && tee -a /etc/yum.repos.d/google-cloud-sdk.repo <<EOF && dnf copr enable -y wslutilities/wslu && dnf copr enable -y errornointernet/jetbrains && sed -i '9d' /etc/dnf/dnf.conf
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
RUN dnf install -y alacritty bat btop cmake dbus-x11 direnv eza feh fcitx5 fcitx5-chewing gcc git google-cloud-sdk i3 iproute iputils langpacks-zh_TW make man man-db neovim openssh-server podman polybar rcm rofi sudo systemd tealdeer tmux trash-cli unzip wget wslu xdg-utils xrdp zoxide zsh zip qutebrowser pass gpg && dnf clean all -y
# 設定podman
RUN setcap cap_setuid+ep /usr/bin/newuidmap && setcap cap_setgid+ep /usr/bin/newgidmap && systemctl unmask systemd-logind
# 設定sshd
RUN sed -i 's/\^#?Port.*/Port 2332/' /etc/ssh/sshd_config && systemctl enable sshd
# 設定xrdp
RUN sed -i 's/3389/3390/' /etc/xrdp/xrdp.ini && systemctl enable xrdp
# 自動重連X0(wslg X11 socket)
COPY --chmod=0400 x0.service /etc/systemd/system/x0.service
RUN systemctl enable x0.service
# 設定xrdp
RUN sed -i '165s/^#//' /etc/xrdp/sesman.ini && sed -i '167d' /etc/xrdp/sesman.ini 
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
RUN useradd -m -s /usr/bin/bash -G wheel $USER && echo $PASSWD | passwd --stdin $USER
RUN cat <<EOF > /usr/libexec/xrdp/startwm.sh && chmod +x /usr/libexec/xrdp/startwm.sh
export GDK_BACKEND=x11
i3
EOF
# 切換使用者
USER $USER
ADD --chown=$USER:$USER fonts.tgz /home/$USER/.fonts
ADD --chown=$USER:$USER i3 /home/$USER/.config/i3
ADD --chown=$USER:$USER polybar /home/$USER/.config/polybar
ADD --chown=$USER:$USER direnvrc /home/$USER/.config/direnv
ADD --chown=$USER:$USER alacritty.toml /home/$USER/.config/alacritty/alacritty.toml
WORKDIR /home/$USER
# 設定zsh
RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" && \
    sed -i 's/robbyrussell/nord-extended\/nord/' ~/.zshrc && \
    sed -i '73 s/git/gcloud tmux tldr git podman mvn node sudo eza brew direnv dnf nvm sdk ripgrep vi-mode zoxide/' ~/.zshrc && \
    echo -e "zstyle ':omz:plugins:eza' 'dirs-first' yes\nzstyle ':omz:plugins:eza' 'size-prefix' Mi\nunset WAYLAND_DISPLAY" | tee -a ~/.zshrc && \
    sed -i '39i _EZA_TAIL+=(" --icons=always")' ~/.oh-my-zsh/plugins/eza/eza.plugin.zsh
# 設定profile
RUN cat <<EOF | sudo tee -a /etc/profile
# WSL似乎不會載入/etc/environment
export PODMAN_IGNORE_CGROUPSV1_WARNING=1
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export INPUT_METHOD=fcitx
export GLFW_IM_MODULE=ibus
export LANG=en_US.UTF-8
export TZ=Asia/Taipei
export BROWSER=xdg-open
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
nvim() {
        # Fedora 預設會帶 WAYLAND的變數，但實際上環境並沒有啟動 WAYLAND，反而導致nvim剪貼簿問題
        unset WAYLAND_DISPLAY
        /usr/bin/nvim "$@"
}
EOF
# 設定alias
RUN cat <<EOF | sudo tee -a /etc/profile.d/00-aliases.sh | sudo tee -a /etc/zshenv
alias vi=nvim
alias vim=nvim
alias rm=trash
alias powershell="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
alias winStart="powershell -c start"
alias ssh="/mnt/c/Windows/System32/OpenSSH/ssh.exe"
alias ip="ip -c=always"
EOF
RUN git clone https://github.com/fxbrit/nord-extended ~/.oh-my-zsh/themes/nord-extended
# 設定TMUX
COPY --chown=$USER:$USER tmux.conf /home/$USER/.config/tmux/tmux.conf
RUN git clone https://github.com/nordtheme/tmux.git ~/.tmux/themes/nord-tmux && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
RUN ~/.tmux/plugins/tpm/scripts/install_plugins.sh
# 安裝oogrep
RUN mkdir -p /home/$USER/.local/bin
RUN wget -c https://github.com/takumayokoo/oogrep/releases/download/v1.2/linux_386.tgz -O - | tar xz -C /home/$USER/.local/bin
# 設定git
RUN git config --global core.editor nvim && git config --global init.defaultBranch main
# 安裝sdkman & nvm
RUN curl -sS "https://get.sdkman.io?rcupdate=false" | bash
RUN curl -sS https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN echo -e "export SDKMAN_DIR=\"\$HOME/.sdkman\"\n\
[[ -s \"\$HOME/.sdkman/bin/sdkman-init.sh\" ]] && source \"\$HOME/.sdkman/bin/sdkman-init.sh\"\n\
export NVM_DIR=\"\$HOME/.nvm\"\n\
[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"" | sudo tee -a /etc/zshrc | sudo tee -a /etc/bashrc
# 安裝 LazyVim
RUN mkdir -p ~/.config
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim && \
    rm -rf ~/.config/nvim/.git && \
    echo -e "\
local opt = vim.opt\n\
opt.wrap = true\n\
vim.o.tabstop = 4\n\
vim.o.expandtab = true\n\
vim.o.softtabstop = 4\n\
vim.o.shiftwidth = 4" | tee -a ~/.config/nvim/lua/config/options.lua && \
    echo -e "return {\n    { \"nvimdev/dashboard-nvim\", enabled = false },\n}" | tee -a ~/.config/nvim/lua/plugins/disabled.lua
RUN echo "env SHELL=/usr/bin/zsh tmux new-session -A -s main" | tee -a ~/.bashrc
