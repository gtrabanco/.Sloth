#!/usr/bin/env bash

declare -g -x _screen_updated=0
declare -A -x _screen=(
    ['rows']=$LINES
    ['cols']=$COLUMNS
)

screen_init() {

    clear
    screen_reset
    printf '\033[?25l'
}

screen_reset() {

    _screen['cols']=$COLUMNS
    _screen['rows']=$LINES
    clear
}

screen_resized() { (( COLUMNS == _screen['cols'] )) && (( LINES == _screen['rows'] )) && echo 0 || echo 1; }

render_init() { [[ $_screen_updated == 1 ]] && clear; }

draw_chars() {

    local x=$1
    local y=$2
    local s="$3"

    printf "\033[${y};${x}H${s}"
}

show_line_per_line() {
  local line
  local -r secs="${1:-}s"
  shift

  for line in "$@"; do
    sleep "$secs"
    echo "$(date +%s): $line"
  done
}

# column_print() {
#   local header width
#   while [[ $# -gt 0 ]]; do
#     case "${1:-}" in
#       --header)
#         header="$2"
#         shift 2
#         ;;
#       *)
#         break 2;
#         ;;
#     esac
#   done;
#   [[ $# -lt 3 ]] && return 1
  
#   local -r column_width="$1"
#   local -r column_order="$2"
#   shift 2

#   if "$column_width" =~ /%$/; then

# }



# echo "Test async"

# declare -a -g JOB_IDS=()

# trap "exit" INT TERM
# trap "kill 0" EXIT

# killAll() {
#   local job
#   for job in "${JOB_IDS[@]}"; do
#     killJob "$job"
#   done
# }

# call_async() {
#   local fn current_job

#   for fn in "$@"; do
#     if declare -F "$fn"; then
#       ( "$fn" ) &
#       current_job="$!"
#       JOB_IDS+=("$current_job")
#     fi
#   done
# }

# myfn() {
#   sleep 10s
#   echo "10 secs"
# }

# print_jobs() {
#   echo "Jobs"
#   while true; do
#     echo
#     jobs -l
#     echo
#     jobs -p
#     echo
#     sleep 1
#   done
#   #kill "$(jobs -p)"
# }

# call_async myfn print_jobs


# wait

# exit

  trap 'tput cnorm && exit 1' SIGTERM SIGINT EXIT

  #tput require ncurses package which is included with most part of linux distros
  tput clear
  tput cup 0 0 # Write on top
  echo
  echo BREW PACKAGES
  echo
  tput civis
  tput smcup
  # echo -e '\033[?47h' # save screen

all_packages=($(brew list --formula -1))


# Update must be executed async
# Screen stuff must run in sync
# Wait until each update ends

for pkg in "${all_packages[@]}"; do
  outdated_app_info="$(brew info "$pkg")"
  app_old_version=$(brew list "$pkg" --versions)
  app_old_version="${app_old_version//$pkg /}"
  app_info=$(echo "$outdated_app_info" | head -2 | tail -1)
  app_url=$(echo "$outdated_app_info" | head -3 | tail -1 | head -1)

  echo "🍺 $pkg"
  echo "├ $app_old_version -> latest"
  echo "├ $app_info"
  echo "└ $app_url"
  echo

  # Should update on background

  #tput cup 0 20
  echo " ==> LOG <=="
  echo
  show_line_per_line 1 "Downloading pkg source" "Configuring" "Finish"
  #show_line_per_line 1 "Downloading pkg source" "Configuring" "Executing make" "Make install" "Finish"
  #show_line_per_line 1 tail -f ~/dotly.log # should finish when background update ends
  echo
  tput rmcup
  # echo -e '\033[?47l' # restore screen
  # tput ed
  echo -e "\E[J"
  sleep 1s
done