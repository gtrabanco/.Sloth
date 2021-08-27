#!/usr/bin/env bash

tput smcup
clear

# example "application" follows...
read -n1 -p "Press any key to continue..."
# example "application" ends here

# restore
tput rmcup