#!/bin/bash
docker build -t aitc-wsl .
docker create --name aitc-wsl aitc-wsl
docker export -o AitcWSL.tar aitc-wsl
rm -rf AitcWSL.tar.gz && gzip AitcWSL.tar
