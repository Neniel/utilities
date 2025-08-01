#!/bin/bash

set -e

is_git_repository() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}
