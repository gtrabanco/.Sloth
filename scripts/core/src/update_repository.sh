#!/usr/bin/env bash

# https://github.com/Homebrew/brew/blob/master/Library/Homebrew/cmd/update.sh

update_repository::upstream_branch() {
  local upstream_branch

  upstream_branch="$(git::get_remote_head_upstream_branch "$@")"
  if [[ -z "${upstream_branch}" ]]; then
    git::git "$@" remote set-head origin --auto > /dev/null
    upstream_branch="$(git::get_remote_head_upstream_branch "$@")"
  fi
  upstream_branch="${upstream_branch#origin/}"
  [[ -z "${upstream_branch}" ]] && upstream_branch="master"
  echo "${upstream_branch}"
}

# All ways of update must check if the update is allowed before except Option 3 which force updates

# Update fully a local repository Option 1: Soft, this is a dev friendly only with latest branch
# When update starts should ask user if the working dir is not clean to use this method

# 1. Make a git stash of current workdir
# 1.1. Check if there are untracked files
# 1.2. Check if there are no staged changes
# 1.3. Check if there are no commited changes
#      git add -A && git stash -u will adds everyting
# 1.9 Check if repository is a shallow by checkign .git/shallow file exists
#     If it is a shallow, unshallow by executing:
#     git fetch --unsallow
# 2. Set all remote branches to the local
# 3. Track all local/remote branches
# 4. Change to the the remote HEAD branch in local and set it up as tracked branch
# 5. git fetch --all
# 6. In every branch that is locally and remotely perform a git pull
#    git pull --ff-only to avoid merge remote branch if conflicts (it will return an error if this happen)
# 7. Restore to stating branch
# 8. git stash pop if has something to be stashed but needs to resolve possible conflicts
#   8.1 stash_pop_info="$(git stash apply)"
#   8.2 Check any conflic: echo "$stash_pop_info" | grep -qi '^CONFLICT'
#   8.3 If no conflict execute: git stash drop
#   8.4 If user had the working dir clean? set current branch as remote head branch or keeps the user branch?
# 9. If previous step has conflicts say it to the user
# 10. Show message next time terminal is open in async or now in sync mode


# Update fully a local repository Option 2: normal way
# This way should be used if working dir is clean

# 1. Check if the working directory is clean, if it is no clean stop the update else, continue
# 1.1 Check if repository is shallow
# 2. Set and track remote HEAD branch locally
# 3. git fetch --all
# 4. git pull --force
# 5. Set to right version if stable, or minor
# 6. Show message next time terminal is open in async or now in sync mode


# Update fully a local repository Option 3: forced way
# This way should be used if working dir is not clean, this can be done using steps 1 to 

# 1. Check if the working directory is clean, if it is no clean stop the update else, continue
# 1.1 Check if repository is shallow
# 2. Set and track remote HEAD branch locally
# 3. git fetch --all
# 4. git pull --force
# 5. Set to right version if stable, or minor
# 6. Show message next time terminal is open in async or now in sync mode



