# RHEL WSL
基於`RHEL8`的WSL環境，預設啟動Systemd。

## 預設的Package
- zsh
- oh-my-zsh
- tmux
- tpm(tmux的外掛管理)
- neovim(LazyVim)
- tleadeer
- bat
- btop
- podman
- direnv
- [nvm](https://github.com/nvm-sh/nvm)
- [sdkman](https://sdkman.io/)
- Homebrew
- eza
- trash-cli
- oogrep

## 安裝
1. 使用Docker建立Image及Container
  ```bash
  podman build -t ubi8-wsl --build-arg USER="yourname" --build-arg PASSWD="passwd" --format docker --squash-all .
  podman create --name ubi8-wsl ubi8-wsl
  ```

2. 將container匯出成tar檔
  ```bash
  podman export -o UBI8WSL.tar ubi8-wsl
  ```

3. 匯入到WSL
請參考[微軟官網教學](https://learn.microsoft.com/zh-tw/windows/wsl/use-custom-distro#import-the-tar-file-into-wsl)


## 自動啟動 
```powershell
cp AutoBoot.link C:\Users\{UserName}\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
```

## oogrep
oogrep跨系統執行，會有嚴重的效能問題，因此使用shell function，依據路徑決定使用哪個OS的版本，所以windows需自行安裝oogre(scoop)
``

podman system connection add wsl --identity C:\Users\daniel\.ssh\id_rsa --port 2332 daniel@localhost --socket-path /run/user/1000/podman/podman.sock
