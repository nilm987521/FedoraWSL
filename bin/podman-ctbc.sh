#!/bin/bash

sudo podman ps | grep o360 | awk '{print $NF}' |
  awk '{
      printf("%s %d \"new-window -n %s sudo podman exec -ti --user o360adm %s bash\" ",
             $1,    # instance name
             NR,    # menu item number
             $1,    # window name
             $1)    # instance name for ssh
    }' | xargs tmux display-menu -T " Attach CTBC Container "
