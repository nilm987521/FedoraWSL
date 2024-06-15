Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -u root -- bash -c 'while true; do ping -c 1 8.8.8.8 > /dev/null; sleep 15; done'", vbhide
