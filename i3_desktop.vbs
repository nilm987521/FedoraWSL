Set shell = CreateObject("WScript.Shell" ) 
shell.run "C:\Users\daniel\scoop\shims\vcxsrv.exe :5 -screen 0 @1 -nodecoration -ac", 0	
shell.run "wsl --cd ~ -- ~/.local/bin/wsl-launch", 0
