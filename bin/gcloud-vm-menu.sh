#!/bin/bash

gcloud compute instances list |
  grep RUNNING |
  awk '{
      printf("%s %d \"new-window -n %s gcloud compute ssh --tunnel-through-iap %s\" ",
             $1,    # instance name
             NR,    # menu item number
             $1,    # window name
             $1)    # instance name for ssh
    }' | xargs tmux display-menu -T "Switch session"
