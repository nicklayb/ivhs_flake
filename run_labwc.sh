#!/usr/bin/env sh

U=ivhs

sudo -u $U \
  DISPLAY=:0 \
  XDG_RUNTIME_DIR=/run/user/$(id -u $U) \
  $@
