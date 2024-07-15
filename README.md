# Fedora WSL
基於`Fedora:40`的WSL環境，預設啟動Systemd。

## 預設的Package
- alacritty
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
- eza
- trash-cli
- oogrep

## 安裝
1. 使用Podman建立Image及Container
  ```bash
  podman build -t fedora-wsl --build-arg-file account  --format docker --squash-all .
  podman create --name fedora-wsl fedora-wsl
  ```

2. 將container匯出成tar檔
  ```bash
  podman export -o FedoraWSL.tar fedora-wsl
  ```

3. 匯入到WSL
請參考[微軟官網教學](https://learn.microsoft.com/zh-tw/windows/wsl/use-custom-distro#import-the-tar-file-into-wsl)


4. 自動啟動 
```powershell
cp AutoBoot.vbs 'C:\Users\{UserName}\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'
```

https://github.com/marchaesen/vcxsrv/releases

## oogrep
oogrep跨系統執行，會有嚴重的效能問題，因此使用shell function，依據路徑決定使用哪個OS的版本，所以windows需自行安裝oogre(scoop)
``

## SSH Client
預設使用Windows的ssh.exe(alias),如果有使用1passwd密碼管理器,啟動其ssh-agent功能,可以少設定公私鑰

## Windows使用WSL內的Podman
```powershell
podman system connection add wsl --identity C:\Users\<user>\.ssh\id_rsa --port 2332 <user>@localhost --socket-path /run/user/1000/podman/podman.sock
```

## 使用紅帽的開發者訂閱
如果FedoraWSL有執行紅帽的訂閱,創見podman容器時,也會啟動訂閱
```shell
sudo subscription-manager register
```
## 中文輸入法
部份Desktop啟動的App，會不吃環境變數須在Desktop檔案中調整`Exec`
```
Exec=env FOO=bar /usr/bin/my_prog
```


