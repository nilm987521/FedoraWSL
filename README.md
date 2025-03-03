# Fedora WSL
基於`Fedora:40`的WSL環境，預設啟動Systemd。

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
- eza
- trash-cli
- atuin

## 安裝
1. 使用Podman建立Image及Container
  ```bash
  podman build -t aitc-wsl --format docker --squash-all .
  podman create --name aitc-wsl aitc-wsl
  ```

2. 將container匯出成tar檔
  ```bash
  podman export -o AitcWSL.tar aitc-wsl
  ```

3. 匯入到WSL
請參考[微軟官網教學](https://learn.microsoft.com/zh-tw/windows/wsl/use-custom-distro#import-the-tar-file-into-wsl)

4. 啟用cgroup v2
複製`.wslconfig`到windows使用者家目錄下

## 使用紅帽的開發者訂閱
如果FedoraWSL有執行紅帽的訂閱,創見podman容器時,也會啟動訂閱
```shell
sudo subscription-manager register
```
