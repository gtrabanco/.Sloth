#!/usr/bin/env bash

git-delta::install() {
  package::install git-delta auto
}

git-delta::is_installed() {
  platform::command_exists delta
}
